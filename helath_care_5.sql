/*Problem Statement 1: 
Johansson is trying to prepare a report on patients who have gone through treatments more than once. Help Johansson prepare
 a report that shows the patient's name, the number of treatments they have undergone, and their age, Sort the data in a way 
 that the patients who have undergone more treatments appear on top.
*/
select p.personname,count(t.treatmentid) as num_of_treatment,floor(abs(datediff(n.dob,curdate()))/365) as 
age from treatment t join person p on t.patientid=p.personid join patient n on n.patientid=p.personid group by t.patientid 
having (num_of_treatment>1) 
order by num_of_treatment desc;

/*
Problem Statement 2:  
Bharat is researching the impact of gender on different diseases, He wants to analyze if a certain disease is more
 likely to infect a certain gender or not.
Help Bharat analyze this by creating a report showing for every disease how many males and females underwent treatment 
for each in the year 2021. It would also be helpful for Bharat if the male-to-female ratio is also shown.
*/

  select diseasename,male,female,male/female as male_to_female_ratio from 
 (select count(gender) as female,diseaseid from person join treatment on person.personid=treatment.patientid  
 where gender='female' group by diseaseid) as f join (select count(gender) as male,diseaseid 
 from person join treatment on person.personid=treatment.patientid  
 where gender='male' group by diseaseid) as m using(diseaseid) join disease using(diseaseid);
 

/*
Problem Statement 3:  
Kelly, from the Fortis Hospital management, has requested a report that shows for each disease, the top 3 cities that had the most 
number treatment for that disease.
Generate a report for Kelly’s requirement.*/

with cte1 as (select count(treatmentid) as num,diseasename,city,dense_rank() over(partition by diseasename order by count(treatmentid)
 desc)as rank_city
from disease join treatment using(diseaseid) join person on person.personid=treatment.patientid join address using(addressid)
 group by diseasename,city )
 select * from cte1 where rank_city in (1,2,3);
 
/*Problem Statement 4: 
Brooke is trying to figure out if patients with a particular disease are preferring some pharmacies over others or not, 
For this purpose, she has requested a detailed pharmacy report that shows each pharmacy name, 
and how many prescriptions they have prescribed for each disease in 2021 and 2022, 
She expects the number of prescriptions prescribed in 2021 and 2022 be displayed in two separate columns.
Write a query for Brooke’s requirement.*/
select phar.pharmacyname,d.diseasename,count(presc.prescriptionid) as no_of_prescriptions,
sum( if(year(t.date)=2021,1,0)) as 2021_count,
sum( if(year(t.date)=2022,1,0)) as 2022_count
from pharmacy phar join prescription presc using(pharmacyid)
join treatment t using(treatmentid)
join disease d using(diseaseid)
group by phar.pharmacyname,d.diseasename
having 2021_count>1 AND 2022_count>1
order by no_of_prescriptions desc;

/*Problem Statement 5:  
Walde, from Rock tower insurance, has sent a requirement for a report that presents 
which insurance company is targeting the patients of which state the most. 
Write a query for Walde that fulfills the requirement of Walde.
Note: We can assume that the insurance company is targeting a region more if the patients of that region are 
claiming more insurance of that company.*/
with cte as
(select ic.companyName,a.state,count(p.patientID) as patient_cnt
,rank() over(partition by ic.companyName order by count(p.patientID) desc) as rnk
from InsuranceCompany ic
join InsurancePlan ip on ip.companyID = ic.companyID
join Claim c on c.uin = ip.uin
join Treatment t on t.claimID = c.claimID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
group by ic.companyName, a.state)
select * from cte where rnk = 1;