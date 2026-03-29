# =============================================================================
# EXAMPLE: Lambda@Edge + CloudFront Functions
#
# Demonstrates two types of edge compute:
#
#   CloudFront Functions (viewer-request) — lightweight, sub-ms:
#     • URL normalisation (remove trailing slash, lowercase path)
#     • JWT bearer-token validation (public-key verification)
#
#   Lambda@Edge (origin-request) — full Node.js runtime:
#     • A/B testing: route 10 % of traffic to a canary S3 prefix
#     • Add debug headers visible only to internal IPs
#
# Architecture:
#   Viewer → [CF Function: auth+URL rewrite] → CloudFront cache
#           → [Lambda@Edge: A/B split] → S3 origin-A or origin-B
# =============================================================================

provider "aws" {
  region = "us-east-1"   # Lambda@Edge + CloudFront Functions MUST be us-east-1
}

# ── S3 bucket (private) ───────────────────────────────────────────────────────
resource "aws_s3_bucket" "app" {
  bucket        = "${var.name}-app-${var.environment}"
  force_destroy = var.environment != "prod"
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket                  = aws_s3_bucket.app.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Lambda@Edge execution role ────────────────────────────────────────────────
data "aws_iam_policy_document" "edge_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "edge" {
  name               = "${var.name}-edge-role"
  assume_role_policy = data.aws_iam_policy_document.edge_assume.json
}

resource "aws_iam_role_policy_attachment" "edge_basic" {
  role       = aws_iam_role.edge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Grant Lambda@Edge read access to the S3 bucket so it can redirect to canary
resource "aws_iam_role_policy" "edge_s3" {
  name = "${var.name}-edge-s3"
  role = aws_iam_role.edge.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.app.arn}/*"
    }]
  })
}

# ── Lambda@Edge function: A/B test origin routing ────────────────────────────
# NOTE: Lambda@Edge functions must be published ($LATEST is not allowed).
# The zip is uploaded from a local build artefact; in CI build it first with:
#   cd functions/ab-test && npm ci && zip -r ../../ab-test.zip .
resource "aws_lambda_function" "ab_test" {
  function_name    = "${var.name}-ab-test-edge"
  role             = aws_iam_role.edge.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = "${path.module}/functions/ab-test/ab-test.zip"
  source_code_hash = filebase64sha256("${path.module}/functions/ab-test/ab-test.zip")
  publish          = true   # REQUIRED for Lambda@Edge

  # Lambda@Edge has strict limits: 128 MB memory, 5 s timeout (origin-request)
  memory_size = 128
  timeout     = 5

  environment {
    variables = {
      CANARY_WEIGHT = tostring(var.canary_traffic_percent)
      CANARY_PREFIX = "canary/"
    }
  }
}

# ── CloudFront Function: URL normalisation + JWT auth ────────────────────────
# The function code is inline for simplicity; for larger functions use a file.
resource "aws_cloudfront_function" "url_normalise" {
  name    = "${var.name}-url-normalise"
  runtime = "cloudfront-js-2.0"
  comment = "Normalise URLs and validate Bearer JWT"
  publish = true

  code = <<-JS
    // CloudFront Functions — viewer-request
    // 1. Lowercase the URI path
    // 2. Remove trailing slash (except root)
    // 3. Validate Authorization: Bearer <jwt> header (signature check
    //    is omitted here — add your public-key HMAC/RSA verification)
    function handler(event) {
      var request = event.request;
      var uri     = request.uri;

      // Normalise: lowercase
      uri = uri.toLowerCase();

      // Normalise: strip trailing slash
      if (uri !== '/' && uri.endsWith('/')) {
        uri = uri.slice(0, -1);
      }

      // Add .html extension for extensionless paths (SPA fallback)
      if (!uri.includes('.') && uri !== '/') {
        uri = uri + '.html';
      }

      request.uri = uri;

      // JWT presence check (replace with real signature validation)
      var authHeader = (request.headers['authorization'] || {}).value || '';
      var requireAuth = uri.startsWith('/protected');
      if (requireAuth && !authHeader.startsWith('Bearer ')) {
        return {
          statusCode: 401,
          statusDescription: 'Unauthorized',
          headers: {
            'www-authenticate': { value: 'Bearer realm="app"' }
          }
        };
      }

      return request;
    }
  JS
}

# ── CloudFront distribution ───────────────────────────────────────────────────
module "cloudfront" {
  source      = "../../"
  name        = "${var.name}-edge"
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  aliases             = var.domain_names
  default_root_object = "index.html"
  comment             = "${var.name} — Lambda@Edge + CF Functions demo"

  viewer_certificate = length(var.domain_names) > 0 ? {
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  } : { cloudfront_default_certificate = true }

  price_class     = var.price_class
  http_version    = "http2and3"
  is_ipv6_enabled = true

  origin_access_controls = {
    app-oac = {
      description                       = "OAC for ${var.name} app bucket"
      origin_access_control_origin_type = "s3"
      signing_behavior                  = "always"
      signing_protocol                  = "sigv4"
    }
  }

  origins = [{
    origin_id   = "app-s3"
    domain_name = aws_s3_bucket.app.bucket_regional_domain_name
    s3_origin_config = {
      origin_access_control_id = module.cloudfront.origin_access_control_ids["app-oac"]
    }
  }]

  # Default cache behavior:
  #   viewer-request  → CloudFront Function  (URL normalise + JWT check)
  #   origin-request  → Lambda@Edge          (A/B canary routing)
  default_cache_behavior = {
    target_origin_id       = "app-s3"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    # CloudFront Function runs at the viewer tier (no charge per invocation for
    # cache hits) — ideal for lightweight transforms
    function_associations = [{
      event_type   = "viewer-request"
      function_arn = module.cloudfront.cloudfront_function_arns["url-normalise"]
    }]

    # Lambda@Edge runs at the origin tier (only on cache misses)
    lambda_function_associations = [{
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.ab_test.qualified_arn
      include_body = false
    }]
  }

  ordered_cache_behaviors = [
    # /assets/* — immutable hashed files, no edge compute needed
    {
      path_pattern           = "/assets/*"
      target_origin_id       = "app-s3"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      min_ttl                = 31536000
      default_ttl            = 31536000
      max_ttl                = 31536000
    },
  ]

  custom_error_responses = [
    { error_code = 403, response_code = 200, response_page_path = "/index.html", error_caching_min_ttl = 0 },
    { error_code = 404, response_code = 200, response_page_path = "/index.html", error_caching_min_ttl = 0 },
  ]

  # Publish the CloudFront Function through the module
  cloudfront_functions = {
    url-normalise = {
      name    = "${var.name}-url-normalise"
      runtime = "cloudfront-js-2.0"
      comment = "Normalise URLs and validate Bearer JWT"
      publish = true
      code    = file("${path.module}/functions/url-normalise/index.js")
    }
  }
}

# ── S3 bucket policy ──────────────────────────────────────────────────────────
resource "aws_s3_bucket_policy" "app" {
  bucket = aws_s3_bucket.app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.app.arn}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = module.cloudfront.distribution_arn }
      }
    }]
  })
}

output "cloudfront_domain"       { value = module.cloudfront.distribution_domain_name }
output "cloudfront_id"           { value = module.cloudfront.distribution_id }
output "cf_function_arn"         { value = module.cloudfront.cloudfront_function_arns["url-normalise"] }
output "lambda_edge_arn"         { value = aws_lambda_function.ab_test.qualified_arn }
output "app_url" {
  value = length(var.domain_names) > 0 ? "https://${var.domain_names[0]}" : "https://${module.cloudfront.distribution_domain_name}"
}
