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


/*Vytvo�en� tabulky pro data mezd a cen potravin za �eskou republiku 
 * sjednocen�ch na toto�n� porovnateln� obdob� � spole�n� roky.*/

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


/* 1. Rostou v pr�b�hu let mzdy ve v�ech odv�tv�ch, nebo v n�kter�ch klesaj�? */

select
	distinct payroll_year,
	value_type,
	year_value,
	industry_branch
from 
	t_eliska_sklenarova_project_sql_primary_final
where 
	value_type = "Pr�m�rn� hrub� mzda na zam�stnance" and 
	calculation = "fyzick�" and 
	industry_branch is not NULL
order by 
	industry_branch, year
;

/* Odpov�di k jednotliv�m odv�tv�m - zda mzdy rostou nebo v n�kter�ch letech klesaj�:
	   
	   > Administrativn� a podp�rn� �innosti - mzdy v pr�b�hu let rostou.
	   > �innosti v oblasti nemovitost� - rostou, m�rn� pokles 2013.
	   > Doprava a skladov�n� - mzdy v pr�b�hu let rostou.
	   > Informa�n� a komunika�n� �innosti - rostou, m�rn� pokles 2013.
	   > Kulturn�, z�bavn� a rekrea�n� �innosti - rostou, m�rn� pokles 2011 a 2013.
	   > Ostatn� �innosti - rostou.
	   > Pen�nictv� a poji��ovnictv� - rostou, v�razn� pokles 2013.
	   > Profesn�, v�deck� a technick� �innosti - rostou, pokles 2010 a 2013.
	   > Stavebnictv� - mzdy v pr�b�hu let rostou, pokles: 2013.
	   > T�ba a dob�v�n� - mzdy v pr�b�hu let rostou, ale poklesy: 2009, 2013, 2014, 2016.
	   > Ubytov�n�, stravov�n� a pohostinstv� - mzdy v pr�b�hu let rostou, poklesy: 2009, 2011.
	   > Velkoobchod a maloobchod; opravy a �dr�ba motorov�ch vozidel - mzdy v pr�b�hu let rostou, poklesy: 2009 (velmi m�rn�), 2013.
	   > Ve�ejn� spr�va a obrana; povinn� soci�ln� zabezpe�en� - rostou, pokles 2010, 2011.
	   > V�roba a rozvod elekt�iny, plynu, tepla a klimatiz. vzduchu - mzdy v pr�b�hu let rostou, poklesy: 2013 a 2015.
	   > Vzd�l�v�n� - rostou, pokles 2010.
	   > Z�sobov�n� vodou; �innosti souvisej�c� s odpady a sanacemi -  mzdy v pr�b�hu let rostou, pokles: 2013.
	   > Zdravotn� a soci�ln� p��e - rostou.
	   > Zem�d�lstv�, lesnictv�, ryb��stv� - mzdy v pr�b�hu let rostou.
	   > Zpracovatelsk� pr�mysl - mzdy v pr�b�hu let rostou.
	  
	  Trend je tedy pochopiteln� takov�, �e mzdy obecn� ka�doro�n� rostou, v n�kter�ch odv�tv�ch v�razn�ji, v n�kter�ch m�n� z�sadn�.
	  Nej�asteji byl pokles zaznamen�n v roce 2013, d�le se opakovaly roky 2009, 2010 a 2011.
	   
	 */



/*2. Kolik je mo�n� si koupit litr� ml�ka a kilogram� chleba 
 * za prvn� a posledn� srovnateln� obdob� v dostupn�ch datech cen a mezd?*/

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
		when name = "Ml�ko polotu�n� pasterovan�" then ROUND((year_value/average_value),2)
		else ROUND((year_value/average_value),2)
	end as kupni_sila
from 
	t_eliska_sklenarova_project_sql_primary_final
where 
	industry_branch is null and 
	(year = "2006" or year = "2018") and 
	(name = "Ml�ko polotu�n� pasterovan�" or name = "Chl�b konzumn� km�nov�") and 
	value_type = 'Pr�m�rn� hrub� mzda na zam�stnance' and
	calculation = "fyzick�"
order by 
	year
;
/*	
	Celkov� je tedy mo�n� si v roce 2006 koupit m�s��n� 1309.17 litr� ml�ka a 1172.32 kg chleba. 
	V roce 2018 1564.04 litr� ml�ka a 1278.88 kg chleba.
*/



/* 3. Kter� kategorie potravin zdra�uje nejpomaleji (je u n� nejni��� percentu�ln� meziro�n� n�r�st)? */


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


	-- pr�m�rn� meziro�n� percentu�ln� n�r�st u jednotliv�ch potravin --
select 	
	name,
	round(avg(percentage_change),2) as average_perc_change
from percentage_change_view
group by name
order by average_perc_change
;
/* Nejpomaleji tedy zdra�uje (respektive dokonce zlev�uje) b�l� cukr.*/


/* 4. Existuje rok, ve kter�m byl meziro�n� n�r�st cen potravin v�razn� vy��� ne� r�st mezd (v�t�� ne� 10 %)? */

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

/* Takov� rok neexistuje. */



/*
	5. M� v��ka HDP vliv na zm�ny ve mzd�ch a cen�ch potravin? 
	Neboli, pokud HDP vzroste v�razn�ji v jednom roce, 
	projev� se to na cen�ch potravin �i mzd�ch ve stejn�m 
 	nebo n�sduj�c�m roce v�razn�j��m r�stem?
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
 Z dat, kter� m�m, podle m� nedok�u na ot�zku p�esn� odpov�d�t - zkusila jsem si ale i tak ud�lat v Excelu
 graf - z n�j by �lo vyvodit, �e pokud na n�co z toho m� r�st HDP vliv, tak sp�e na r�st mezd.
*/




-- Jako dodate�n� materi�l p�ipravte i tabulku s HDP, GINI koeficientem --
-- a populac� dal��ch evropsk�ch st�t� ve stejn�m obdob�, jako prim�rn� p�ehled pro �R.--

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
