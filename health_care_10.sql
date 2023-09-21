-- Problem Statement 1:
-- The healthcare department has requested a system to analyze the performance of insurance companies and their plan.
-- For this purpose, create a stored procedure that returns the performance of different insurance plans of an insurance company. When passed the insurance company ID the procedure should generate and return all the insurance plan names the provided company issues, the number of treatments the plan was claimed for, and the name of the disease the plan was claimed for the most. The plans which are claimed more are expected to appear above the plans that are claimed less.

drop procedure if exists plan_perf_report;
create procedure plan_perf_report(companyID int)
begin
	with cte as
	(select
		ip.planName
		,ic.companyName
		,d.diseaseName
		,count(d.diseaseName) as dis_cnt
		,rank() over(partition by ip.planName order by count(d.diseaseName) desc) as rnk
	from InsurancePlan ip 
	join InsuranceCompany ic on ic.companyID = ip.companyID
	join Claim c on c.uin = ip.uin
	join Treatment t on t.claimID = c.claimID
	join Disease d on d.diseaseID = t.diseaseID
	where ic.companyID = @companyID
	group by ip.planName, ic.companyName, d.diseaseName)
	,cte1 as
	(select
		planName
		,companyName
		,diseaseName
	from cte
	where rnk = 1)
	,cte2 as
	(select 
		planName
		,companyName
		,sum(dis_cnt) as claim_cnt
	from cte
	group by planName, companyName)
	select distinct
		cte1.planName
		,cte1.companyName
		,diseaseName as highest_claimed_disease
		,claim_cnt
	from cte1
	join cte2 on cte1.planName = cte2.planName
	order by claim_cnt desc;
end //
delimiter ;

call plan_perf_report (1118);


-- Problem Statement 2:
-- It was reported by some unverified sources that some pharmacies are more popular for certain diseases. The healthcare department wants to check the validity of this report.
-- Create a stored procedure that takes a disease name as a parameter and would return the top 3 pharmacies the patients are preferring for the treatment of that disease in 2021 as well as for 2022.
-- Check if there are common pharmacies in the top 3 list for a disease, in the years 2021 and the year 2022.
-- Call the stored procedure by passing the values “Asthma” and “Psoriasis” as disease names and draw a conclusion from the result.

drop procedure get_disease_phar_report;
delimiter //
create procedure get_disease_phar_report(diseaseName varchar(50))

begin
	with cte as
	(select 
		s.pharmacyName
		,year(t.date) as year
		,count(s.pharmacyID) as pharm_cnt
		,row_number() over(partition by year(t.date) order by count(s.pharmacyID)) as min_rnk
		,row_number() over(partition by year(t.date) order by count(s.pharmacyID) desc) as max_rnk
	from Disease d
	join Treatment t on t.diseaseID = d.diseaseID
	join Prescription p on p.treatmentID = t.treatmentID
	join Pharmacy s on s.pharmacyID = p.pharmacyID
	where d.diseaseName = @diseaseName
	and year(t.date) in (2021, 2022)
	group by s.pharmacyName, year(t.date))
	select 
		c1.pharmacyName as '2021_pharm'
		,c1.pharm_cnt
		,c2.pharmacyName as '2022_pharm'
		,c2.pharm_cnt
	from cte c1
	join cte c2 on c1.max_rnk = c2.max_rnk 
	and (c1.max_rnk <= 3 and c2.max_rnk <= 3) 
	and (c1.year = 2021 and c2.year = 2022);
end //
delimiter ;
call get_disease_phar_report ('Asthma');
call get_disease_phar_report ('Psoriasis');



-- Problem Statement 3:
-- Jacob, as a business strategist, wants to figure out if a state is appropriate for setting up an insurance company or not.
-- Write a stored procedure that finds the num_patients, num_insurance_companies, and insurance_patient_ratio, the stored procedure should also find the avg_insurance_patient_ratio and if the insurance_patient_ratio of the given state is less than the avg_insurance_patient_ratio then it Recommendation section can have the value “Recommended” otherwise the value can be “Not Recommended”.




-- Description of the terms used:
-- num_patients: number of registered patients in the given state
-- num_insurance_companies:  The number of registered insurance companies in the given state
-- insurance_patient_ratio: The ratio of registered patients and the number of insurance companies in the given state
-- avg_insurance_patient_ratio: The average of the ratio of registered patients and the number of insurance for all the states.

