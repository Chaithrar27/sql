/*Problem Statement 1:  Some complaints have been lodged by patients that they have been prescribed hospital-exclusive medicine that they can’t find elsewhere and facing problems due to that. Joshua, from the pharmacy management, wants to get a report of which pharmacies have prescribed hospital-exclusive medicines the most in the years 2021 and 2022. Assist Joshua to generate the report so that the pharmacies who prescribe hospital-exclusive medicine more often are advised to avoid such practice if possible. */  

with cte as
(select 
	YEAR(t.date) as 'year'
	,s.pharmacyName
	,count(m.hospitalExclusive) as exc_cnt
	,dense_rank() over(
		partition by YEAR(t.date) 
		order by count(m.hospitalExclusive) desc 
		) as rnk
from Pharmacy s
join Prescription p on p.pharmacyID = s.pharmacyID
join Treatment t on t.treatmentID = p.treatmentID
join Contain c on c.prescriptionID = p.prescriptionID
join Medicine m on m.medicineID = c.medicineID
where YEAR(t.date) in (2022, 2021) and
m.hospitalExclusive = 'S'
group by YEAR(t.date), s.pharmacyName)
select 
	year
	,pharmacyName
	,exc_cnt
from cte
where rnk  = 1
;


/*Problem Statement 2: Insurance companies want to assess the performance of their insurance plans. Generate a report that shows each insurance plan, the company that issues the plan, and the number of treatments the plan was claimed for.*/


select 
	ip.planName
	,ic.companyName
	,count(t.treatmentID) as cnt_of_treatment_claimed
from InsurancePlan ip
join InsuranceCompany ic on ic.companyID = ip.companyID
join Claim c on c.uin = ip.uin
join Treatment t on t.claimID = c.claimID
group by ip.planName, ic.companyName
;

/*Problem Statement 3: Insurance companies want to assess the performance of their insurance plans. Generate a report that shows each insurance company's name with their most and least claimed insurance plans.*/


with cte as
(
select 
	ic.companyName
	,ip.planName
	,count(c.claimID) as clain_cnt
	,rank() over(partition by ic.companyName order by count(c.claimID) desc) as high_rnk
	,rank() over(partition by ic.companyName order by count(c.claimID)) as low_rnk
from InsurancePlan ip
join InsuranceCompany ic on ic.companyID = ip.companyID
join Claim c on c.uin = ip.uin
group by ic.companyName, ip.planName
)
,cte1 as
(select 
	planName
	,companyName
from cte
where high_rnk = 1)
,cte2 as
(select 
	planName
	,companyName
from cte
where low_rnk = 1)
select 
	c1.companyName
	,c1.planName as most_plan
	,c2.planName as least_plan
from cte1 c1
join cte2 c2 on c1.companyName = c2.companyName
;


/*Problem Statement 4:  The healthcare department wants a state-wise health report to assess which state requires more attention in the healthcare sector. Generate a report for them that shows the state name, number of registered people in the state, number of registered patients in the state, and the people-to-patient ratio. sort the data by people-to-patient ratio. */

-- Problem 4
select 
	a.state
	,count(p.personID) as pers_cnt
	,count(pt.patientID) as patient_cnt
	,count(pt.patientID) * 100.0/ count(p.personID) as patient_person_ration
from Person p
left join Patient pt on pt.patientID = p.personID
join Address a on a.addressID = p.addressID
group by a.state
;


/*Problem Statement 5:  Jhonny, from the finance department of Arizona(AZ), has requested a report that lists the total quantity of medicine each pharmacy in his state has prescribed that falls under Tax criteria I for treatments that took place in 2021. Assist Jhonny in generating the report. 
*/
select 
	s.pharmacyName
	,sum(c.quantity) as med_cnt
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