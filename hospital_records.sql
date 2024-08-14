-- creation of tables--

CREATE TABLE payers (
	id VARCHAR(60),
	name VARCHAR(60),
	address VARCHAR(60),
	city VARCHAR(60),
	state_headquatered VARCHAR(40),
	zip VARCHAR(30),
	phone VARCHAR(30)
);



SELECT * 
FROM payers


CREATE TABLE patients (
	id VARCHAR(60),
	birth_date DATE,
	death_date DATE,
	prefix VARCHAR(30),
	first_name VARCHAR(60),
	last_name VARCHAR(60),
	suffix VARCHAR(50),
	maiden VARCHAR(60),
	marital VARCHAR(20),
	race VARCHAR(50),
	ethnicity VARCHAR(50),
	gender VARCHAR(20),
	birth_place VARCHAR(50),
	address VARCHAR(60),
	city VARCHAR(60),
	state VARCHAR(60),
	county VARCHAR(60),
	zip VARCHAR(40),
	latitude DECIMAL(9,6),
	longitude DECIMAL(9,6)
);


SELECT *
FROM patients


CREATE TABLE encounters(
	id VARCHAR(60),
	start DATE,
	stop DATE,
	patient VARCHAR(60),
	organization VARCHAR(60),
	payer VARCHAR(60),
	encounter_class VARCHAR (60),
	code VARCHAR(30),
	description VARCHAR(100),
	base_encounter_cost DECIMAL(12,4),
	total_claim_cost DECIMAL(12,4),
	payer_coverage DECIMAL(12,4),
	reason_code VARCHAR(40),
	reason_description VARCHAR(100)
	);


SELECT *
FROM encounters;


CREATE TABLE procedures_table(
	start DATE,
	stop DATE,
	patient VARCHAR(60),
	encounter VARCHAR(60),
	code VARCHAR(40),
	description VARCHAR(200),
	base_cost DECIMAL(9,1),
	reason_code VARCHAR(40),
	reason_description VARCHAR(100)
	);


SELECT * 
FROM procedures_table;



CREATE TABLE organizations(
	id VARCHAR(60),
	name VARCHAR(60),
	address VARCHAR(60),
	city VARCHAR(60),
	state VARCHAR(60),
	zip VARCHAR(60),
	latitude DECIMAL(9,6),
	longitude DECIMAL(9,6) 
);

SELECT *
FROM organizations;


--Exploratory data analysis--

SELECT * 
FROM patients;


--checking for duplicate information--
SELECT 
	first_name, 
	last_name, 
	birth_date, 
	death_date, 
	COUNT(*)
FROM 
	patients
GROUP BY 
	first_name, 
	last_name, 
	birth_date, 
	death_date
HAVING 
	COUNT(*) >1



--Patients' demography--

SELECT 
	gender, 
	COUNT(gender)
FROM 
	patients
GROUP BY 
	gender;

SELECT 
	ethnicity, 
	COUNT(ethnicity)
FROM 
	patients
GROUP BY 
	ethnicity;

SELECT 
	marital, 
	COUNT(marital)
FROM 
	patients
GROUP BY 
	marital;

--checking for the missing value for patient's marital status--
SELECT *
FROM 
	patients 
WHERE 
	marital IS NULL;


--count of patients by race--	
SELECT 
	race, 
	COUNT(race)
FROM 
	patients
GROUP BY 
	race;

--count of patients by their county--
SELECT 
	county, 
	COUNT(county)
FROM 
	patients
GROUP BY 
	county;


--count of patients by race and gender--	
SELECT 
	race, 
	gender, 
	COUNT(*) AS count
FROM 
	patients
GROUP BY 
	race, 
	gender
ORDER BY 
	race, 
	gender;


	
--creating a view for calculating and categorization of patients' ages--
CREATE VIEW 
	age_cat_view AS
SELECT 
    id, 
	CONCAT(first_name,' ', last_name) AS name,
    prefix,
	birth_date,
	death_date,
	marital,
	gender,
	race,
    CASE 
        WHEN death_date IS NOT NULL THEN 
            DATE_PART('year', age(death_date, birth_date))
        ELSE 
            DATE_PART('year', age(CURRENT_DATE, birth_date))
    END AS age,
	CASE 
		WHEN DATE_PART('year', age(CURRENT_DATE, birth_date)) BETWEEN 0 AND 12 THEN 'Children'
		WHEN DATE_PART('year', age(CURRENT_DATE, birth_date)) BETWEEN 13 AND 19 THEN 'Teenagers'
		WHEN DATE_PART('year', age(CURRENT_DATE, birth_date)) BETWEEN 20 AND 34 THEN 'Young Adults'
		WHEN DATE_PART('year', age(CURRENT_DATE, birth_date)) BETWEEN 35 AND 49 THEN 'Middle-aged Adults'
		WHEN DATE_PART('year', age(CURRENT_DATE, birth_date)) BETWEEN 50 AND 64 THEN 'Older Adults'
		WHEN DATE_PART('year', age(CURRENT_DATE, birth_date)) >= 65 THEN 'Seniors'
	ELSE 'Not Given'
	END AS age_cat
FROM 
    patients;


--This query is for counting the patients in each categories--
SELECT 
	age_cat, 
	COUNT (age_cat)
FROM 
	age_cat_view
GROUP BY 
	age_cat
ORDER BY COUNT 
	(age_cat) DESC;



