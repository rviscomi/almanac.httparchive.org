#standardSQL
# Workbox usage - based on 2019/14_05.sql
SELECT
  client,
  COUNT(DISTINCT page) AS freq,
  total,
  ROUND(COUNT(DISTINCT page) * 100 / total, 2) AS pct
FROM
  `httparchive.almanac.service_workers`
JOIN
  (SELECT client, COUNT(DISTINCT page) AS total FROM `httparchive.almanac.service_workers` WHERE date = '2020-08-01' GROUP BY client)
USING (client),
  UNNEST(REGEXP_EXTRACT_ALL(body, r'new Workbox|new workbox|workbox\.precaching\.|workbox\.strategies\.')) AS occurrence
WHERE
  date = '2020-08-01'
GROUP BY
  client,
  total
ORDER BY
  freq / total DESC
