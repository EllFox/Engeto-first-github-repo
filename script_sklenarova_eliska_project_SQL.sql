/* VIEW nad czechia_payroll */
create or replace view modified_czechia_payroll_view AS
select
	cpvt.name as value_type,	
	avg(cp.value) as year_value,
	cpu.name as unit,
	cpib.name as industry_branch,
	cpc.name as calculation,
	cp.payroll_year	
from 
	czechia_payroll cp 
left join 
	czechia_payroll_calculation cpc on cp.calculation_code = cpc.code
left join 
	czechia_payroll_industry_branch cpib ON cp.industry_branch_code = cpib.code 
left join 
	czechia_payroll_unit cpu on cp.unit_code = cpu.code
left join 
	czechia_payroll_value_type cpvt on cp.value_type_code = cpvt.code
group by 
	value_type, 
	unit, 
	industry_branch, 
	cpc.name,
	cp.payroll_year
;


/* VIEW nad czechia_price */
create or replace view 
	modified_czechia_price_view AS
select
	avg(cpr.value) as average_value,
	year(cpr.date_from) as year,
	cpc.name,
	cpc.price_value,
	cpc.price_unit,
	cpr.region_code
from 
	czechia_price cpr
left join 
	czechia_price_category cpc on cpr.category_code = cpc.code
where 
	region_code is null
group by 
	year,
	cpc.name,
	cpc.price_value,
	cpc.price_unit,
	cpr.region_code
;


/*Vytvoøení tabulky pro data mezd a cen potravin za Èeskou republiku 
 * sjednocenıch na totoné porovnatelné období – spoleèné roky.*/

create or replace table 
	t_Eliska_Sklenarova_project_SQL_primary_final
select 
	value_type,	
	year_value,
	unit,
	industry_branch,
	calculation,
	payroll_year,
	average_value,
	year,
	name,
	price_value,
	price_unit
from 
	modified_czechia_payroll_view as mcpv
inner join 
	modified_czechia_price_view as mcprv on mcprv.year = mcpv.payroll_year
;


/* 1. Rostou v prùbìhu let mzdy ve všech odvìtvích, nebo v nìkterıch klesají? */

select
	distinct payroll_year,
	value_type,
	year_value,
	industry_branch
from 
	t_eliska_sklenarova_project_sql_primary_final
where 
	value_type = "Prùmìrná hrubá mzda na zamìstnance" and 
	calculation = "fyzickı" and 
	industry_branch is not NULL
order by 
	industry_branch, year
;

/* Odpovìdi k jednotlivım odvìtvím - zda mzdy rostou nebo v nìkterıch letech klesají:
	   
	   > Administrativní a podpùrné èinnosti - mzdy v prùbìhu let rostou.
	   > Èinnosti v oblasti nemovitostí - rostou, mírnı pokles 2013.
	   > Doprava a skladování - mzdy v prùbìhu let rostou.
	   > Informaèní a komunikaèní èinnosti - rostou, mírnı pokles 2013.
	   > Kulturní, zábavní a rekreaèní èinnosti - rostou, mírnı pokles 2011 a 2013.
	   > Ostatní èinnosti - rostou.
	   > Penìnictví a pojišovnictví - rostou, vıraznı pokles 2013.
	   > Profesní, vìdecké a technické èinnosti - rostou, pokles 2010 a 2013.
	   > Stavebnictví - mzdy v prùbìhu let rostou, pokles: 2013.
	   > Tìba a dobıvání - mzdy v prùbìhu let rostou, ale poklesy: 2009, 2013, 2014, 2016.
	   > Ubytování, stravování a pohostinství - mzdy v prùbìhu let rostou, poklesy: 2009, 2011.
	   > Velkoobchod a maloobchod; opravy a údrba motorovıch vozidel - mzdy v prùbìhu let rostou, poklesy: 2009 (velmi mírnı), 2013.
	   > Veøejná správa a obrana; povinné sociální zabezpeèení - rostou, pokles 2010, 2011.
	   > Vıroba a rozvod elektøiny, plynu, tepla a klimatiz. vzduchu - mzdy v prùbìhu let rostou, poklesy: 2013 a 2015.
	   > Vzdìlávání - rostou, pokles 2010.
	   > Zásobování vodou; èinnosti související s odpady a sanacemi -  mzdy v prùbìhu let rostou, pokles: 2013.
	   > Zdravotní a sociální péèe - rostou.
	   > Zemìdìlství, lesnictví, rybáøství - mzdy v prùbìhu let rostou.
	   > Zpracovatelskı prùmysl - mzdy v prùbìhu let rostou.
	  
	  Trend je tedy pochopitelnì takovı, e mzdy obecnì kadoroènì rostou, v nìkterıch odvìtvích vıraznìji, v nìkterıch ménì zásadnì.
	  Nejèasteji byl pokles zaznamenán v roce 2013, dále se opakovaly roky 2009, 2010 a 2011.
	   
	 */



