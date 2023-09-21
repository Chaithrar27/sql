/*Problem Statement 1: 
Brian, the healthcare department, has requested for a report that shows for each state how many people underwent treatment for 
the disease “Autism”.  He expects the report to show the data for each state as well as each gender and for each state and 
gender combination. Prepare a report for Brian for his requirement.*/


select state,gender,count(patientid) as num from disease 
join treatment using(diseaseid) 
join person on person.personid=treatment.patientid
join address using(addressid)
where diseasename='Autism'
group by state,gender order by state ;

/*
Problem Statement 2:  
Insurance companies want to evaluate the performance of different insurance plans they offer. 
Generate a report that shows each insurance plan, the company that issues the plan, and the number of treatments
 the plan was claimed for. The report would be more relevant if the data compares the performance for different years(2020, 2021 and 2022) and if the report also includes the total number of claims in the different years, as well as the total number of claims for each plan in all 3 years combined.*/

-- select count(treatmentid) as num ,claimid,companyName,planName  from treatment join claim using(claimid) join insuranceplan using(uin)
-- join insurancecompany using(companyid) group by claimid order by num desc;

SELECT
    ip.planName,
    ic.companyName,
    YEAR(t.date) AS year,
    COUNT(DISTINCT c.claimID) AS claim_cnt,
    COUNT(t.treatmentID) AS treatment_cnt
FROM InsuranceCompany ic
JOIN InsurancePlan ip ON ip.companyID = ic.companyID
JOIN Claim c ON c.uin = ip.uin
JOIN Treatment t ON t.claimID = c.claimID
GROUP BY YEAR(t.date), ip.planName, ic.companyName
ORDER BY ip.planName, ic.companyName, YEAR(t.date);



/*
Problem Statement 3:  
Sarah, from the healthcare department, is trying to understand if some diseases are spreading in a particular region. 
Assist Sarah by creating a report which shows each state the number of the most and least treated diseases by the patients 
of that state in the year 2022. It would be helpful for Sarah if the aggregation for the different combinations is found as well.
 Assist Sarah to create this report. 
*/
SELECT 
    state,
    diseaseName,
    MAX(treatment_cnt) AS max_treatment_cnt,
    MIN(treatment_cnt) AS min_treatment_cnt
FROM (
    SELECT
        a.state,
        d.diseaseName,
        COUNT(t.treatmentID) AS treatment_cnt,
        ROW_NUMBER() OVER (PARTITION BY a.state ORDER BY COUNT(t.treatmentID) DESC) AS max_rnk,
        ROW_NUMBER() OVER (PARTITION BY a.state ORDER BY COUNT(t.treatmentID) ASC) AS min_rnk
    FROM Disease d
    JOIN Treatment t ON t.diseaseID = d.diseaseID
    JOIN Patient p ON p.patientID = t.patientID
    JOIN Person pn ON pn.personID = p.patientID
    JOIN Address a ON a.addressID = pn.addressID
    WHERE YEAR(t.date) = 2022
    GROUP BY a.state, d.diseaseName
) AS subquery
GROUP BY state, diseaseName WITH ROLLUP;



/*
Problem Statement 4: 
Jackson has requested a detailed pharmacy report that shows each pharmacy name, and how many prescriptions they have prescribed for each disease in the year 2022, along with this Jackson also needs to view how many prescriptions were prescribed by each pharmacy, and the total number prescriptions were prescribed for each disease.
Assist Jackson to create this report. */
SELECT
    s.pharmacyName,
    d.diseaseName,
    COUNT(p.prescriptionID) AS pres_cnt
FROM Pharmacy s
JOIN Prescription p ON p.pharmacyID = s.pharmacyID
JOIN Treatment t ON t.treatmentID = p.treatmentID
JOIN Disease d ON d.diseaseID = t.diseaseID
WHERE YEAR(t.date) = 2021
GROUP BY s.pharmacyName, d.diseaseName
ORDER BY s.pharmacyName, d.diseaseName;


/*
Problem Statement 5:  
Praveen has requested for a report that finds for every disease how many males and females underwent treatment for each in the year 2022. It would be helpful for Praveen if the aggregation for the different combinations is found as well.
Assist Praveen to create this report. 
*/

SELECT
    d.diseaseName,
    pn.gender,
    COUNT(t.treatmentID) AS treatment_cnt
FROM Disease d
JOIN Treatment t ON t.diseaseID = d.diseaseID
JOIN Patient p ON p.patientID = t.patientID
JOIN Person pn ON pn.personID = p.patientID
WHERE YEAR(t.date) = 2022
GROUP BY d.diseaseName, pn.gender WITH ROLLUP;
