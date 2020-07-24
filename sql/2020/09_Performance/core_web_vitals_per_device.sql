#standardSQL
# Core WebVitals per device

CREATE TEMP FUNCTION IS_GOOD (good FLOAT64, needs_improvement FLOAT64, poor FLOAT64) RETURNS BOOL AS (
  good / (good + needs_improvement + poor) >= 0.75
);

CREATE TEMP FUNCTION IS_NI (good FLOAT64, needs_improvement FLOAT64, poor FLOAT64) RETURNS BOOL AS (
  good / (good + needs_improvement + poor) < 0.75
  AND poor / (good + needs_improvement + poor) < 0.25
);

CREATE TEMP FUNCTION IS_POOR (good FLOAT64, needs_improvement FLOAT64, poor FLOAT64) RETURNS BOOL AS (
  poor / (good + needs_improvement + poor) >= 0.25
);

CREATE TEMP FUNCTION IS_NON_ZERO (good FLOAT64, needs_improvement FLOAT64, poor FLOAT64) RETURNS BOOL AS (
  good + needs_improvement + poor > 0
);

WITH
  base AS (
  SELECT
    origin,
    device,

    fast_fid,
    avg_fid,
    slow_fid,
    
    fast_lcp,
    avg_lcp,
    slow_lcp,
    
    small_cls,
    medium_cls,
    large_cls
  FROM
    `chrome-ux-report.materialized.device_summary`
  WHERE
    device in ('desktop','phone')
    AND date = date('2020-06-01')
  )

SELECT
  device,
  
  COUNT(DISTINCT origin) AS total_origins,
  
  SAFE_DIVIDE(
      COUNT(DISTINCT IF(
          IS_GOOD(fast_fid, avg_fid, slow_fid) AND
          IS_GOOD(fast_lcp, avg_lcp, slow_lcp) AND
          IS_GOOD(small_cls, medium_cls, large_cls), origin, NULL)),
      COUNT(DISTINCT IF(
          IS_NON_ZERO(fast_fid, avg_fid, slow_fid) AND
          IS_NON_ZERO(fast_lcp, avg_lcp, slow_lcp) AND
          IS_NON_ZERO(small_cls, medium_cls, large_cls), origin, NULL))) AS pct_cwv_good,
  
  SAFE_DIVIDE(
      COUNT(DISTINCT IF(
          IS_GOOD(fast_lcp, avg_lcp, slow_lcp), origin, NULL)), 
      COUNT(DISTINCT IF(
          IS_NON_ZERO(fast_lcp, avg_lcp, slow_lcp), origin, NULL))) AS pct_lcp_good,
  SAFE_DIVIDE(
      COUNT(DISTINCT IF(
          IS_NI(fast_lcp, avg_lcp, slow_lcp), origin, NULL)), 
      COUNT(DISTINCT IF(
          IS_NON_ZERO(fast_lcp, avg_lcp, slow_lcp), origin, NULL))) AS pct_lcp_ni,
  SAFE_DIVIDE(
      COUNT(DISTINCT IF(
          IS_POOR(fast_lcp, avg_lcp, slow_lcp), origin, NULL)), 
      COUNT(DISTINCT IF(
          IS_NON_ZERO(fast_lcp, avg_lcp, slow_lcp), origin, NULL))) AS pct_lcp_poor,
  
  SAFE_DIVIDE(
      COUNT(DISTINCT IF(
          IS_GOOD(fast_fid, avg_fid, slow_fid), origin, NULL)), 
      COUNT(DISTINCT IF(
          IS_NON_ZERO(fast_fid, avg_fid, slow_fid), origin, NULL))) AS pct_fid_good,
  SAFE_DIVIDE(
      COUNT(DISTINCT IF(
          IS_NI(fast_fid, avg_fid, slow_fid), origin, NULL)), 
      COUNT(DISTINCT IF(
          IS_NON_ZERO(fast_fid, avg_fid, slow_fid), origin, NULL))) AS pct_fid_ni,
  SAFE_DIVIDE(
      COUNT(DISTINCT IF(
          IS_POOR(fast_fid, avg_fid, slow_fid), origin, NULL)), 
      COUNT(DISTINCT IF(
          IS_NON_ZERO(fast_fid, avg_fid, slow_fid), origin, NULL))) AS pct_fid_poor,
  
  SAFE_DIVIDE(
      COUNT(DISTINCT IF(
          IS_GOOD(small_cls, medium_cls, large_cls), origin, NULL)), 
      COUNT(DISTINCT IF(
          IS_NON_ZERO(small_cls, medium_cls, large_cls), origin, NULL))) AS pct_cls_good,
  SAFE_DIVIDE(
      COUNT(DISTINCT IF(
          IS_NI(small_cls, medium_cls, large_cls), origin, NULL)), 
      COUNT(DISTINCT IF(
          IS_NON_ZERO(small_cls, medium_cls, large_cls), origin, NULL))) AS pct_cls_ni,
  SAFE_DIVIDE(
      COUNT(DISTINCT IF(
          IS_POOR(small_cls, medium_cls, large_cls), origin, NULL)), 
      COUNT(DISTINCT IF(
          IS_NON_ZERO(small_cls, medium_cls, large_cls), origin, NULL))) AS pct_cls_poor,
FROM
  base
GROUP BY
  device