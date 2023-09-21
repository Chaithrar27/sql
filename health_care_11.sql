-- Problem Statement 1:
-- Patients are complaining that it is often difficult to find some medicines. They move from pharmacy to pharmacy to get the required medicine. A system is required that finds the pharmacies and their contact number that have the required medicine in their inventory. So that the patients can contact the pharmacy and order the required medicine.
-- Create a stored procedure that can fix the issue.

DROP PROCEDURE IF EXISTS get_medicine_prod_details;

DELIMITER //

CREATE PROCEDURE get_medicine_prod_details(IN productName VARCHAR(50))
BEGIN
    SELECT
        p.pharmacyName,
        p.phone,
        m.productName,
        k.quantity
    FROM Pharmacy p
    JOIN Keep k ON k.pharmacyID = p.pharmacyID
    JOIN Medicine m ON m.medicineID = k.medicineID
    WHERE m.productName = productName;
END;
//

DELIMITER ;
CALL get_medicine_prod_details('MEGASTROL');


-- Problem Statement 2:
-- The pharmacies are trying to estimate the average cost of all the prescribed medicines per prescription, for all the prescriptions they have prescribed in a particular year. Create a stored function that will return the required value when the pharmacyID and year are passed to it. Test the function with multiple values.



DELIMITER //

CREATE PROCEDURE get_avg_med_per_prescription(IN year INT, IN pharmacyID INT)
BEGIN
    WITH cte AS (
        SELECT
            p.prescriptionID,
            SUM(c.quantity * m.maxPrice) AS total_cost_per_prescription
        FROM Prescription p
        JOIN Treatment t ON t.treatmentID = p.treatmentID
        JOIN Pharmacy s ON s.pharmacyID = p.pharmacyID
        JOIN Contain c ON c.prescriptionID = p.prescriptionID
        JOIN Medicine m ON m.medicineID = c.medicineID
        WHERE YEAR(t.date) = year
        AND s.pharmacyID = pharmacyID
        GROUP BY p.prescriptionID
    )
    SELECT 
        AVG(total_cost_per_prescription) AS avg_med_per_prescription
    FROM cte;
END;
//

DELIMITER ;
CALL get_avg_med_per_prescription(2022, 7448);


-- Problem Statement 3:
-- The healthcare department has requested an application that finds out the disease that was spread the most in a state for a given year. So that they can use the information to compare the historical data and gain some insight.
-- Create a stored function that returns the name of the disease for which the patients from a particular state had the most number of treatments for a particular year. Provided the name of the state and year is passed to the stored function.




DELIMITER //

CREATE PROCEDURE get_most_disease_per_state(IN state VARCHAR(4), IN year INT)
BEGIN
    SELECT 
        d.diseaseName,
        COUNT(t.treatmentID) AS treatment_cnt
    FROM Disease d
    JOIN Treatment t ON t.diseaseID = d.diseaseID
    JOIN Patient p ON p.patientID = t.patientID
    JOIN Person pn ON pn.personID = p.patientID
    JOIN Address a ON a.addressID = pn.addressID
    WHERE YEAR(t.date) = year
    AND a.state = state
    GROUP BY d.diseaseName
    ORDER BY treatment_cnt DESC
    LIMIT 1;
END;
//

DELIMITER ;
CALL get_most_disease_per_state('CA', 2021);


-- Problem Statement 4:
-- The representative of the pharma union, Aubrey, has requested a system that she can use to find how many people in a specific city have been treated for a specific disease in a specific year.
-- Create a stored function for this purpose.



DELIMITER //

CREATE PROCEDURE get_tratment_cnt_per_disease_year_city(IN city VARCHAR(20), IN diseaseName VARCHAR(20), IN year INT)
BEGIN
    SELECT
        COUNT(t.treatmentID) AS treatment_cnt
    FROM Disease d
    JOIN Treatment t ON t.diseaseID = d.diseaseID
    JOIN Patient p ON p.patientID = t.patientID
    JOIN Person pn ON pn.personID = p.patientID
    JOIN Address a ON a.addressID = pn.addressID
    WHERE a.city = city
    AND d.diseaseName = diseaseName
    AND YEAR(t.date) = year;
END;
//

DELIMITER ;

CALL get_tratment_cnt_per_disease_year_city('Anchorage', 'Autism', 2019);



-- Problem Statement 5:
-- The representative of the pharma union, Aubrey, is trying to audit different aspects of the pharmacies. She has requested a system that can be used to find the average balance for claims submitted by a specific insurance company in the year 2022. 
-- Create a stored function that can be used in the requested application. 


DELIMITER //

CREATE PROCEDURE get_avg_balance_per_year_company(IN companyName VARCHAR(100), IN year INT)
BEGIN
    SELECT
        AVG(c.balance) AS avg_balance
    FROM InsuranceCompany ic
    JOIN InsurancePlan ip ON ic.companyID = ip.companyID
    JOIN Claim c ON c.uin = ip.uin
    JOIN Treatment t ON t.claimID = c.claimID
    WHERE YEAR(t.date) = year
    AND ic.companyName = companyName;
END;
//

DELIMITER ;
CALL get_avg_balance_per_year_company('Kotak Mahindra General Insurance Co. Ltd.', 2020);
