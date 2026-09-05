CREATE DATABASE maritime_crisis_db;
USE maritime_crisis_db;

/* 1. Route Diversion & Distance Impact (Distance Analysis) */

SELECT 
    r.route_name,
    r.standard_distance_nm,
    r.diverted_distance_nm,
    (r.diverted_distance_nm - r.standard_distance_nm) AS extra_distance_nm,
    ROUND(AVG(c.distance_nm), 2) AS avg_actual_distance_nm,
    COUNT(c.record_id) AS total_trips
FROM crisis_metrics c
JOIN routes_master r ON c.route_id = r.route_id
GROUP BY r.route_name, r.standard_distance_nm, r.diverted_distance_nm
ORDER BY extra_distance_nm DESC;


/* 2. Freight Cost Escalation (Pricing Trend Analysis) */

SELECT 
    v.vessel_type,
    c.period_status,
    COUNT(c.record_id) AS total_shipments,
    ROUND(AVG(c.freight_rate_usd), 2) AS avg_freight_rate_usd,
    ROUND(MAX(c.freight_rate_usd), 2) AS max_freight_rate_usd,
    ROUND(MIN(c.freight_rate_usd), 2) AS min_freight_rate_usd
FROM crisis_metrics c
JOIN vessels_master v ON c.vessel_type_id = v.vessel_type_id
GROUP BY v.vessel_type, c.period_status
ORDER BY v.vessel_type, c.period_status;

/* 3. Port Congestion & Delay (Operational Performance) */

SELECT 
    p.port_name,
    p.country,
    p.base_dwell_days,
    ROUND(AVG(c.transit_delay_days), 2) AS avg_transit_delay_days,
    ROUND(MAX(c.transit_delay_days), 2) AS max_transit_delay_days,
    COUNT(c.record_id) AS total_port_calls
FROM crisis_metrics c
JOIN ports_master p ON c.port_id = p.port_id
GROUP BY p.port_name, p.country, p.base_dwell_days
ORDER BY avg_transit_delay_days DESC;

/* 4. Traffic & Trade Volume Impact (Macro Trend Analysis) */

SELECT 
    c.period_status,
    COUNT(c.record_id) AS total_shipments,
    ROUND(SUM(c.trade_volume_tons), 2) AS total_trade_volume_tons,
    ROUND(AVG(c.trade_volume_tons), 2) AS avg_trade_volume_per_shipment,
    ROUND(SUM(c.ghg_emission_tons), 2) AS total_ghg_emission_tons
FROM crisis_metrics c
GROUP BY c.period_status
ORDER BY total_trade_volume_tons DESC;

/* 5. Supply Chain Vulnerability & Corridor Risk Ranking (Advanced KPI & Ranking) */

WITH RouteMetrics AS (
    SELECT 
        r.route_name,
        COUNT(c.record_id) AS total_shipments,
        ROUND(AVG(c.distance_nm), 2) AS avg_distance,
        ROUND(AVG(c.transit_delay_days), 2) AS avg_delay,
        ROUND(AVG(c.freight_rate_usd), 2) AS avg_freight_rate,
        ROUND((AVG(c.distance_nm) * 0.3) + (AVG(c.transit_delay_days) * 50) + (AVG(c.freight_rate_usd) * 0.2), 2) AS composite_risk_score
    FROM crisis_metrics c
    JOIN routes_master r ON c.route_id = r.route_id
    GROUP BY r.route_name
)
SELECT 
    route_name,
    total_shipments,
    avg_distance,
    avg_delay,
    avg_freight_rate,
    composite_risk_score,
    RANK() OVER (ORDER BY composite_risk_score DESC) AS risk_rank
FROM RouteMetrics;