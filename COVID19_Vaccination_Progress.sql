create table covid19_data(
iso_code varchar(255),
	continent varchar(255),
	location varchar(255),
	date date,
	total_cases numeric,
	total_vaccinations numeric,
	people_vaccinated numeric,
	people_fully_vaccinated numeric,
	new_vaccinations numeric,
	new_vaccinations_smoothed numeric,
	total_vaccinations_per_hundred numeric,
	people_vaccinated_per_hundred numeric,
	people_fully_vaccinated_per_hundred	numeric,
	new_vaccinations_smoothed_per_million numeric,
	population numeric	
)

--Data exploration using covid19_data table
select * 
from
	covid19_data
order by
	3,4;

--Checking distinct continents
select distinct(continent)
from
	covid19_data
order by
	1;

--Checking distinct locations in data
select distinct(location)
from
	covid19_data
where
	continent is not null
order by
	1;

--Country Vs.Total Vaccination
select
	location, 
	date,
	total_vaccinations
from 
	covid19_data
where
	continent is not null
order by 
	1,2;

--Country Vs.Total Vaccination(cumulative)
select
	location, 
	date
	total_vaccinations,
	sum(total_vaccinations) over(partition by location order by date ) as cum_total_vaccinations
from 
	covid19_data
where
	continent is not null and 
	total_vaccinations is not null and 
	total_vaccinations!=0
order by 
	1 ;
	
--monthly Vaccination
select
	TO_CHAR(date,'Mon,YYYY') as Month,
	sum(new_vaccinations_smoothed) as Monthly_vaccinations
from
	covid19_data
where
	continent is not null and 
	new_vaccinations_smoothed is not null
group by
	Month
order by
	2 ;

--Total Vacc Vs. Total Cases
select
	TO_CHAR(date,'Mon,YYYY') as Month,
	sum(total_vaccinations) as total_vaccinations,
	sum(total_cases) as total_cases
from
	covid19_data
where
	continent is not null and 
	total_vaccinations is not null
group by
	Month
order by
	 2,3 ;
	 
--Continent Vs.Total_Vaccination(cumulative)
select
	--location,
	continent, 
	date,
	total_vaccinations,
	sum(total_vaccinations) over(partition by continent order by date ) as cumulative_total_vaccinations_con
from 
	covid19_data
where
	continent is not null and
	total_vaccinations is not null
group by 
	continent,
	date,
	total_vaccinations
order by 
	1;

create table covid19_vaccine(
	location varchar(255),
	iso_code varchar(255),
	last_observation_date date,
	vaccines varchar(255)
)

--Data exploration using covid19_vaccine table
select 
	location,
	vaccines
from 
	covid19_vaccine
order by 
	1,2;

--Vaccines used per country
select
	location,
    trim(regexp_split_to_table(vaccines, ',')) as vaccines_name
from
	covid19_vaccine;

--CTE
--Vaccine Count
with count_table(vaccines_name) as
(
select
	trim(regexp_split_to_table(vaccines, ',')) as vaccines_name
	--count (vaccines_name) as vaccines_count
from
	covid19_vaccine
)

select *,count (vaccines_name) as vaccines_count
from
	count_table
group by
	vaccines_name
order by
	2 desc;
	
--share of population not yet vaccinated
with no_vacc as
(
select
	location,
	population,
	coalesce(max(people_vaccinated), 0) as number_people_vaccinated
from 
	covid19_data
where
	continent is not null and
	location not in ('Northern Cyprus')
group by
	location,
	population
)
select *,
	(avg(population)-sum(number_people_vaccinated))/avg(population)*100 as percent_notvaccinated
from
	no_vacc
group by
	location,
	population,
	number_people_vaccinated
order by
	4 desc;

--view tables for visualizations 
--1.Status of vaccination administered-total,partially,fully
create view status_vaccination_administered as
select
	sum(total_vaccinations) as total_vaccinations,
	sum(people_vaccinated) as people_partially_vaccinated,
	sum(people_fully_vaccinated) as people_fully_vaccinated
	
from 
	covid19_data
where
	continent is not null and 
	total_vaccinations is not null;
--order by 1,2;

--2.Country Vs Total Vaccination(cumulative)
create view Country_Vs_TotalVacc as
select
	location, 
	date
	total_vaccinations,
	sum(total_vaccinations) over(partition by location order by date ) as cum_total_vaccinations
from 
	covid19_data
where
	continent is not null and 
	total_vaccinations is not null and 
	total_vaccinations!=0
order by 
	1 ;
	
--3.Monthly Vaccination
create view Monthly_Vacc as
select
	TO_CHAR(date,'Mon,YYYY') as Month,
	sum(new_vaccinations_smoothed) as Monthly_vaccinations
from
	covid19_data
where
	continent is not null and 
	new_vaccinations_smoothed is not null
group by
	Month
order by
	2 ;

--4.Total Vacc Vs. Total Cases
create view TotalVaccVsTotalCases as
select
	TO_CHAR(date,'Mon,YYYY') as Month,
	sum(total_vaccinations) as total_vaccinations,
	sum(total_cases) as total_cases
from
	covid19_data
where
	continent is not null and 
	total_vaccinations is not null
group by
	Month
order by
	3,2 ;
	 
--5.Vaccines used per country
create view Vaccines_Per_country as
select
	location,
    trim(regexp_split_to_table(vaccines, ',')) as vaccines_name
from
	covid19_vaccine;

--6.Number of vaccines used
create view vaccine_count as
with count_table(vaccines_name) as
(
select
	trim(regexp_split_to_table(vaccines, ',')) as vaccines_name
from
	covid19_vaccine
)

select *,
	count(vaccines_name) as vaccine_count
from
	count_table
group by
	vaccines_name
order by
	2 desc;
	
--7. Country_NoVacc
create view Country_NoVacc as
with no_vacc as
(
select
	location,
	population,
	coalesce(max(people_vaccinated), 0) as number_people_vaccinated
from 
	covid19_data
where
	continent is not null and
	location not in ('Northern Cyprus')
group by
	location,
	population
)
select *,
	(avg(population)-sum(number_people_vaccinated))/avg(population)*100 as percent_notvaccinated
from
	no_vacc
group by
	location,
	population,
	number_people_vaccinated
order by
	4 desc;