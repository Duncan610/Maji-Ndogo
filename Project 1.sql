
--  comparison of the quality scores in the water_quality table to the auditor's scores. The auditor_report table
-- used location_id, but the quality scores table only has a record_id we can use. The visits table links location_id and record_id, so we
-- can link the auditor_report table and water_quality using the visits table So we first grab the location_id and true_water_source_score columns from auditor_report.

SELECT 
	location_id,
    true_water_source_score
FROM md_water_services.auditor_report;

-- Joining the visits table to the auditor_report table grabbing the subjective_quality_score, record_id and location_id.
select 
	ar.location_id,
    ar.true_water_source_score,
    v.record_id,
    wq.subjective_quality_score
from md_water_services.auditor_report as ar
join visits as v
on ar.location_id = v.location_id
-- Retrieval of the corresponding scores from the water_quality table by joining the visits table and the water_quality table
join water_quality as wq
on v.record_id = wq.record_id;

-- Dropping location_id column and rename the scores to surveyor_score and auditor_score
select 
	ar.location_id,
    ar.true_water_source_score as auditor_score,
    v.record_id,
    wq.subjective_quality_score as employee_score
from md_water_services.auditor_report as ar
join visits as v
on ar.location_id = v.location_id
-- Retrieval of the corresponding scores from the water_quality table by joining the visits table and the water_quality table
join water_quality as wq
on v.record_id = wq.record_id;

-- check if the auditor's and exployees' scores agree.
select 
	ar.location_id,
    ar.true_water_source_score as auditor_score,
    v.record_id,
    wq.subjective_quality_score as employee_score
from md_water_services.auditor_report as ar
join visits as v
on ar.location_id = v.location_id
-- Retrieval of the corresponding scores from the water_quality table by joining the visits table and the water_quality table
join water_quality as wq
on v.record_id = wq.record_id
where true_water_source_score = subjective_quality_score;

-- removing duplicates by setting visit_count = 1 in the where clause
select 
	ar.location_id,
    ar.true_water_source_score as auditor_score,
    v.record_id,
    wq.subjective_quality_score as employee_score
from md_water_services.auditor_report as ar
join visits as v
on ar.location_id = v.location_id
-- Retrieval of the corresponding scores from the water_quality table by joining the visits table and the water_quality table
join water_quality as wq
on v.record_id = wq.record_id
where true_water_source_score = subjective_quality_score
and v.visit_count = 1;

-- 102 records are incorrect
-- Employee scores that are not matching with the auditor score
select 
	ar.location_id,
    ar.true_water_source_score as auditor_score,
    v.record_id,
    wq.subjective_quality_score as employee_score,
    ar.type_of_water_source as auditor_source,
    ws.type_of_water_source as employee_source
from md_water_services.auditor_report as ar
join visits as v
on ar.location_id = v.location_id
-- Retrieval of the corresponding scores from the water_quality table by joining the visits table and the water_quality table
join water_quality as wq
on v.record_id = wq.record_id
join water_source as ws
on ws.source_id = v.source_id
where true_water_source_score != subjective_quality_score
and v.visit_count = 1;

-- looking at where these errors may have come from. At some of the locations, employees assigned scores incorrectly, and those records
-- ended up in this results set.
-- The employees are the source of the errors, so let's JOIN the assigned_employee_id for all the people on our list from the visits
-- table to our query
select 
	ar.location_id,
    ar.true_water_source_score as auditor_score,
    v.record_id,
    wq.subjective_quality_score as employee_score,
    e.employee_name as Employee_Incorrect
from md_water_services.auditor_report as ar
join visits as v
on ar.location_id = v.location_id
-- Retrieval of the corresponding scores from the water_quality table by joining the visits table and the water_quality table
join water_quality as wq
on v.record_id = wq.record_id
join water_source as ws
on ws.source_id = v.source_id
join employee as e
on e.assigned_employee_id = v.assigned_employee_id
where true_water_source_score != subjective_quality_score
and v.visit_count = 1;

--  Saving this as a CTE, so when we do more analysis, we can just call that CTE like it was a table.
with Incorrect_records as (
select 
	ar.location_id,
    ar.true_water_source_score as auditor_score,
    v.record_id,
    wq.subjective_quality_score as employee_score,
    e.employee_name as Employee_Incorrect
from md_water_services.auditor_report as ar
join visits as v
on ar.location_id = v.location_id
-- Retrieval of the corresponding scores from the water_quality table by joining the visits table and the water_quality table
join water_quality as wq
on v.record_id = wq.record_id
join water_source as ws
on ws.source_id = v.source_id
join employee as e
on e.assigned_employee_id = v.assigned_employee_id
where true_water_source_score != subjective_quality_score
and v.visit_count = 1)
select *
from Incorrect_records;

-- Getting a unique list of employees from this table

