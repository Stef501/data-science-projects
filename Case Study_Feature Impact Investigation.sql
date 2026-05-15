--Case Study: Feature Impact Investigation

-- Create Tables
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    signup_date DATE,
    country VARCHAR(50)
);

CREATE TABLE events (
    user_id INT,
    event_date DATE,
    event_type TEXT
);

CREATE TABLE purchases (
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
INSERT INTO users (user_id, signup_date, country) VALUES
(1, '2024-01-01', 'US'),
(2, '2024-01-02', 'US'),
(3, '2024-01-03', 'CA'),
(4, '2024-01-04', 'CA'),
(5, '2024-01-05', 'US'),
(6, '2024-01-06', 'US'),
(7, '2024-01-07', 'CA'),
(8, '2024-01-08', 'US'),
(9, '2024-01-09', 'CA'),
(10, '2024-01-10', 'US'),
(11, '2024-01-15', 'US'),
(12, '2024-01-15', 'CA'),
(13, '2024-01-16', 'US'),
(14, '2024-01-16', 'CA'),
(15, '2024-01-17', 'US'),
(16, '2024-01-17', 'CA'),
(17, '2024-01-18', 'US'),
(18, '2024-01-18', 'CA'),
(19, '2024-01-19', 'US'),
(20, '2024-01-19', 'CA');

INSERT INTO events (user_id, event_date, event_type) VALUES
-- CONTROL (good funnel)
(1, '2024-01-02', 'view'),
(1, '2024-01-02', 'add_to_cart'),
(1, '2024-01-02', 'purchase'),
(2, '2024-01-03', 'view'),
(2, '2024-01-03', 'add_to_cart'),
(3, '2024-01-04', 'view'),
(3, '2024-01-04', 'add_to_cart'),
(3, '2024-01-04', 'purchase'),
(4, '2024-01-05', 'view'),
(5, '2024-01-06', 'view'),
(5, '2024-01-06', 'add_to_cart'),
(5, '2024-01-06', 'purchase'),
(6, '2024-01-07', 'view'),
(6, '2024-01-07', 'add_to_cart'),
(7, '2024-01-08', 'view'),
(7, '2024-01-08', 'purchase'),
(8, '2024-01-09', 'view'),
(8, '2024-01-09', 'add_to_cart'),
(8, '2024-01-09', 'purchase'),
(9, '2024-01-10', 'view'),
(10, '2024-01-11', 'view'),
(10, '2024-01-11', 'add_to_cart'),
(10, '2024-01-11', 'purchase'),

-- TREATMENT (more activity, worse conversion)
(11, '2024-01-15', 'view'),
(11, '2024-01-15', 'view'),
(12, '2024-01-15', 'view'),
(12, '2024-01-15', 'add_to_cart'),
(13, '2024-01-16', 'view'),
(14, '2024-01-16', 'view'),
(14, '2024-01-16', 'add_to_cart'),
(15, '2024-01-17', 'view'),
(16, '2024-01-17', 'view'),
(16, '2024-01-17', 'purchase'),
(17, '2024-01-18', 'view'),
(18, '2024-01-18', 'view'),
(18, '2024-01-18', 'add_to_cart'),
(19, '2024-01-19', 'view'),
(20, '2024-01-19', 'view');

INSERT INTO purchases (user_id, purchase_date, revenue) VALUES
-- CONTROL
(1, '2024-01-02', 100),
(3, '2024-01-04', 120),
(5, '2024-01-06', 90),
(8, '2024-01-09', 110),
(10, '2024-01-11', 130),

-- TREATMENT (fewer + lower value)
(16, '2024-01-17', 70);

INSERT INTO experiments (user_id, experiment_group, experiment_start) VALUES
-- Control group (before/neutral experience)
(1, 'control', '2024-01-01'),
(2, 'control', '2024-01-01'),
(3, 'control', '2024-01-01'),
(4, 'control', '2024-01-01'),
(5, 'control', '2024-01-01'),
(6, 'control', '2024-01-01'),
(7, 'control', '2024-01-01'),
(8, 'control', '2024-01-01'),
(9, 'control', '2024-01-01'),
(10, 'control', '2024-01-01'),

-- Treatment group (1-click checkout)
(11, 'treatment', '2024-01-15'),
(12, 'treatment', '2024-01-15'),
(13, 'treatment', '2024-01-15'),
(14, 'treatment', '2024-01-15'),
(15, 'treatment', '2024-01-15'),
(16, 'treatment', '2024-01-15'),
(17, 'treatment', '2024-01-15'),
(18, 'treatment', '2024-01-15'),
(19, 'treatment', '2024-01-15'),
(20, 'treatment', '2024-01-15');

--Q1 Compare funnel conversion rates:
	--BEFORE 2024-01-15
	--AFTER 2024-01-15

--Split Data Into Pre and Post
with events_pre_post as
	(select
		*,
		case 
			when event_date < '2024-01-15' then 'pre'
			else 'post'
		end as period
	from events),

-- Create User funnel from events split data for control and treatment group
user_funnel as
	(select
		period,
		user_id,
		max(case when event_type='view' then 1 else 0 end) as viewer,
		max(case when event_type='add_to_cart' then 1 else 0 end) as adder,
		max(case when event_type='purchase' then 1 else 0 end) as purchaser
	from events_pre_post
	group by user_id, period),

-- Calculate user funnel counts for control group
user_funnel_counts as
	(select
		period,
		'view' as stage,
		count(*) as users
	from user_funnel
	where viewer=1
	group by period	
	
	union all

	select
		period,
		'add_to_cart' as stage,
		count(*) as users
	from user_funnel
	where viewer=1 and adder=1
	group by period


	union all

	select
		period,
		'purchase' as stage,
		count(*) as users
	from user_funnel
	where viewer=1 and adder=1 and purchaser=1
	group by period),

ordered as
    (select
        period,
        stage,
        users,
        case stage
            when 'view' then 1
            when 'add_to_cart' then 2
            when 'purchase' then 3
        end as stage_order,
        case period
            when 'pre' then 1
            when 'post' then 2
        end as period_order
    from user_funnel_counts)

-- calculate conversion rates between user counts within periods
select
	period,
	stage,
	users,
	users/lag(users) over(partition by period
	order by 
		stage_order
		)::float as conversion_from_previous
from ordered
order by 
	period_order, 
	stage_order;

--Comments
-- Funnel conversion rates decrease from pre to post both due to lower add-to-carts and purchases but not due to views.

--Q2. Did users acquired after launch retain worse?
--Compute:
--signup_date cohort → % returning within 7 days

--Split Data Into Pre and Post
with events_pre_post as
	(select
		u.user_id,
        u.signup_date,
        e.event_date,
		case 
			when u.signup_date < '2024-01-15' then 'pre'
			else 'post'
		end as period
	from users u
	left join events e on u.user_id=e.user_id),

--calculate retention
retention as
	(select 
		period,
		signup_date,
		count(distinct(user_id)) as users,
		count (distinct 
			case 
				when event_date > signup_date 
				and event_date <= signup_date + interval '7 days'
				then user_id
				else null
			end) as retained_users,
		count (distinct 
			case 
				when event_date > signup_date 
				and event_date <= signup_date + interval '7 days'
				then user_id
				else null
			end)
		/
		count(distinct(user_id))::float as retention_rate
	from events_pre_post
	group by period, signup_date
	order by period desc, signup_date)

--Average of pre and post retention rates for comparison
select
	period,
	avg(retention_rate) as avg_retention_rate
	from retention
	group by period;
		
--Comments:
--Users aquired after launch were not retained better.

	
--Q3. Why did revenue drop?
-- Break ARPU into:
--ARPU = conversion_rate × avg_order_value
--conversion_rate = number of purchasers/number of unique users
--Output:
--period | conversion_rate | avg_order_value | arpu

--Define Users in the pre and post period according to treatment group
with users_by_period as
(select
	user_id,
	case 
		when experiment_group='control' then 'pre'
		else 'post'
	end as period
from experiments)

--Calculate Conversion Rate & ARPU 
select
	u.period,
	count(distinct case when p.user_id is not null then u.user_id end)
	/count(distinct (u.user_id))::float  as convertion_rate,
	avg(p.revenue) as avg_order_value ,
	(count(distinct case when p.user_id is not null then u.user_id end)
	/count(distinct (u.user_id))::float)
	*avg(p.revenue) as arpu
	from users_by_period u
	left join purchases p on u.user_id=p.user_id
	group by u.period
	order by u.period desc;

--By calculating user_by period, I link all calcs at the user level to connect to the period.
-- Both the convertion rate and the average order value decreases from pre to post

--Q.4 Did DAU increase because of low-quality users?
--Compute:
--Daily_active_users
--% of users who never purchased

--Define Users in the pre and post period according to treatment group
with users_by_period as
(select
	user_id,
	case 
		when experiment_group='control' then 'pre'
		else 'post'
	end as period
from experiments),

--Calc Dau
-- I am just showing the DAU by event date to have calc in this table but will aggregate by period later along with adding the proportion of non-purchasers together to compare
dau_table as
	(select 
		e.event_date,
		u.period, 
		count(distinct(e.user_id)) as dau
	from events e
	join users_by_period u on e.user_id=u.user_id
	group by u.period, e.event_date),

--Calculation of avg dau to match grains
avg_dau_table as
	(select
		period,
		avg(dau) as avg_dau
	from dau_table
	group by period),

--Define active users and purchasers
active_users as (
    select distinct user_id
    from events),

purchasers as 
	(select distinct user_id
    from purchases),

-- Calculation of % of non_purchsases from users to match grains
	non_purchasers_active as (
    select
        u.period,
        1 -(count(distinct case when p.user_id is not null then a.user_id end)
        / count(distinct a.user_id)::float
        ) as non_purchasers_active
    from users_by_period u
    join active_users a on u.user_id = a.user_id
    left join purchasers p on a.user_id = p.user_id
    group by u.period)

--Dau aggregation to average DAU between Pre and Post and combined with % of non-purchsases for comparison
select
	ad.period,
	ad.avg_dau,
	n.non_purchasers_active
	from avg_dau_table ad
	join non_purchasers_active n on ad.period=n.period
	order by period desc;
	
--Comments
--The Dau inreased from the pre to post perdiod, however the proportion of non-purchasers also increases and by roughly the same proportion. this indicated that even with DAU increasing it is notlikely that those additional users will be purhasing. This finding is also consistent with the funnel conversion rates fro pre to post
--The calculation of % of users who never purchased was requested. However, since DAU is an activity-based metric, I would want to check the % of active users who never purchased to ensure we’re comparing consistent populations.

--Q5: Compare treatment vs control:
--Output: group | conversion_rate | arpu | lift

--Calculate metrics
with metrics as
(select
	ex.experiment_group as "group",
	count(distinct case when p.user_id is not null then ex.user_id end)
        / count(distinct ex.user_id)::float as conversion_rate,
	sum(p.revenue)/count(distinct(ex.user_id)) as arpu
	from experiments ex
	left join purchases p on ex.user_id=p.user_id
	group by ex.experiment_group),

--Separate control variables
control as
    (select
		conversion_rate as control_cr,
		arpu as control_arpu
	FROM metrics
	where "group"='control')	

--cross join control variables, apply lift calculations, join with metrics
select
	m.group,
	m.conversion_rate,
	m.arpu,
 	(m.conversion_rate - c.control_cr) / nullif(c.control_cr,0) as lift_conversion_rate,
 	(m.arpu - c.control_arpu) / nullif(c.control_arpu,0) as lift_arpu
from metrics m
cross join control c;

-- In this final query when comparing the major metrix we can see that all metrics decrease as we move from control to treatment groups.
-- Conversion drops as there are fewer people purchasing of the treatment cohort.
-- Arpu drops as there is both a decrease in purchasers regarding the treatment cohort and a decrease in the average value per order as seen in Q3.
-- This decrease among the metricsis also reflected in the lift values for both conversion rates and arpu.

	
 