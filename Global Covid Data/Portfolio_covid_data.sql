--GLOBAL COVID CASES AND VACCINATION DATA: Data Exploration

--General view of covid death data
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is null AND NOT (location LIKE '%income%')
ORDER BY 3,4
 
SELECT location,date, total_cases, new_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Calculating death rate
--Shows the probability of dying after contracting covid by country
SELECT location,date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Calculating infectivity rate
--Shows the percentage of a country's population that is infected
SELECT location,date,population,total_cases,(total_cases/population)*100 as infectivity_rate
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Exploring countries with the highest infection rate
SELECT location,population,MAX(total_cases) as highest_infection_count,Max((total_cases/population))*100 as percent_pop_infected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY percent_pop_infected desc

--Exploring countries with the highest death count 
SELECT location,MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count desc

--Exploring continents with the highest death count
SELECT location,MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is null AND NOT (location LIKE '%income%')
GROUP BY location
ORDER BY total_death_count desc

--Global total death
SELECT SUM(new_cases) as total_new_cases, SUM(cast(new_deaths as int)) as total_new_death, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as total_death_rate
FROM PortfolioProject..CovidDeaths
WHERE continent is not null AND NOT (location LIKE '%income%')
ORDER BY 1,2

--Exploring Total Population vs Total Vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as cummulative_vac
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null AND NOT (dea.location LIKE '%income%')
ORDER BY 2,3

--Calculating vaccination rate of countries (CTE Method)
With PopvsVac(continent,location,date,population,new_vaccinations,cummulative_vac)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as cummulative_vac
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null AND NOT (dea.location LIKE '%income%')
)
SELECT *, (cummulative_vac/population) * 100 as vaccination_rate
FROM PopvsVac

--Calculating vaccination rate of countries (Temp Table Method)
DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
cummulative_vac numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as cummulative_vac
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null AND NOT (dea.location LIKE '%income%')

SELECT *, (cummulative_vac/population) * 100 as vaccination_rate
FROM #PercentPopulationVaccinated

--Create View for visualisation
DROP VIEW IF exists PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as cummulative_vac
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null AND NOT (dea.location LIKE '%income%')

SELECT *
FROM PercentPopulationVaccinated