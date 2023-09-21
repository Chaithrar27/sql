/*Problem Statement 1: 
A company needs to set up 3 new pharmacies, they have come up with an idea that the pharmacy can be set up in cities 
where the pharmacy-to-prescription ratio is the lowest and the number of prescriptions should exceed 100. 
Assist the company to identify those cities where the pharmacy can be set up.*/
WITH P AS (
  SELECT ph.pharmacyID,pr.prescriptionID
  FROM prescription pr LEFT JOIN contain c USING (prescriptionID) JOIN pharmacy ph USING (pharmacyID)
  GROUP BY ph.pharmacyID, pr.prescriptionID
)
SELECT a.city, COUNT(DISTINCT P.prescriptionID) as presciptions,
COUNT(DISTINCT P.pharmacyID) / NULLIF(COUNT(DISTINCT P.prescriptionID), 1) AS pharmacy_to_prescriptions_ratio
FROM P JOIN pharmacy ph USING (pharmacyID) JOIN address a USING (addressID)
GROUP BY a.citys
HAVING COUNT(DISTINCT P.prescriptionID) > 100
ORDER BY pharmacy_to_prescriptions_ratio DESC
LIMIT 3;

/*Problem Statement 2: 
The State of Alabama (AL) is trying to manage its healthcare resources more efficiently. 
For each city in their state, they need to identify the disease for which the maximum number of patients have gone for treatment. 
Assist the state for this purpose.
Note: The state of Alabama is represented as AL in Address Table.*/
with cte as(
select city,diseasename,count(t.patientID) as no_of_patient
from address a
 join pharmacy ph using (addressID)
 join prescription pe using(pharmacyID)
 join treatment t using ( treatmentID)
 join  disease d using (diseaseID)
where state='AL' group by city,diseasename )
SELECT city,diseasename,no_of_patient from (SELECT city,diseasename,no_of_patient,
RANK() OVER (PARTITION BY city ORDER BY no_of_patient DESC) As rank1 from cte) as dervived_cte
WHERE rank1 = 1;

# need to check which is correct

with cte as
(select 
	a.city
	,d.diseaseName
	-- ,pn.personID
	,count(p.patientID) as dis_cnt
	,rank() over(partition by a.city order by count(p.patientID) desc) as rnk
from Disease d 
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
where a.state = 'AL'
group by a.city, d.diseaseName)
select 
	city
	,diseaseName
	,dis_cnt
from cte
where rnk = 1
;

/*Problem Statement 3: The healthcare department needs a report about insurance plans. 
The report is required to include the insurance plan, which was claimed the most and least for each disease.  
Assist to create such a report.*/
with cte as(
select diseaseName,count(claimID),planName 
,ROW_NUMBER() over(partition by diseaseName order by count(claimID) desc) as max_rank
,ROW_NUMBER() over(partition by diseaseName order by count(claimID) ) as min_rank
from disease 
join treatment using (diseaseID)
join claim using (claimID)
join insuranceplan using (UIN) 
group by diseaseName,planName )
select diseaseName,c1.planName as max_plan,c2.planName as min_plan  from cte c1 join cte c2
using (diseaseName)
 where c1.max_rank=1 and c2.min_rank=1 ;
 
 /*Problem Statement 4: The Healthcare department wants to know which disease is most likely to infect multiple people in the same household. 
 For each disease find the number of households that has more than one patient with the same disease. 
Note: 2 people are considered to be in the same household if they have the same address. */

with cte as
(select 
	d.diseaseName
	,a.address1
	,count(p.patientID) as total
from Disease d 
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
group by d.diseaseName ,a.addressID
having count(p.patientID) > 1)
select 
	diseaseName
	,COUNT(address1) as total_count
from cte
group by diseaseName
order by total_count desc;

/*Problem Statement 5:  An Insurance company wants a state wise report of the treatments to claim ratio 
between 1st April 2021 and 31st March 2022 (days both included). Assist them to create such a report.*/

with cte as
(select a.state,count(t.treatmentID) as treatment_cnt,count(c.claimID) as claim_cnt
from Treatment t
join Patient p on p.patientID = t.patientID
join Person pers on pers.personID = p.patientID
join Address a on a.addressID = pers.addressID
left join Claim c on c.claimID = t.claimID
where t.date between '2021-04-01' and '2022-03-21'
group by a.state
)
select state,treatment_cnt,claim_cnt,(treatment_cnt/claim_cnt) as treatment_to_claim_ratio
from cte;

