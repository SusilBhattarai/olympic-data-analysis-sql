-- Database: Olympic_database

CREATE DATABASE "Olympic_database"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
	
	
	DROP TABlE IF EXISTS OLMYPICS_HISTORY;
CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY
(
    id      INT,
    name    VARCHAR,
    sex     VARCHAR,
    age     VARCHAR,
    height  VARCHAR,
    weight  VARCHAR,
    team    VARCHAR,
    noc     VARCHAR,
    games   VARCHAR,
    year    INT,
    season  VARCHAR,
    city    VARCHAR,
    sport   VARCHAR,
    event   VARCHAR,
    medal   VARCHAR 

);

DROP TABlE IF EXISTS OLMYPICS_HISTORY_NOC_REGIONS;
CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY_NOC_REGIONS
(
    noc     VARCHAR,
    region  VARCHAR,
    notes   VARCHAR 
);

	
ALTER TABLE public.olympics_history
ALTER COLUMN games TYPE VARCHAR(255); -- Adjust the length based on your data


--Total number of olympics games held as per dataset.

select count(distinct games) as total_olympic_games
from OLYMPICS_HISTORY;

-- List of all the olympic fames held so far.
select year,season,city 
from OLYMPICS_HISTORY
order by year asc;

--Total number of country participated in each olympic games.
select games,r.region from OLYMPICS_HISTORY as h 
join OLYMPICS_HISTORY_NOC_REGIONS  as r
on h.NOC = r.NOC;

-- the above problem can also be done following way:
with all_countries as 
	(
	select games,nr.region
	from OLYMPICS_HISTORY as oh
	join OLYMPICS_HISTORY_NOC_REGIONS as nr on nr.noc=oh.noc
	group by games, nr.region
	)
select games, count(1) as total_countries
from all_countries
group by games 
order by games;

--Olympic games which had the highest and lowest participating countries.
with all_countries as
(
	select sport,games, nr.region from OLYMPICS_HISTORY as oh
	join OLYMPICS_HISTORY_NOC_REGIONS as nr
	on oh.noc = nr.noc
	group by games,sport, nr.region
),
  tot_countries as
    (select games,count(1) as total_countries
	from all_countries  
	group by games)
	
select distinct 
     concat(first_value (games) over(order by total_countries),
	 '-',
	 first_value(total_countries) over(order by total_countries))  as Lowest_Countries,
	 concat(first_value(games) over(order by total_countries desc),
	 '-',
	 first_value (total_countries) over(order by total_countries desc)) as Highest_Countries
	 from tot_countries
	 order by 1;

SELECT * FROM OLYMPICS_HISTORY;	
SELECT * FROM OLYMPICS_HISTORY_NOC_REGIONS;	

--To fetch the list of all sports which have been part of every summer olympics.
-- 1. Find total number of summer olympic games 
-- 2. Find for each sport, how many games where they played in.
-- 3. compare 1 and 2.

with t1 as 
	(select count(distinct games ) as total_summer_games
	from OLYMPICS_HISTORY 
	where season = 'Summer'),
	
	t2 as 
	(select distinct sport, games 
	from OLYMPICS_HISTORY 
	where season = 'Summer'),
	
	t3 as 
	(select sport, count(games) as no_of_games
	from t2
	group by sport)
	 
	select * 
	from t3 
	join t1 on t1.total_summer_games = t3.no_of_games;
	
--To fetch the to 5 athletes who have won the most gold medals.
with t1 as
	(select name, count(1) as total_medals 
	from OlYMPICS_HISTORY
	where medal = 'Gold'
	group by name
	order by count(1) desc),
	
t2 as 
	(select * ,dense_rank() over(order by total_medals desc) as rnk
	from t1) 
	
select * 
from t2
where rnk <= 5;

--To list down the total gold, silver and bronze medals won by each country 
create extension tablefunc; --To run the crosstab function.

select country
,coalesce(gold, 0) as gold
,coalesce(silver, 0)as silver
,coalesce(bronze,0) as bronze
from crosstab ('select nr.region as country,medal,count(1) as total_medals
	from OLYMPICS_HISTORY as oh
	join OLYMPICS_HISTORY_NOC_REGIONS as nr on nr.noc=oh.noc
	where medal <> ''NA''
    group by nr.region,medal
	order by nr.region,medal',
	'values (''Bronze''),(''Gold''),(''Silver'')')		  
	as result (country varchar, bronze bigint, gold bigint, silver bigint)
order by gold desc, silver desc, bronze desc;

--To fetch total number of sports played in each olumpic games.
with t1 as 
	(select distinct games, sport
	from olympics_history),
	t2 as 
	(select games, count(1) as no_of_sports
	from t1
	group by games)
	select * from t2
	order by no_of_sports desc;
	
--To find the ratio of male and female athletes participated.
with t1 as 
	(select sex, count(1) as cnt
	from olympics_history
	group by sex),
t2 as
	(select *,row_number() over(order by cnt) as rn
	from t1)	,
min_cnt as
	(select cnt from t2 where rn = 1),
max_cnt as 
	(select cnt from t2 where rn = 2)
select concat('1: ', round(max_cnt.cnt::decimal/min_cnt.cnt,2)) as ratio
from min_cnt, max_cnt;