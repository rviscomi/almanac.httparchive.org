#standardSQL

# Calculates number of sites where the performance score changed low ( < 10), medium (10-30) or big (> 30) between
# LH 5 and 6 versions.
SELECT
  COUNTIF(perf_score_delta <= 0.1) AS small_change,
  COUNTIF(perf_score_delta > 0.1 AND perf_score_delta <= 0.3) AS mid_change,
  COUNTIF(perf_score_delta > 0.3) AS big_change
FROM
(
  SELECT
    url,
    perf_score_lh6,
    perf_score_lh5,
    (perf_score_lh6 - perf_score_lh5) as perf_score_delta
  FROM
  (
    SELECT lh6.url AS url,
      CAST(JSON_EXTRACT(lh6.report, '$.categories.performance.score') AS NUMERIC) AS perf_score_lh6,
      CAST(JSON_EXTRACT(lh5.report, '$.categories.performance.score') AS NUMERIC) AS perf_score_lh5,
      FROM `httparchive.sample_data.lighthouse_mobile_10k` lh6
      JOIN `httparchive.scratchspace.2020_03_01_lighthouse_mobile_10k` lh5 ON lh5.url=lh6.url
  )
)