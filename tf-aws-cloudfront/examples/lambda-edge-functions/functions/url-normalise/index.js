/**
 * CloudFront Function — viewer-request (cloudfront-js-2.0)
 *
 * Runs on EVERY viewer request (including cache hits) so it must be fast.
 * CloudFront Functions are billed per invocation but are ~10x cheaper than
 * Lambda@Edge at the viewer tier.
 *
 * Transforms applied (in order):
 *   1. Lowercase the URI path to avoid duplicate cache entries
 *   2. Remove trailing slash (except root "/")
 *   3. Append ".html" to extensionless paths for S3 website hosting
 *   4. Block requests missing a Bearer token on /protected/* paths
 */

function handler(event) {
  var request = event.request;
  var uri     = request.uri;

  // 1. Lowercase
  uri = uri.toLowerCase();

  // 2. Remove trailing slash
  if (uri.length > 1 && uri.charAt(uri.length - 1) === '/') {
    uri = uri.slice(0, -1);
  }

  // 3. Extensionless → .html (only if no dot in the last segment)
  var lastSegment = uri.split('/').pop();
  if (lastSegment.indexOf('.') === -1 && uri !== '/') {
    uri = uri + '.html';
  }

  request.uri = uri;

  // 4. Simple Authorization presence check for /protected/*
  //    Replace this with real JWT signature verification using crypto APIs
  //    available in cloudfront-js-2.0 (SubtleCrypto).
  if (uri.indexOf('/protected') === 0) {
    var authHeader = (request.headers['authorization'] || { value: '' }).value;
    if (authHeader.indexOf('Bearer ') !== 0) {
      return {
        statusCode: 401,
        statusDescription: 'Unauthorized',
        headers: {
          'www-authenticate': { value: 'Bearer realm="app"' },
          'content-type':     { value: 'application/json' }
        },
        body: JSON.stringify({ error: 'Missing or invalid Authorization header' })
      };
    }
  }

  return request;
}
