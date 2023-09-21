/*Problem Statement 1: 
Insurance companies want to know if a disease is claimed higher or lower than average.  
Write a stored procedure that returns “claimed higher than average” or “claimed lower than average” 
when the diseaseID is passed to it. 
Hint: Find average number of insurance claims for all the diseases.  If the number of claims for the passed disease is higher than the average return “claimed higher than average” otherwise “claimed lower than average”.*/

delimiter //
create procedure claim(in did int,out msg varchar(20))
begin 
declare avg decimal(10,3);
set avg=(select avg(c) from (select count(claimid) as c,diseaseid from treatment group by diseaseid)as z);
with cte as(
select count(claimid) as n,diseaseid from treatment where diseaseid=did group by diseaseid
)
select case when n>avg then 'claimed higher than average'
else 'claimed lower than average'
end as status from cte;

end//
delimiter ;

call claim(1,@avg)


/*
Problem Statement 2:  
Joseph from Healthcare department has requested for an application which helps him get genderwise report for any disease. 
Write a stored procedure when passed a disease_id returns 4 columns,
disease_name, number_of_male_treated, number_of_female_treated, more_treated_gender
Where, more_treated_gender is either ‘male’ or ‘female’ based on which gender underwent more often for 
the disease, if the number is same for both the genders, the value should be ‘same’.*/

delimiter //
create procedure gender_count(in did int)
begin
with cte as (
  select disea
  seid,diseasename,male,female,case when male> female then 'Male' else 'Female' end as male_or_female from 
 (select count(gender) as female,diseaseid from person join treatment on person.personid=treatment.patientid  
 where gender='female' group by diseaseid) as f join (select count(gender) as male,diseaseid 
 from person join treatment on person.personid=treatment.patientid  
 where gender='male' group by diseaseid) as m using(diseaseid) join disease using(diseaseid))
 select * from cte where diseaseid=did
 ;
end//
delimiter ;
call gender_count(1);


/*
Problem Statement 3:  
The insurance companies want a report on the claims of different insurance plans. 
Write a query that finds the top 3 most and top 3 least claimed insurance plans.
The query is expected to return the insurance plan name, the insurance company name which has that plan, 
and whether the plan is the most claimed or least claimed. */


(select count(claimid) as no_of_claim,planname,companyname,'most' as status from claim join 
insuranceplan using(uin) join insurancecompany using(companyid) group by uin 
order by no_of_claim desc limit 3) union all (select count(claimid) as 
no_of_claim,planname,companyname,'least' as status from claim join insuranceplan 
using(uin) join insurancecompany using(companyid) group by uin 
order by no_of_claim limit 3);

/*
with cte as
(select
	ip.planName
	,ic.companyName
	,count(c.claimID) as claim_cnt
from InsuranceCompany ic
join InsurancePlan ip on ic.companyID = ip.companyID
join Claim c on c.uin = ip.uin
group by ip.planName, ic.companyName)
,cte1 as
(select 
	planName
	,companyName
	,claim_cnt
	,'most' as status
from cte
order by claim_cnt desc limit 3)
,cte2 as
(select 
	planName
	,companyName
	,claim_cnt
	,'least' as status
from cte
order by claim_cnt limit 3 )
select * from cte1
union
select * from cte2;
*/



/*
Problem Statement 4: 
The healthcare department wants to know which category of patients is being affected the most by each disease.
Assist the department in creating a report regarding this.
Provided the healthcare department has categorized the patients into the following category.
YoungMale: Born on or after 1st Jan  2005  and gender male.
YoungFemale: Born on or after 1st Jan  2005  and gender female.
AdultMale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender male.
AdultFemale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender female.
MidAgeMale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender male.
MidAgeFemale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender female.
ElderMale: Born before 1st Jan 1970, and gender male.
ElderFemale: Born before 1st Jan 1970, and gender female.*/

with cte as
(select
	CASE
		WHEN pt.dob >= '2005-01-01' AND gender = 'Male' THEN 'YoungMale'
		WHEN pt.dob >= '2005-01-01' AND gender = 'Female' THEN 'YoungFemale'
		WHEN pt.dob < '2005-01-01' AND pt.dob >= '1985-01-01' AND gender = 'Male' THEN 'AdultMale'
		WHEN pt.dob < '2005-01-01' AND pt.dob >= '1985-01-01' AND gender = 'Female' THEN 'AdultFemale'
		WHEN pt.dob < '1985-01-01' AND pt.dob >= '1970-01-01' AND gender = 'Male' THEN 'MidAgeMale'
		WHEN pt.dob < '1985-01-01' AND pt.dob >= '1970-01-01' AND gender = 'Female' THEN 'MidAgeFemale'
		WHEN pt.dob < '1970-01-01' AND gender = 'Male' THEN 'ElderMale'
		WHEN pt.dob < '1970-01-01' AND gender = 'Female' THEN 'ElderFemale'
		ELSE 'Unknown'
	END as category
	,d.diseaseName
from Patient pt
join Person p on p.personID = pt.patientID
join Treatment t on t.patientID = pt.patientID
join Disease d on d.diseaseID = t.diseaseID
)
,cte1 as
(select 
	category
	,diseaseName
	,count(diseaseName) as dis_per_cat
	,row_number() over(partition by diseaseName order by count(diseaseName) desc) as rnk
from cte
group by diseaseName, category)
select 
	diseaseName
	,category
	,dis_per_cat
from cte1
where rnk = 1;


/*
Problem Statement 5:  
Anna wants a report on the pricing of the medicine. She wants a list of the most expensive and most affordable medicines only. 
Assist anna by creating a report of all the medicines which are pricey and affordable, listing the companyName, productName, description, maxPrice, and the price category of each. Sort the list in descending order of the maxPrice.
Note: A medicine is considered to be “pricey” if the max price exceeds 1000 and “affordable” if the price is under 5. Write a query to find 
*/

select medicineid,companyname,productname,description,maxprice,case when maxprice>=1000 then 'Pricey' else 'Affordable' end as category 
from medicine where maxprice>=1000 or maxprice<=5 order by maxprice;