with Incorrect_records as (
select 
	ar.location_id,
    ar.true_water_source_score as auditor_score,
    v.record_id,
    wq.subjective_quality_score as employee_score,
    e.employee_name as Employee_Incorrect
from md_water_services.auditor_report as ar
join visits as v
on ar.location_id = v.location_id
-- Retrieval of the corresponding scores from the water_quality table by joining the visits table and the water_quality table
join water_quality as wq
on v.record_id = wq.record_id
join water_source as ws
on ws.source_id = v.source_id
join employee as e
on e.assigned_employee_id = v.assigned_employee_id
where true_water_source_score != subjective_quality_score
and v.visit_count = 1)
select distinct Employee_incorrect
from Incorrect_records;

-- Calculation of how many mistakes each employee made by counting how many times their name is in the Incorrect_records list
with Incorrect_records as (
select 
	ar.location_id,
    ar.true_water_source_score as auditor_score,
    v.record_id,
    wq.subjective_quality_score as employee_score,
    e.employee_name as Employee_Incorrect
from md_water_services.auditor_report as ar
join visits as v
on ar.location_id = v.location_id
join water_quality as wq
on v.record_id = wq.record_id
join water_source as ws
on ws.source_id = v.source_id
join employee as e
on e.assigned_employee_id = v.assigned_employee_id
where true_water_source_score != subjective_quality_score
and v.visit_count = 1)
select Employee_incorrect,
count(Employee_incorrect) as error_count
from Incorrect_records
group by Employee_incorrect;

-- calculating the average number of mistakes the employees made
with error_count as (with Incorrect_records as (
select 
	ar.location_id,
    ar.true_water_source_score as auditor_score,
    v.record_id,
    wq.subjective_quality_score as employee_score,
    e.employee_name as Employee_Incorrect
from md_water_services.auditor_report as ar
join visits as v
on ar.location_id = v.location_id
join water_quality as wq
on v.record_id = wq.record_id
join water_source as ws
on ws.source_id = v.source_id
join employee as e
on e.assigned_employee_id = v.assigned_employee_id
where true_water_source_score != subjective_quality_score
and v.visit_count = 1)
select Employee_incorrect,
count(Employee_incorrect) as number_of_mistakes
from Incorrect_records
group by Employee_incorrect)
select 
avg(number_of_mistakes) as avg_error_count_per_empl
from error_count;

-- Replacing CTE with a view
CREATE VIEW Incorrect_records AS (
SELECT
auditor_report.location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS employee_score,
auditor_report.statements AS statements
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
water_quality AS wq
ON visits.record_id = wq.record_id
JOIN
employee
ON employee.assigned_employee_id = visits.assigned_employee_id
WHERE
visits.visit_count =1
AND auditor_report.true_water_source_score != wq.subjective_quality_score);


with error_count as (
select
	employee_name,
    count(*) as number_of_mistakes
from incorrect_records
group by employee_name
order by number_of_mistakes desc
)
select
	employee_name,
    number_of_mistakes
from error_count
where number_of_mistakes > 6;

-- conversion of the query error_count into a CTE.
WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
/*
Incorrect_records is a view that joins the audit report to the database
for records where the auditor and
employees scores are different*/
GROUP BY
employee_name)
-- Query
SELECT avg(number_of_mistakes) as avg_number_of_mistakes
FROM error_count;

-- employee names with number of mistakes
WITH error_count AS ( 
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY
employee_name
)
SELECT
employee_name,
number_of_mistakes
FROM error_count
where number_of_mistakes > 6;


WITH error_count AS ( 
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY
employee_name
)
SELECT
employee_name,
number_of_mistakes
FROM error_count
where number_of_mistakes > 6;


WITH error_count AS ( 
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY employee_name
ORDER BY number_of_mistakes desc
),
suspect_list AS (
select employee_name,
number_of_mistakes
from error_count
where number_of_mistakes > (select avg(number_of_mistakes)
from error_count)
)
select employee_name,
number_of_mistakes
from suspect_list;

-- adding the statements column to the Incorrect_records CTE. Then pull up the records where the employee_name is in thesuspect list
WITH error_count AS ( 
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY employee_name
ORDER BY number_of_mistakes desc
),
suspect_list AS (
select employee_name,
number_of_mistakes
from error_count
where number_of_mistakes > (select avg(number_of_mistakes)
from error_count)
)
select location_id,
employee_name,
statements
from incorrect_records
where
employee_name in (
select employee_name
from suspect_list);

-- Filter the records that refer to "cash"
WITH error_count AS ( 
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY employee_name
ORDER BY number_of_mistakes desc
),
suspect_list AS (
select employee_name,
number_of_mistakes
from error_count
where number_of_mistakes > (select avg(number_of_mistakes)
from error_count)
)
select 
location_id,
employee_name,
statements
from incorrect_records
where statements like '%cash%';


select
	l.location_id,
    l.province_name,
    l.town_name,
    v.visit_count
from
location as l
join visits as v
on l.location_id = v.location_id;

 -- joining the water_source table on the key shared between water_source and visits.
 -- To have unique location_id rows
 select
	l.location_id,
    l.province_name,
    l.town_name,
    v.visit_count,
    ws.source_id,
    ws.number_of_people_served
from
location as l
join visits as v
on l.location_id = v.location_id
join water_source as ws
on v.source_id = ws.source_id
where v.visit_count = 1;