#Sheet 3#
/*Problem Statement 1:  
Some complaints have been lodged by patients that they have been prescribed hospital-exclusive medicine 
that they can’t find elsewhere and facing problems due to that. Joshua, from the pharmacy management, 
wants to get a report of which pharmacies have prescribed hospital-exclusive medicines the most in the years 2021 and 2022. 
Assist Joshua to generate the report so that the pharmacies who prescribe hospital-exclusive medicine more often are advised 
to avoid such practice if possible.  */
select count(p.pharmacyID) as Count_exclusive,p.pharmacyID, p.pharmacyname
from pharmacy p
join prescription pt using(pharmacyid)
join treatment t using(treatmentID)
join contain c on pt.prescriptionID=c.prescriptionID
join medicine m using(medicineID)
join keep k using(medicineId)
where year(t.date) in (2022,2021) AND m.hospitalExclusive='S' 
group by p.pharmacyname,p.pharmacyID
order by p.pharmacyname;

/*Problem Statement 2: Insurance companies want to assess the performance of their insurance plans. 
Generate a report that shows each insurance plan, the company that issues the plan, and the number of treatments the plan was claimed for.*/
select ip.planname, ic.companyname, count(t.treatmentid) as no_of_treatments_claimed
from insurancecompany ic join insuranceplan ip using(companyid)
join claim c using(uin)
left join treatment t using(claimid)
group by ip.planname, ic.companyname;

/*Problem Statement 3: Insurance companies want to assess the performance of their insurance plans. 
Generate a report that shows each insurance company's name with their most and least claimed insurance plans.*/
with cte as(
select companyname,count(claimID),planName 
,ROW_NUMBER() over(partition by companyname order by count(claimID) desc) as max_rank
,ROW_NUMBER() over(partition by companyname order by count(claimID) ) as min_rank
from insurancecompany 
join insuranceplan using (companyID)
join claim using (UIN)
join treatment using (claimID) 
group by companyname,planName )
select companyname,c1.planName as max_plan,c2.planName as min_plan  from cte c1 join cte c2
using (companyname)
 where c1.max_rank=1 and c2.min_rank=1 ;
 
 
/*Problem Statement 4:  The healthcare department wants a state-wise health report to assess which state requires more attention in the healthcare 
sector. Generate a report for them that shows the state name, number of registered people in the state, number of registered patients in the state, 
and the people-to-patient ratio. sort the data by people-to-patient ratio. */

select a.state, count(p.personid) as Ppl_count, count(pat.patientid) as patient_count,
(count(p.personid) / count(pat.patientid)) as people_to_patient_ratio
from address a join person p using(addressid)
left join patient pat on pat.patientid=p.personid
group by a.state
order by people_to_patient_ratio;

/*Problem Statement 5:  
Jhonny, from the finance department of Arizona(AZ), 
has requested a report that lists the total quantity of medicine each pharmacy in his state has 
prescribed that falls under Tax criteria I for treatments that took place in 2021. Assist Jhonny in generating the report. */
select s.pharmacyName ,sum(c.quantity) as med_cnt
from Medicine m
join Contain c on c.medicineID = m.medicineID
join Prescription p on p.prescriptionID = c.prescriptionID
join Pharmacy s on s.pharmacyID = p.pharmacyID
join Address a on a.addressID = s.addressID
join Treatment t on t.treatmentID = p.treatmentID
where m.taxCriteria = 'I'
and year(t.date) = 2021
and a.state = 'AZ'
group by s.pharmacyName;

#Sheet 4#
/*Problem Statement 1: 
“HealthDirect” pharmacy finds it difficult to deal with the product type of medicine being displayed in numerical form, 
they want the product type in words. Also, they want to filter the medicines based on tax criteria. 
Display only the medicines of product categories 1, 2, and 3 for medicines that come under tax category I 
and medicines of product categories 4, 5, and 6 for medicines that come under tax category II.
Write a SQL query to solve this problem.
ProductType numerical form and ProductType in words are given by
1 - Generic, 
2 - Patent, 
*/
select productname, producttype,taxcriteria,
case producttype 
WHEN 1 THEN 'Generic'
WHEN 2 THEN 'Patent'
WHEN 3 THEN 'Reference'
WHEN 4 THEN 'Similar'
WHEN 5 THEN 'New'
WHEN 6 THEN 'Specific'
WHEN 7 THEN 'Biological'
WHEN 8 THEN 'Dinamized'
ELSE 'Unknown'
END as productCategory
from medicine
where (taxcriteria ='I' and producttype in (1,2,3)) or (taxcriteria ='II' and producttype in (4,5,6));

