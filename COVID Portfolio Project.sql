/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM
	COVIDPortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM
	--COVIDPortfolioProject.dbo.CovidVaccinations
--ORDER BY 3,4

--Select Relevant Data for Project

SELECT
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM
	COVIDPortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Total Cases vs Total Deaths
	-- Shows likelihood of dying if you contract covid in your country

SELECT
	location,
	date,
	total_cases,
	total_deaths,
CAST(total_deaths as bigint)/NULLIF(CAST(total_cases AS FLOAT),0)*100 AS DeathPercentage
FROM
	COVIDPortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%States%'
ORDER BY 1,2

-- Total Cases vs Population
	-- Shows what percentage of population infected with Covid

SELECT
	location,
	date,
	total_cases,
	population,
CAST(total_cases as bigint)/NULLIF(CAST(population as float),0)*100 AS PopulationInfectedPercentage
FROM
	COVIDPortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%States%'
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population

SELECT
	Location,
	Population,
MAX(total_cases) as HighestInfectionCount,
MAX((total_cases/population))*100 as PopulationInfectedPercentage
FROM
	COVIDPortfolioProject.dbo.CovidDeaths
--WHERE location LIKE '%States%'
WHERE continent IS NOT NULL
GROUP BY
	Location,
	Population
ORDER BY
	PopulationInfectedPercentage DESC

-- Countries with Highest Death Count per Population

SELECT
	Location,
MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM
	COVIDPortfolioProject.dbo.CovidDeaths
--WHERE location LIKE '%States%'
WHERE continent IS NOT NULL
GROUP BY
	Location
ORDER BY
	TotalDeathCount DESC

-- BREAKING THINGS DOWN BY CONTINENT
	-- Showing contintents with the highest death count per population

SELECT
	continent,
MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM
	COVIDPortfolioProject.dbo.CovidDeaths
--WHERE location LIKE '%States%'
WHERE continent IS NOT NULL
GROUP BY
	continent
ORDER BY
	TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT
	SUM(new_cases) as total_cases,
	SUM(cast(new_deaths as int)) as total_deaths,
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM
	COVIDPortfolioProject.dbo.CovidDeaths
--WHERE location LIKE '%States%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

-- Total Population vs Vaccinations
	-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
FROM
	COVIDPortfolioProject.dbo.CovidDeaths dea
JOIN COVIDPortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE to perform Calculation on PARTITION BY in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM
	COVIDPortfolioProject.dbo.CovidDeaths dea
JOIN COVIDPortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT
	*, (RollingPeopleVaccinated/Population)*100
FROM
	PopvsVac

-- Using Temp Table to perform Calculation on PARTITION BY in previous query

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM
	COVIDPortfolioProject.dbo.CovidDeaths dea
JOIN COVIDPortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM
	#PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW
	PercentPopulationVaccinated AS
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM
	COVIDPortfolioProject.dbo.CovidDeaths dea
JOIN COVIDPortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated