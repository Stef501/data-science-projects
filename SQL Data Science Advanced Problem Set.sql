--10 Advanced Data Science SQL Problems
-- Create Tables

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    signup_date DATE,
    country VARCHAR(50)
);

CREATE TABLE events (
    event_id INT PRIMARY KEY,
    user_id INT,
    event_type VARCHAR(50),
    event_date DATE
);

CREATE TABLE purchases (
    purchase_id INT PRIMARY KEY,
    user_id INT,
    purchase_date DATE,
    revenue DECIMAL(10,2)
);

CREATE TABLE experiments (
    user_id INT,
    experiment_group VARCHAR(20),
    experiment_start DATE
);

--Insert Data
INSERT INTO users VALUES
(1,'2025-01-01','USA'),
(2,'2025-01-01','Canada'),
(3,'2025-01-02','USA'),
(4,'2025-01-03','UK'),
(5,'2025-01-03','Canada'),
(6,'2025-01-04','USA'),
(7,'2025-01-05','USA'),
(8,'2025-01-05','UK'),
(9,'2025-01-06','Canada'),
(10,'2025-01-07','USA');

INSERT INTO events VALUES
(1,1,'view','2025-01-01'),
(2,1,'add_to_cart','2025-01-02'),
(3,1,'purchase','2025-01-02'),
(4,2,'view','2025-01-01'),
(5,2,'view','2025-01-03'),
(6,3,'view','2025-01-02'),
(7,3,'add_to_cart','2025-01-04'),
(8,4,'view','2025-01-03'),
(9,4,'add_to_cart','2025-01-03'),
(10,4,'purchase','2025-01-04'),
(11,5,'view','2025-01-03'),
(12,6,'view','2025-01-04'),
(13,6,'add_to_cart','2025-01-05'),
(14,7,'view','2025-01-05'),
(15,7,'add_to_cart','2025-01-05'),
(16,7,'purchase','2025-01-06'),
(17,8,'view','2025-01-05'),
(18,9,'view','2025-01-06'),
(19,9,'add_to_cart','2025-01-07'),
(20,10,'view','2025-01-07');

INSERT INTO purchases VALUES
(1,1,'2025-01-02',120),
(2,4,'2025-01-04',80),
(3,7,'2025-01-06',200),
(4,1,'2025-01-07',60);

INSERT INTO experiments VALUES
(1,'control','2025-01-01'),
(2,'control','2025-01-01'),
(3,'treatment','2025-01-02'),
(4,'treatment','2025-01-03'),
(5,'control','2025-01-03'),
(6,'treatment','2025-01-04'),
(7,'treatment','2025-01-05'),
(8,'control','2025-01-05'),
(9,'treatment','2025-01-06'),
(10,'control','2025-01-07');

--10 Advanced Data Science SQL Problems
--Q1. For each signup cohort, calculate the percentage of users who return within 7 days.
SELECT
    u.signup_date,
    COUNT(DISTINCT u.user_id) AS users,
    COUNT(DISTINCT CASE 
        WHEN e.event_date > u.signup_date
        AND e.event_date <= u.signup_date + INTERVAL '7 days'
        THEN u.user_id
    END) AS retained_users,
    COUNT(DISTINCT CASE 
        WHEN e.event_date > u.signup_date
        AND e.event_date <= u.signup_date + INTERVAL '7 days'
        THEN u.user_id
    END)::float
    / COUNT(DISTINCT u.user_id) AS retention_rate
FROM users u
LEFT JOIN events e
ON u.user_id = e.user_id
GROUP BY u.signup_date
ORDER BY u.signup_date;

-- Count(distinct case) is used to apply a condition inside an aggregation without filtering the entire dataset.
-- WHERE is cannot be used beause it filters rows BEFORE aggregation and sometimes we want one metric using all rows and another metric using only some rows.
-- Left Join is used because users with no events must still exist in cohort.

--Q2. Calculate the percentage of users who make a purchase within 7 days of signup
select
(select count(distinct(p.user_id))::float
from purchases p
join users u on u.user_id = p.user_id
where p.purchase_date between u.signup_date and u.signup_date + interval '7 days')
/
(select count(distinct(user_id)) from users) as conversion_rate;

