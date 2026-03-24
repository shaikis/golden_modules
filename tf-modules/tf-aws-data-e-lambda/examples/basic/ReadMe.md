```
module "lambda" {
  source        = "../tf-aws-lambda"
  function_name = "my-function"
  runtime       = "python3.12"
  handler       = "index.handler"

  # Points to a zip file on your local machine / CI runner
  filename         = "${path.module}/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")
}
```

```
module "lambda" {
  source        = "../tf-aws-lambda"
  function_name = "my-function"
  runtime       = "python3.12"
  handler       = "app.handler"

  s3_bucket         = "my-lambda-artifacts-prod"
  s3_key            = "api-handler/v2.1.0.zip"
  s3_object_version = "abc123xyz"   # optional — pin exact version
}
```
```
module "lambda" {
  source        = "../tf-aws-lambda"
  function_name = "my-function"
  package_type  = "Image"           # ← switch to image mode
  image_uri     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-lambda:v1.2.3"

  # Optional: override container CMD/ENTRYPOINT
  image_config = {
    command     = ["app.handler"]
    entry_point = ["/lambda-entrypoint.sh"]
  }
}
```
```
Variable	Used when
--------    ---------
filename	Local zip on disk
source_code_hash	Local zip — triggers redeploy on change
s3_bucket + s3_key	Zip stored in S3
s3_object_version	S3 — pin to exact object version
image_uri	Container image in ECR
image_config	Container image — override CMD/ENTRYPOINT
```