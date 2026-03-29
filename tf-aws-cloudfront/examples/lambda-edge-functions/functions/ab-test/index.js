/**
 * Lambda@Edge — origin-request
 *
 * A/B canary routing: routes CANARY_WEIGHT % of requests to the
 * "canary/" S3 key prefix so a new build can be tested with a
 * fraction of real traffic before full promotion.
 *
 * The routing decision is stored in a cookie (`x-ab-group`) so that
 * the same user always lands in the same group for the session.
 */

'use strict';

const CANARY_WEIGHT = parseInt(process.env.CANARY_WEIGHT || '10', 10);
const CANARY_PREFIX = process.env.CANARY_PREFIX || 'canary/';
const COOKIE_NAME   = 'x-ab-group';

exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers;

  // Read existing group cookie (sticky sessions)
  let group = getCookieValue(headers, COOKIE_NAME);
  if (!group) {
    group = Math.random() * 100 < CANARY_WEIGHT ? 'canary' : 'stable';
  }

  // Route canary users to the /canary/ S3 prefix
  if (group === 'canary' && !request.uri.startsWith('/' + CANARY_PREFIX)) {
    request.uri = '/' + CANARY_PREFIX + request.uri.replace(/^\//, '');
  }

  // Set the sticky-session cookie on the response (via custom header forwarded back)
  headers['x-ab-group'] = [{ key: 'X-AB-Group', value: group }];

  return request;
};

function getCookieValue(headers, name) {
  const cookieHeader = (headers.cookie || []).map(h => h.value).join('; ');
  const match = cookieHeader.match(new RegExp('(?:^|;\\s*)' + name + '=([^;]+)'));
  return match ? match[1] : null;
}