--Q3. Calculate the funnel conversion rates: view → add_to_cart → purchase
--Method 1
Select *, (users)/lag(users) over (order by 
CASE stages
    WHEN 'view' THEN 1
    WHEN 'add_to_cart' THEN 2
    WHEN 'purchases' THEN 3
END)::float as conversion_from_previous
from
(select event_type as stages, count(distinct(user_id)) as users
from events
group by event_type 
ORDER BY CASE event_type
    WHEN 'view' THEN 1
    WHEN 'add_to_cart' THEN 2
    WHEN 'purchases' THEN 3
END);

--Method 2
select event_type as stages, count(distinct(user_id)) as users,
count(distinct(user_id))/lag(count(distinct(user_id))) over(
ORDER BY CASE event_type
    WHEN 'view' THEN 1
    WHEN 'add_to_cart' THEN 2
    WHEN 'purchases' THEN 3
END)::float as concersion_from_previous
from events
group by event_type;

--Comment: Why is it "order by case eventtype" and not order by event_type case
--Comment: Within the order by case, how does sql know to show the names not the numbers

--Q4. Calculate Average Revenue Per Active User per day
-- ARPU = daily_revenue / daily_active_users

select e.event_date as date, COALESCE(sum(p.revenue),0) as revenue, count(distinct(e.user_id)) as dau,
COALESCE(sum(p.revenue),0)/count(distinct(e.user_id)) as arpu
from events e
left join purchases p on e.event_date=p.purchase_date
group by e.event_date
order by date;

-- Check

--Q5. Calculate 7-day rolling active users.
select date, sum(active_users) over(order by date rows 6 preceding) as rolling_active_users
from
(select event_date as date, count(distinct(user_id)) as active_users
	from events
	group by event_date) t
	
--Q6. Find users in the top 10% of activity based on number of events.

With activity_rank as

(select user_id, count(event_type) as event_count,
percent_rank() over(order by count(event_type) Desc)::float as percentile_rank
from events
group by user_id)

select * from activity_rank
where percentile_rank<='0.1';

--Q7. Using the experiments table, calculate purchase conversion rate for control and treatment
select ex.experiment_group, 
	count(distinct(ex.user_id)) as users, 
	count(distinct(p.user_id)) as purchasers, 
	count(distinct(p.user_id))/count(distinct(ex.user_id))::float as conversion_reate
	from experiments ex
	left join purchases p on ex.user_id=p.user_id
	group by ex.experiment_group;

--Comment: A left join is used because we want to include all users in both experiment groups regardless of purchases

--Q8. Calculate the average revenue per user for Calculate the average revenue per user for control vs treatment. Then compute Lift. (lift = (treatment - control) / control)

-- Part 1: Calculation of average revenues
select ex.experiment_group as group,
	sum(p.revenue)/count(u.user_id) as arpu
	from experiments ex
	join users u on u.user_id=ex.user_id
	left join purchases p on u.user_id=p.user_id
	group by ex.experiment_group;

-- Part 2: lift Calculation of average revenues
with tc_arpu as
(select ex.experiment_group as group,
	sum(p.revenue)/count(u.user_id) as arpu
	from experiments ex
	join users u on u.user_id=ex.user_id
	left join purchases p on u.user_id=p.user_id
	group by ex.experiment_group)


select 
    (treatment_arpu - control_arpu) / control_arpu as lift
FROM (
    select
        avg(CASE WHEN "group" = 'treatment' THEN arpu END) AS treatment_arpu,
        avg(CASE WHEN "group" = 'control' THEN arpu END) AS control_arpu
    FROM tc_arpu
);

-- Comments
-- Nested Queries using CASE
-- Isolate: Use CASE statements to pull the values into their own "buckets" (columns).
-- Collapse: Use an aggregate like MAX or SUM to squish those rows together so both values sit on the same line.
-- Calculate: Now that they are "side-by-side" in the same row, you can run your lift formula.

--Q9. Calculate the average number of days between events for each user


--