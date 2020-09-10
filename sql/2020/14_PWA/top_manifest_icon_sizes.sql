#standardSQL
# Top manifest icon sizes - based on 2019/14_04f.sql
CREATE TEMPORARY FUNCTION getIconSizes(manifest STRING)
RETURNS ARRAY<STRING> LANGUAGE js AS '''
try {
  var $ = JSON.parse(manifest);
  return $.icons.map(icon => icon.sizes);
} catch (e) {
  return null;
}
''';

SELECT
  client,
  size,
  COUNT(0) AS freq,
  SUM(COUNT(0)) OVER (PARTITION BY client) AS total,
  ROUND(COUNT(0) * 100 / SUM(COUNT(0)) OVER (PARTITION BY client), 2) AS pct
FROM
  `httparchive.almanac.manifests`,
  UNNEST(getIconSizes(body)) AS size
WHERE
  date = '2020-08-01'
GROUP BY
  client,
  size
HAVING
  size IS NOT NULL
ORDER BY
  freq / total DESC