--count the number of encounters for each class in descending order--
SELECT 
	encounter_class,
	COUNT (*) AS count_of_encounters
FROM 
	encounters
GROUP BY 
	encounter_class
ORDER BY 
	count_of_encounters desc;



--this query is to calculate the number of days each encounter lasted, and the highest days--
CREATE VIEW days_in_hospital AS 
SELECT
	id,
	patient,
	start,	
	stop, 
	DATE_PART('day', age(stop, start)),
	encounter_class,
	description
FROM 
	encounters
ORDER BY 
	DATE_PART desc
LIMIT 20;


--To get the average number of days patients spent in hospital--
SELECT 
	avg(date_part) AS avg_no_of_days
FROM 
	days_in_hospital;

/*This query calculates the amount a patient pays for each encounter. This is done by   
deducting the amount covered by the health insurance from the total cost */
SELECT 
	id,
	patient,
	encounter_class,
	total_claim_cost,
	payer_coverage,
    ROUND((total_claim_cost - payer_coverage),2) AS patients_cost
FROM
	encounters;


/* this is a test code
SELECT	
	payer,
	TO_CHAR(SUM(total_claim_cost),'FM999,999,999.00') AS overall_claim_cost,
	TO_CHAR(SUM(payer_coverage),'FM999,999,999.00') AS overall_payer_coverage,
	TO_CHAR(SUM(total_claim_cost - payer_coverage),'FM999,999,999.00') AS overall_patients_cost
FROM
	encounters
GROUP BY
	payer*/





	
SELECT 
	payer,
(SELECT	
	payer,
	ROUND(SUM(total_claim_cost),2) AS overall_claim_cost,
	ROUND(SUM(payer_coverage),2) AS overall_payer_coverage,
	ROUND(SUM(total_claim_cost - payer_coverage),2) AS overall_patients_cost,
	ROUND(((SUM(payer_coverage) *100)/(SUM(total_claim_cost))),2) AS percentage
FROM
	encounters
GROUP BY
	payer) AS i
FROM encounters as a
LEFT JOIN payers as b
ON payer=b.id;

	

/*This query calculates the percentage of total claim cost
covered by the payers over the years*/
SELECT 
    DATE_PART('year', start),
    payer,
    ROUND((SUM(payer_coverage) / SUM(total_claim_cost)) * 100, 2) AS percentage 
FROM 
    encounters
GROUP BY
    DATE_PART('year', start), payer
ORDER BY
    payer, DATE_PART('year', start);


--This query calculates the total_claim_cost by encounter class--
SELECT
	encounter_class,
	ROUND(SUM(total_claim_cost),2) AS overall_claim_cost
FROM 
	encounters
GROUP BY 
	encounter_class
ORDER BY
	overall_claim_cost desc;

--This join is to see those encounters that are also procedures--
SELECT 
	e.id,
	e.encounter_class,
	p.encounter,
	p.base_cost,
	p.reason_description
FROM 
	encounters AS e
INNER JOIN
	procedures_table AS p
ON 
	e.id=p.encounter


/*Joined the patients, payers, and the encounters table together to display the patient
details, encounter class, cost, payer name, and payer coverage*/
SELECT
	p.prefix,
	CONCAT(first_name,' ' , last_name) AS name,
	e.encounter_class,
	ROUND(base_encounter_cost, 2) AS base_encounter_cost,
	ROUND(total_claim_cost,2) AS total_claim_cost, 
	ROUND(payer_coverage,2)AS payer_coverage,
	payers.name AS payer_name
FROM 
	patients AS p
JOIN 
	encounters AS e
ON 
	p.id = e.patient
JOIN 
	payers
ON
	payers.id = e.payer
ORDER BY 
	name;



/* This is to display the health insurance companies' coverage from 
the lowest to the highest*/
SELECT 
	p.name,
	p.city,
	p.phone,
	SUM(payer_coverage) AS total_payer_coverage
FROM 
	payers AS p
JOIN 
	encounters AS e
ON
	p.id = e.payer
GROUP BY 
	p.name, p.city, p.phone
ORDER BY 
	total_payer_coverage asc;



--To count the number of encounters covered by individual insurance companies--
SELECT 
	e.payer AS payer_id, 
	p.name AS payer_name,
	p.phone AS payer_phone,
	COUNT(payer) AS count_of_encounters_covered  
FROM 
	encounters AS e
JOIN 
	payers AS p
ON 
	e.payer = p.id
WHERE 
	payer_coverage > 0
GROUP BY 
	e.payer, p.name, p.phone
ORDER BY 
	count_of_encounters_covered desc;


--creating a view for late patients--

CREATE VIEW 
	death_view AS 
SELECT id, 
	CONCAT(first_name,' ', last_name) AS name,
	birth_date,
	death_date
FROM
	patients
WHERE 
	death_date IS NOT NULL;


--This query is to check the year with the highest number of deaths--
SELECT 
	DATE_PART('year', death_date), 
	COUNT(DATE_PART('year', death_date)) AS number_of_deaths
FROM 
	death_view
GROUP BY 
	DATE_PART('year', death_date)
ORDER BY 
	number_of_deaths DESC;

--This query is to show the number of yearly encounters--
SELECT 
	DATE_PART('year',start), COUNT(patient)
FROM 
	encounters
GROUP BY 
	DATE_PART('year',start)
ORDER BY 
	COUNT(patient) DESC;