/*Problem Statement 2:  
'Ally Scripts' pharmacy company wants to find out the quantity of medicine prescribed in each of its prescriptions.
Write a query that finds the sum of the quantity of all the medicines in a prescription and if the total quantity of medicine is less than 20 tag it as “low quantity”. If the quantity of medicine is from 20 to 49 (both numbers including) tag it as “medium quantity“ and if the quantity is more than equal to 50 then tag it as “high quantity”.
Show the prescription Id, the Total Quantity of all the medicines in that prescription, and the Quantity tag for all the prescriptions issued by 'Ally Scripts'.
3 rows from the resultant table may be as follows:
prescriptionID	totalQuantity	Tag
1147561399		43			Medium Quantity
1222719376		71			High Quantity
1408276190		48			Medium Quantity
*/
select p.prescriptionID,sum(c.quantity) as med_cnt
,case 
	when sum(c.quantity) < 3 then 'low'
	when sum(c.quantity) < 5 then 'medium'
	else 'high'
	end as category
from Prescription p 
join Contain c on c.prescriptionID = p.prescriptionID
group by p.prescriptionID;

/*Problem Statement 3: 
In the Inventory of a pharmacy 'Spot Rx' the quantity of medicine is considered ‘HIGH QUANTITY’ when the quantity exceeds 7500 and ‘LOW QUANTITY’ 
when the quantity falls short of 1000. The discount is considered “HIGH” if the discount rate on a product is 30% or higher, 
and the discount is considered “NONE” when the discount rate on a product is 0%.
 'Spot Rx' needs to find all the Low quantity products with high discounts 
 and all the high-quantity products with no discount so they can adjust the discount rate according to the demand. 
Write a query for the pharmacy listing all the necessary details relevant to the given requirement.
Hint: Inventory is reflected in the Keep table.*/
with cte as
(select p.pharmacyName,m.productName,k.quantity
	,case
		when k.quantity < 1000 then 'low'
		when k.quantity <= 7500 then 'medium'
		else 'high'
	end as qnt_cat
	,k.discount
	,case
		when k.discount = 0 then 'none'
		when k.discount < 30 then 'med'
		else 'high'
	end as discount_cat
from Keep k
join Pharmacy p on p.pharmacyID = k.pharmacyID
join Medicine m on m.medicineID = k.medicineID
where pharmacyName = 'Spot Rx'
)
select productName,qnt_cat,discount_cat
from cte
where (qnt_cat = 'low' and discount_cat='high')
or (qnt_cat = 'high' and discount_cat='none');

/*Problem Statement 4: 
Mack, From HealthDirect Pharmacy, wants to get a list of all the affordable and costly, hospital-exclusive medicines in the database. 
Where affordable medicines are the medicines that have a maximum price of less than 50% of the avg maximum price of all the medicines 
in the database, and costly medicines are the medicines that have a maximum price of more than double the avg maximum price of 
all the medicines in the database.  Mack wants clear text next to each medicine name to be displayed that identifies the medicine 
as affordable or costly. The medicines that do not fall under either of the two categories need not be displayed.
Write a SQL query for Mack for this requirement.*/

with cte as
(select productName,maxPrice, case
		when maxPrice < 0.5 * avg(maxPrice) over() then 'low'
		when maxPrice > 2 * avg(maxPrice) over() then 'high'
		else NULL
	end as category
from Medicine)
select productName,maxPrice,category
from cte
where category is not Null;

/*Problem Statement 5:  
The healthcare department wants to categorize the patients into the following category.
YoungMale: Born on or after 1st Jan  2005  and gender male.
YoungFemale: Born on or after 1st Jan  2005  and gender female.
AdultMale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender male.
AdultFemale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender female.
MidAgeMale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender male.
MidAgeFemale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender female.
ElderMale: Born before 1st Jan 1970, and gender male.
ElderFemale: Born before 1st Jan 1970, and gender female.

Write a SQL query to list all the patient name, gender, dob, and their category.*/


select p.personName,p.gender,pt.dob,  CASE
		WHEN pt.dob >= '2005-01-01' AND gender = 'Male' THEN 'YoungMale'
		WHEN pt.dob >= '2005-01-01' AND gender = 'Female' THEN 'YoungFemale'
		WHEN pt.dob < '2005-01-01' AND pt.dob >= '1985-01-01' AND gender = 'Male' THEN 'AdultMale'
		WHEN pt.dob < '2005-01-01' AND pt.dob >= '1985-01-01' AND gender = 'Female' THEN 'AdultFemale'
		WHEN pt.dob < '1985-01-01' AND pt.dob >= '1970-01-01' AND gender = 'Male' THEN 'MidAgeMale'
		WHEN pt.dob < '1985-01-01' AND pt.dob >= '1970-01-01' AND gender = 'Female' THEN 'MidAgeFemale'
		WHEN pt.dob < '1970-01-01' AND gender = 'Male' THEN 'ElderMale'
		WHEN pt.dob < '1970-01-01' AND gender = 'Female' THEN 'ElderFemale'
		ELSE 'Unknown'
	END as Gender
from Patient pt
join Person p on p.personID = pt.patientID;