/*2. Kolik je moné si koupit litrù mléka a kilogramù chleba 
 * za první a poslední srovnatelné období v dostupnıch datech cen a mezd?*/

select
	year,
	value_type,
	ROUND(year_value,2) as salary_avg,
	unit,
	name,
	ROUND(average_value,2) as price_avg,
	price_value,
	price_unit,
	case 
		when name = "Mléko polotuèné pasterované" then ROUND((year_value/average_value),2)
		else ROUND((year_value/average_value),2)
	end as kupni_sila
from 
	t_eliska_sklenarova_project_sql_primary_final
where 
	industry_branch is null and 
	(year = "2006" or year = "2018") and 
	(name = "Mléko polotuèné pasterované" or name = "Chléb konzumní kmínovı") and 
	value_type = 'Prùmìrná hrubá mzda na zamìstnance' and
	calculation = "fyzickı"
order by 
	year
;
/*	
	Celkovì je tedy moné si v roce 2006 koupit mìsíènì 1309.17 litrù mléka a 1172.32 kg chleba. 
	V roce 2018 1564.04 litrù mléka a 1278.88 kg chleba.
*/



/* 3. Která kategorie potravin zdrauje nejpomaleji (je u ní nejniší percentuální meziroèní nárùst)? */


create or replace view percentage_change_view AS
	select 
		distinct year,
		average_value,
		name,
		price_value,
		price_unit,
		(lead(average_value) over (partition by name order by name,year)-average_value)/average_value * 100 as percentage_change
	from t_eliska_sklenarova_project_sql_primary_final
	group by year, name
	order by name, year
	; 


	-- prùmìrnı meziroèní percentuální nárùst u jednotlivıch potravin --
select 	
	name,
	round(avg(percentage_change),2) as average_perc_change
from percentage_change_view
group by name
order by average_perc_change
;
/* Nejpomaleji tedy zdrauje (respektive dokonce zlevòuje) bílı cukr.*/


/* 4. Existuje rok, ve kterém byl meziroèní nárùst cen potravin vıraznì vyšší ne rùst mezd (vìtší ne 10 %)? */

select 
	payroll_year,
	average_value, 
	year_value as payroll,
	avg(average_value),
	(lead(year_value) over (order by year)-year_value)/year_value * 100 as percentage_change_payroll,
	(lead(avg(average_value)) over (order by year)-avg(average_value))/avg(average_value) * 100 as percentage_change_prices
from 
	t_eliska_sklenarova_project_sql_primary_final
where 
	industry_branch is null
group by 
	year
;

/* Takovı rok neexistuje. */



/*
	5. Má vıška HDP vliv na zmìny ve mzdách a cenách potravin? 
	Neboli, pokud HDP vzroste vıraznìji v jednom roce, 
	projeví se to na cenách potravin èi mzdách ve stejném 
 	nebo násdujícím roce vıraznìjším rùstem?
 */

select 
	t.payroll_year,
	(lead(t.year_value) over (order by t.year)-t.year_value)/t.year_value * 100 as salary_percent_change,
	(lead(avg(t.average_value)) over (order by t.year)-avg(t.average_value))/avg(t.average_value) * 100 as food_percent_change,
	(lead(economies.GDP) over (order by year)-economies.GDP)/economies.GDP * 100 as GDP_percent_change
from 
	t_eliska_sklenarova_project_sql_primary_final as t
left join 
	economies on economies.year  = t.year
where 
	industry_branch is null and economies.country = 'Czech Republic'
group by 
	t.year 
;
/* 
 Z dat, která mám, podle mì nedokáu na otázku pøesnì odpovìdìt - zkusila jsem si ale i tak udìlat v Excelu
 graf - z nìj by šlo vyvodit, e pokud na nìco z toho má rùst HDP vliv, tak spíše na rùst mezd.
*/




-- Jako dodateènı materiál pøipravte i tabulku s HDP, GINI koeficientem --
-- a populací dalších evropskıch státù ve stejném období, jako primární pøehled pro ÈR.--

create table 
	t_Eliska_Sklenarova_project_SQL_secondary_final
select
	year,
	c.country,
	e.population,
	GDP,
	gini
from 
	countries c 
left join 
	economies e on e.country = c.country
where 
	continent = "Europe" and 
	c.country != "Czech Republic" and 
	year > 2005 and year < 2019
order by 
	country, year
;
