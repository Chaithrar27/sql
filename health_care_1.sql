/*Problem Statement 1:  Jimmy, from the healthcare department, has requested a report that shows how the number of treatments each age category of patients has gone through in the year 2022. 
The age category is as follows, Children (00-14 years), Youth (15-24 years), Adults (25-64 years), and Seniors (65 years and over).
Assist Jimmy in generating the report. */
select count(treatmentID),
case
when
floor(abs(datediff(dob,date))/365)>=0 and floor(abs(datediff(dob,date))/365)<=14
then 'Children'
when
floor(abs(datediff(dob,date))/365)>=15 and floor(abs(datediff(dob,date))/365)<=24
then 'Youth'
when
floor(abs(datediff(dob,date))/365)>=25 and floor(abs(datediff(dob,date))/365)<=64
then 'Adult'
else 'Senior'
end as category
from treatment join patient using(patientid) where year(date)=2022 group by category;

/*

Problem Statement 2:  Jimmy, from the healthcare department, wants to know which disease is infecting people of which gender more often.
Assist Jimmy with this purpose by generating a report that shows for each disease the male-to-female ratio. Sort the data in a way that is helpful for Jimmy.*/

 select diseasename,male,female,male/female as male_to_female_ratio from 
 (select count(gender) as female,diseaseid from person join treatment on person.personid=treatment.patientid  
 where gender='female' group by diseaseid) as f join (select count(gender) as male,diseaseid 
 from person join treatment on person.personid=treatment.patientid  
 where gender='male' group by diseaseid) as m using(diseaseid) join disease using(diseaseid);


/*

Problem Statement 3: Jacob, from insurance management, has noticed that insurance claims are not made for all the treatments. He also wants to figure out if the gender of the patient has any impact on the insurance claim. Assist Jacob in this situation by generating a report that finds for each gender the number of treatments, number of claims, and treatment-to-claim ratio. And notice if there is a significant difference between the treatment-to-claim ratio of male and female patients.*/

 select 
	gender,ct,cc,ct/cc as treatment_to_claim_ratio 
from 
	(select 
		count(treatmentid) as ct,gender 
	from treatment 
	join person on treatment.patientid=person.personid 
	group by gender) 
as t 
join
	(select 
		gender,
		count(claimid) as cc 
	from person 
	join treatment on treatment.patientid=person.personid 
	join claim using(claimid) 
	group by gender) 
as c 
using(gender) ;


/*

Problem Statement 4: The Healthcare department wants a report about the inventory of pharmacies. Generate a report on their behalf that shows how many units of medicine each pharmacy has in their inventory, the total maximum retail price of those medicines, and the total price of all the medicines after discount. 
Note: discount field in keep signifies the percentage of discount on the maximum price.*/

select
	p.pharmacyName
	,sum(k.quantity) as medicin_cnt
	,sum(k.quantity * m.maxPrice) as total_price
	,sum( (k.quantity * m.maxPrice) * (100 - k.discount)/100.0) as total_price_after_discount
from Medicine m
join Keep k  on k.medicineID = m.medicineID
join Pharmacy p on p.pharmacyID = k.pharmacyID
group by p.pharmacyName;


/*

Problem Statement 5:  The healthcare department suspects that some pharmacies prescribe more medicines than others in a single prescription, for them, generate a report that finds for each pharmacy the maximum, minimum and average number of medicines prescribed in their prescriptions. 

*/
with cte as
(select
	s.pharmacyName
	,p.prescriptionID
	,sum(c.quantity) as med_cnt_per_pres
from Pharmacy s
join Prescription p on p.pharmacyID = s.pharmacyID
join Contain c on c.prescriptionID = p.prescriptionID
group by s.pharmacyName, p.prescriptionID
)
select
	pharmacyName
	,avg(med_cnt_per_pres) as avg_med_per_pres
	,max(med_cnt_per_pres) as max_med_per_pres
	,min(med_cnt_per_pres) as min_med_per_pres
from cte
group by pharmacyName;