-- COVID 19 DATA FROM 2020-01-22 TO 2021-04-30 - DATA from OurWorldinData.org -- 

-- Looking into Covid 19 Database to see correlations between Vaccinations and Deaths--
-- Examples used will be on the United States--
 
/* Show tabLe */
SELECT *
FROM Covid_Deaths;

SELECT *
FROM Covid_Vac;

/*Data we will be using*/
SELECT location, date, total_cases, total_deaths, population, new_deaths
FROM Covid_Deaths

/* Percentages of Total Cases and Total Deaths*/
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM Covid_Deaths;

/* Looking at death percentages from United States during 2020-01-22 to 2021-04-30 */
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM covid_deaths
WHERE location = 'United States' 
ORDER BY 1,2;
--AS of 2020-04-28, the total death percentage reached it's peak at 6% of all cases until 2020-05-30--

/* Looking into Total Cases and Population */
-- Shows amount of Covid Cases by United States Population -- 
SELECT location, date, total_cases, total_deaths,population, (total_cases/population)*100 AS Total_Population_Infected
FROM covid_deaths
WHERE location = 'United States' 
ORDER BY 1,2;
-- As of 2020-03-01 the population infected reached it's peak of over 9% in the Unied States--

/* Looking at Countries with Highest death rate compared to population*/
SELECT location, population, MAX(total_deaths) AS Highest_Death_Count, MAX((total_cases/population))*100 AS Most_Infected_By_Percentage
FROM covid_deaths
GROUP BY location,population
ORDER BY Most_Infected_By_Percentage DESC
--The Country of Andorra had most infected by 17%--

SELECT location, population, MAX(cast(total_deaths as INT)) AS Total_Death_Count, MAX((total_cases/population))*100 AS Most_Infected_By_Percentage
FROM covid_deaths
WHERE continent is not null
GROUP BY location,population
ORDER BY Total_Death_Count DESC;
-- United States is number 1 in Highest Death Count with 576,232 with only 9% infected out of the whole population as of 2021-04-30--

/* Looking at Total Death Count by Continent and Most Infected by Population*/
SELECT location,population, MAX(cast(total_deaths as INT)) AS Total_Death_Count, MAX((total_cases/population))*100 AS Most_Infected_By_Percentage
FROM covid_deaths
WHERE continent is null 
GROUP BY location,population
ORDER BY Total_Death_Count DESC;
--Europe is number 1 in Total Death Count with 1,016,750 people--


---USING JOIN AND TEMP TABLE---

--Looking at Total Population with Vaccinations in the United States using JOIN--

/*Show vaccinations provided from a daily basis with total amount of vaccinations*/
SELECT dea.continent, dea.location, dea.date, dea.population,dea.total_cases,dea.total_deaths, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS Rolling_Vaccination
FROM Covid_Deaths dea JOIN Covid_Vac vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.location = 'United States' AND dea.continent is not null;
-- Vaccinations started at 2020-12-21 in the United States with 57,909 new vaccinations---
-- Vaccinations were not given out until after 18,153,724 total cases were reported in 2020-12-21

--Looking at total cases and deaths with new_vaccinations by percentage of vaccinations given on a daily basis in the United States--
/*total cases with new_vaccination*/
SELECT dea.continent, dea.location, dea.date, dea.population,dea.total_cases,dea.total_deaths, vac.new_vaccinations, (vac.new_vaccinations/dea.total_cases)*100 AS Vaccination_Given_Percentage
FROM Covid_Deaths dea JOIN Covid_Vac vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.location = 'United States' AND dea.continent is not null AND vac.new_vaccinations is not null;

/*New Vaccinations and New Deaths in the United States*/
--Shows results of New Deaths before and after New Vaccination was given using a rolling average--
SELECT dea.continent, dea.location, dea.date, dea.population,dea.total_cases, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS Rolling_Vaccination, new_deaths,
SUM(CAST(dea.new_deaths as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS Rolling_deaths, (dea.total_deaths/dea.total_cases)*100 AS death_percentage
FROM Covid_Deaths dea JOIN Covid_Vac vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.location = 'United States' AND dea.continent is not null;

--TEMP TABLE--

/*Using Temp Table to show percentage of vaccinated people compared to the whole population in the United States*/
DROP TABLE if exists #Percent_Pop_Vacc
CREATE TABLE #Percent_Pop_Vacc
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_People_Vacc numeric
)

INSERT INTO #Percent_Pop_Vacc

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS Rolling_People_Vacc
FROM Covid_Deaths dea JOIN Covid_Vac vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.location = 'United States';

SELECT *, (Rolling_People_Vacc/Population)*100 AS Percentage_Population_Vaccination
FROM #Percent_Pop_Vacc;
-- As of 2021-04-30 over 68% of the population in the United States is Vaccinated--

/*Dividing daily total new deaths by daily total new vaccinations to find percentage of deaths compared to vaccinations*/

--TEMP TABLE--
DROP TABLE IF EXISTS #Percent_Pop
CREATE TABLE #Percent_Pop
(
continent varchar(255),
location varchar(255),
date datetime,
population numeric,
new_deaths numeric,
Rolling_People_Deaths numeric,
new_vaccinations numeric,
Rolling_People_Vacc numeric,
)

INSERT INTO #Percent_Pop
 
SELECT dea.continent, dea.location, dea.date, dea.population,dea.new_deaths, vac.new_vaccinations
, SUM(CONVERT(int,dea.new_deaths)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS Rolling_People_Deaths,
 SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS Rolling_People_Vacc
FROM Covid_Deaths dea JOIN Covid_Vac vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.location = 'United States';

SELECT *,(Rolling_People_Deaths/population)*100 AS Percentage_Death_Population, 
(Rolling_People_Vacc/population)*100 AS Percentage_Vaccine_Population, (Rolling_People_Deaths/Rolling_People_Vacc)*100 AS Percentage_Deaths_Vaccinated
 FROM #Percent_Pop

 -- Amount of deaths grew smaller compared to amount of vaccinations by population in the United States --  