-- after verification that the table is joined correctly, removal of the location_id and visit_count columns.
 select
    l.province_name,
    l.town_name,
    ws.source_id,
    ws.number_of_people_served
from
location as l
join visits as v
on l.location_id = v.location_id
join water_source as ws
on v.source_id = ws.source_id
where v.visit_count = 1;

-- Add the location_type column from location and time_in_queue from visits to our results set.
 select
    l.province_name,
    l.town_name,
    l.location_type,
    v.time_in_queue,
    ws.source_id,
    ws.number_of_people_served
from
location as l
join visits as v
on l.location_id = v.location_id
join water_source as ws
on v.source_id = ws.source_id
where v.visit_count = 1;

-- This table assembles data from different tables into one to simplify analysis
--  grabbing the results from the well_pollution table using left join
select
	water_source.type_of_water_source,
	location.town_name,
	location.province_name,
	location.location_type,
	water_source.number_of_people_served,
	visits.time_in_queue,
	well_pollution.results
from
visits
left join
well_pollution
on well_pollution.source_id = visits.source_id
inner join
location
on location.location_id = visits.location_id
inner join
water_source
on water_source.source_id = visits.source_id
where
visits.visit_count = 1;

-- This view assembles data from different tables into one to simplify analysis
CREATE VIEW combined_analysis_table AS
SELECT
water_source.type_of_water_source AS source_type,
location.town_name,
location.province_name,
location.location_type,
water_source.number_of_people_served AS people_served,
visits.time_in_queue,
well_pollution.results
FROM
visits
LEFT JOIN
well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN
location
ON location.location_id = visits.location_id
INNER JOIN
water_source
ON water_source.source_id = visits.source_id
WHERE
visits.visit_count = 1;

-- This CTE calculates the population of each province
-- Percentae of people served per water source
WITH province_totals AS (
SELECT
province_name,
SUM(people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
ct.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
province_totals pt ON ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name;


-- This CTE calculates the population of each town
-- Since there are two Harare towns, we have to group by province_name and town_name
WITH town_totals AS (
SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN                           -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY                       -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

-- Creating a temporary table to the 
CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (
SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN                           -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY                       -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

-- view of the temporary table
select * 
from town_aggregated_water_access;

--   town which has the highest ratio of people who have taps, but have no running water
SELECT
province_name,
town_name,
ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) *
100,0) AS Pct_broken_taps
FROM
town_aggregated_water_access;

-- Project progress table
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR(50),
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT
);


-- Project_progress_query
-- It joins the location, visits, and well_pollution tables to the water_source table
SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1                -- This must always be true
AND (                     -- AND one of the following (OR) options must be true as well.
results != 'Clean'
OR type_of_water_source IN ('tap_in_home_broken','river')
OR (type_of_water_source = 'shared_tap' AND time_in_queue >= 30)
);

-- well improvements
SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results,
CASE 
WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO Filter'
WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO Filter'
ELSE null
End as Improvement
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1                -- This must always be true
AND (                     -- AND one of the following (OR) options must be true as well.
results != 'Clean'
OR type_of_water_source IN ('tap_in_home_broken','river')
OR (type_of_water_source = 'shared_tap' AND time_in_queue >= 30)
);

-- Rivers. Upgrade is done by drilling new wells nearby.
SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results,
CASE 
WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO Filter'
WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO Filter'
WHEN water_source.type_of_water_source = 'river' THEN 'Drill well'
ELSE null
End as Improvement
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1                -- This must always be true
AND (                     -- AND one of the following (OR) options must be true as well.
results != 'Clean'
OR type_of_water_source IN ('tap_in_home_broken','river')
OR (type_of_water_source = 'shared_tap' AND time_in_queue >= 30)
);

-- Improvement for shared taps
SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results,
CASE 
WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO Filter'
WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO Filter'
WHEN water_source.type_of_water_source = 'river' THEN 'Drill well'
WHEN type_of_water_source = 'shared_tap' AND time_in_queue >= 30 THEN CONCAT('Install', FLOOR(time_in_queue/30), 'taps nearby')
ELSE null
End as Improvement
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1                -- This must always be true
AND (                     -- AND one of the following (OR) options must be true as well.
results != 'Clean'
OR type_of_water_source IN ('tap_in_home_broken','river')
OR (type_of_water_source = 'shared_tap' AND time_in_queue >= 30)
);

-- Improvement of in home taps broken
SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results,
CASE 
WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO Filter'
WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO Filter'
WHEN water_source.type_of_water_source = 'river' THEN 'Drill well'
WHEN type_of_water_source = 'shared_tap' AND time_in_queue >= 30 THEN CONCAT('Install', FLOOR(time_in_queue/30), 'taps nearby')
WHEN type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose Local Infrastructure'
ELSE null
End as Improvement
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1                -- This must always be true
AND (                     -- AND one of the following (OR) options must be true as well.
results != 'Clean'
OR type_of_water_source IN ('tap_in_home_broken','river')
OR (type_of_water_source = 'shared_tap' AND time_in_queue >= 30)
);





