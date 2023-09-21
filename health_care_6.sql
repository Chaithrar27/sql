/*
Problem Statement 1: 
The healthcare department wants a pharmacy report on the percentage of hospital-exclusive medicine prescribed in the year 2022.
Assist the healthcare department to view for each pharmacy, the pharmacy id, pharmacy name, total quantity of medicine prescribed in 2022, total quantity of hospital-exclusive medicine prescribed by the pharmacy in 2022, and the percentage of hospital-exclusive medicine to the total medicine prescribed in 2022.
Order the result in descending order of the percentage found. 
*/

select 
	s.pharmacyID
	,s.pharmacyName
	,sum(c.quantity) as med_cnt
	,sum( if(m.hospitalExclusive = 'S', c.quantity, 0) ) as hosp_exc_cnt
	,concat(sum( if(m.hospitalExclusive = 'S', c.quantity, 0) ) / sum(c.quantity)*100 ,'%')as med_exc_norm_ration
from Pharmacy s
join Prescription p on s.pharmacyID = p.pharmacyID
join Treatment t on t.treatmentID = p.treatmentID
join Contain c on c.prescriptionID = p.prescriptionID
join Medicine m on m.medicineID = c.medicineID
where year(t.date) = 2021
group by s.pharmacyID,s.pharmacyName;


/*
Problem Statement 2:  
Sarah, from the healthcare department, has noticed many people do not claim insurance for their treatment. She has requested a state-wise report of the percentage of treatments that took place without claiming insurance. Assist Sarah by creating a report as per her requirement.
*/

select state,total_tre,total_cid,100-(total_cid*100/total_tre) as percentage from
(select state,count(treatmentId) as total_tre from treatment join person on
 treatment.patientid=person.personid join address using(addressid) group by state 
 order by total_tre desc) as d join (select state,count(claimid) as total_cid from 
 treatment join claim using(claimid) join person on treatment.patientid=person.personid 
join address using(addressid) group by state) as c using(state) order by percentage;





/*
Problem Statement 3:  
Sarah, from the healthcare department, is trying to understand if some diseases are spreading in a particular region. Assist Sarah by creating a report which shows for each state, the number of the most and least treated diseases by the patients of that state in the year 2022. 
*/

with cte as
(select 
	a.state
	,d.diseaseName
	,count(p.patientID) as dis_cnt
	,rank() over(partition by a.state order by count(p.patientID) desc) as max_rnk
	,rank() over(partition by a.state order by count(p.patientID) ) as min_rnk
from Disease d 
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
where year(t.date) = 2022
group by a.state, d.diseaseName)
select 
	c1.state
	,c1.diseaseName as most_disease
	,c2.diseaseName as least_disease
from cte c1
join cte c2 on c1.state = c2.state
where c1.max_rnk = 1 and c2.min_rnk = 1;




/*
Problem Statement 4: 
Manish, from the healthcare department, wants to know how many registered people are registered as patients as well, in each city. Generate a report that shows each city that has 10 or more registered people belonging to it and the number of patients from that city as well as the percentage of the patient with respect to the registered people.
*/



select
	a.city
	,count(pn.personID) as pers_cnt
	,count(p.patientID) as pat_cnt
	,count(p.patientID) * 100.0 / count(pn.personID) as pat_per_ration
from Person pn
left join Patient p on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
group by a.city
having count(pn.personID) > 10;


/*
Problem Statement 5:  
It is suspected by healthcare research department that the substance “ranitidine” might b
e causing some side effects. Find the top 3 companies using the substance in their medicine so that they can be informed about it.
*/

select 
	p.pharmacyName
	,sum(k.quantity) as med_cnt
from Medicine m
join Keep k on k.medicineID = m.medicineID
join Pharmacy p on p.pharmacyID = k.pharmacyID
where m.substanceName like '%ranitidin%'
group by p.pharmacyName
order by med_cnt desc limit 3;