delimiter //
CREATE PROCEDURE get_insurance_state_report()
BEGIN
    WITH cte AS (
        SELECT 
            a.state,
            COUNT(ic.companyID) AS company_cnt,
            COUNT(p.patientID) AS patient_cnt,
            IF(COUNT(ic.companyID) > 0, COUNT(p.patientID) * 1.0 / COUNT(ic.companyID), 0) AS patient_comp_ratio,
            AVG(IF(COUNT(ic.companyID) > 0, COUNT(p.patientID) * 1.0 / COUNT(ic.companyID), 0)) OVER() AS avg_ratio
        FROM Address a
        LEFT JOIN InsuranceCompany ic ON ic.addressID = a.addressID
        LEFT JOIN Person pn ON pn.addressID = a.addressID
        LEFT JOIN Patient p ON p.patientID = pn.personID
        GROUP BY a.state
    )
    SELECT 
        state,
        company_cnt,
        patient_cnt,
        patient_comp_ratio,
        avg_ratio,
        CASE
            WHEN patient_comp_ratio < avg_ratio THEN 'Recommended'
            ELSE 'Not Recommended'
        END AS status
    FROM cte ;
END //
DELIMITER ;

CALL get_insurance_state_report();



-- Problem Statement 4:
-- Currently, the data from every state is not in the database, The management has decided to add the data from other states and cities as well. It is felt by the management that it would be helpful if the date and time were to be stored whenever new city or state data is inserted.
-- The management has sent a requirement to create a PlacesAdded table if it doesn’t already exist, that has four attributes. placeID, placeName, placeType, and timeAdded.
-- Description
-- placeID: This is the primary key, it should be auto-incremented starting from 1
-- placeName: This is the name of the place which is added for the first time
-- placeType: This is the type of place that is added for the first time. The value can either be ‘city’ or ‘state’
-- timeAdded: This is the date and time when the new place is added

-- You have been given the responsibility to create a system that satisfies the requirements of the management. Whenever some data is inserted in the Address table that has a new city or state name, the PlacesAdded table should be updated with relevant data. 

CREATE TABLE PlacesAdded(
    placeID INT AUTO_INCREMENT PRIMARY KEY,
    placeName VARCHAR(40),
    placeType VARCHAR(10),
    timeAdded DATETIME
);

DELIMITER //

CREATE TRIGGER PlacesAddedTgr
AFTER INSERT ON Address
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(city) FROM Address WHERE city = NEW.city) = 1 THEN
        INSERT INTO PlacesAdded (placeName, placeType, timeAdded)
        VALUES (NEW.city, 'city', NOW());
    END IF;
    
    IF (SELECT COUNT(state) FROM Address WHERE state = NEW.state) = 1 THEN
        INSERT INTO PlacesAdded (placeName, placeType, timeAdded)
        VALUES (NEW.state, 'state', NOW());
    END IF;
END;
//

DELIMITER ;





-- Problem Statement 5:
-- Some pharmacies suspect there is some discrepancy in their inventory management. The quantity in the ‘Keep’ is updated regularly and there is no record of it. They have requested to create a system that keeps track of all the transactions whenever the quantity of the inventory is updated.
-- You have been given the responsibility to create a system that automatically updates a Keep_Log table which has  the following fields:
-- id: It is a unique field that starts with 1 and increments by 1 for each new entry
-- medicineID: It is the medicineID of the medicine for which the quantity is updated.
-- quantity: The quantity of medicine which is to be added. If the quantity is reduced then the number can be negative.
-- For example:  If in Keep the old quantity was 700 and the new quantity to be updated is 1000, then in Keep_Log the quantity should be 300.
-- Example 2: If in Keep the old quantity was 700 and the new quantity to be updated is 100, then in Keep_Log the quantity should be -600.

CREATE TABLE keep_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quantity INT
);

DELIMITER //

CREATE TRIGGER KeepLogTgr
AFTER UPDATE ON Keep
FOR EACH ROW
BEGIN
    IF NEW.quantity <> OLD.quantity THEN
        INSERT INTO keep_log (quantity)
        VALUES (NEW.quantity - OLD.quantity);
    END IF;
END;
//

DELIMITER ;
