-- Create or replace a table with combined data from 2019 and 2020 quarters
CREATE OR REPLACE TABLE `durable-epoch-418201.cyclistic_bike_analysis.divvy_combined1` AS
SELECT
  a.trip_id, 
  a.rideable_type, 
  a.start_time AS started_at, 
  a.end_time AS ended_at,
  a.from_station_name AS start_station_name, 
  a.from_station_id AS start_station_id, 
  a.to_station_name AS end_station_name, 
  a.to_station_id AS end_station_id,
  a.usertype,
  TIMESTAMP_DIFF(TIMESTAMP(a.end_time), TIMESTAMP(a.start_time), SECOND) AS ride_length_seconds,
  a.day_of_week
FROM `durable-epoch-418201.cyclistic_bike_analysis.divvy_2019_q1` a
JOIN `durable-epoch-418201.cyclistic_bike_analysis.divvy_2020_q1` b
ON a.from_station_id = b.start_station_id
AND a.to_station_id = b.end_station_id
AND a.day_of_week = b.day_of_week;

-- Calculate average ride length by user type
SELECT 
  usertype,
  AVG(ride_length_seconds) AS avg_ride_length_seconds
FROM `durable-epoch-418201.cyclistic_bike_analysis.divvy_combined1`
GROUP BY usertype;

-- Calculate total rides by user type
SELECT
  usertype,
  COUNT(*) AS total_ride
FROM `durable-epoch-418201.cyclistic_bike_analysis.divvy_combined1`
GROUP BY usertype;

-- Calculate total rides by day of the week
SELECT
  day_of_week,
  COUNT (*) AS total_rides
FROM `durable-epoch-418201.cyclistic_bike_analysis.divvy_combined1`
GROUP BY day_of_week
ORDER BY day_of_week;
