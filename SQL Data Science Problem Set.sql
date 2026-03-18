--Create Tables
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

--Insert Data
INSERT INTO users VALUES
(1,'2025-01-01','USA'),
(2,'2025-01-01','Canada'),
(3,'2025-01-02','USA'),
(4,'2025-01-03','UK'),
(5,'2025-01-04','Canada');

INSERT INTO events VALUES
(1,1,'login','2025-01-01'),
(2,1,'view','2025-01-01'),
(3,1,'purchase','2025-01-02'),
(4,2,'login','2025-01-01'),
(5,2,'view','2025-01-03'),
(6,3,'view','2025-01-02'),
(7,3,'login','2025-01-05'),
(8,4,'view','2025-01-03'),
(9,4,'add_to_cart','2025-01-03'),
(10,5,'view','2025-01-04');

INSERT INTO purchases VALUES
(1,1,'2025-01-02',120),
(2,2,'2025-01-04',80),
(3,3,'2025-01-06',200),
(4,1,'2025-01-07',60);

-- Data Science SQL Problems

--1. Calculate the daily number of active users based on the events table.
select event_date as date, count(distinct(user_id)) as dau
	from events
	group by event_date;

--2. Find how many new users signed up each day.
select signup_date, count(user_id) as new_user
	from users
	group by signup_date
	order by signup_date;

--3. For each signup date, calculate how many users returned within 7 days.
select  u.signup_date as signup_date, count(distinct(e.user_id)) as retained_users
	from users u
	join events e on e.user_id=u.user_id
where e.event_date > u.signup_date and e.event_date <= u.signup_date + INTERVAL '7 days'
group by u.signup_date

--4. Calculate total revenue per user.
select user_id, sum(revenue) as lifetime_revenue
from purchases
group by user_id;

--5. Calculate total revenue per user.
select u.country as country, sum(p.revenue) as revenue
from users u
join purchases p on u.user_id=p.user_id
group by country
order by revenue desc
limit 3;

--6. Calculate the conversion rate from view → purchase
--conversion_rate = purchasers / viewers
select
(select count(distinct(user_id))
from events
where event_type='purchase')
/
(select count(distinct(user_id))
from events
where event_type='view')
as convertion_rate;

-- Comment the aswer is 1/15 which is 0.06. Even when I add a round it still shows 0

--7. For each user, calculate days between signup and first purchase.
select u.user_id, min(p.purchase_date) - u.signup_date as days_to_purchase 
from users u
join purchases p on u.user_id=p.user_id
group by u.user_id,u.signup_date;
	
--8. Calculate 7-day rolling revenue.
select purchase_date as date, revenue,
	sum(revenue) over(order by purchase_date rows 6 preceding) as rolling_7d_revenue
	from purchases;

--10 Advanced SQL Data Science Problems
