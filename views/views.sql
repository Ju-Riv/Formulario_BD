-- View del update más reciente por hospital
create view most_recent_update_by_hospital as
SELECT 
  uh.id_hospital, uh.update_date, id_update, name_responder, id_personel_vm , id_questionnare_status, id_problem_status , id_action_status , funds, additional_comments
FROM update_hospital uh 
  INNER JOIN (
    SELECT uh2.id_hospital, MAX(uh2.update_date) AS most_recent FROM update_hospital uh2 GROUP BY uh2.id_hospital 
  ) ms ON uh.id_hospital = ms.id_hospital AND uh.update_date = most_recent;
  

-- View del update completo más reciente por hospital
create view most_recent_complete_update_by_hospital as
SELECT 
  uh.id_hospital, uh.update_date, id_update, name_responder, id_personel_vm , id_questionnare_status, id_problem_status , id_action_status , funds, additional_comments
FROM update_hospital uh 
  INNER JOIN (
    SELECT uh2.id_hospital, MAX(uh2.update_date) AS most_recent 
    FROM update_hospital uh2 
    where uh2.id_questionnare_status = 1 
    GROUP BY uh2.id_hospital 
  ) ms ON uh.id_hospital = ms.id_hospital AND uh.update_date = most_recent
  
 drop view most_recent_update_by_hospital cascade

-- View de casos y muertes por provincia
create view cases_and_deaths_by_province as
select p.id_province, count(cc.covid_deaths), count(cc.positive_patients) from covid_cases cc 
join most_recent_complete_update_by_hospital mrubh using (id_update)
join hospital h using (id_hospital)
join province p on h.province = p.id_province 
group by id_province;

-- View de hospitales con campañas de awareness
create view hospitals_with_awareness_campaigns as
select h.id_hospital, p.covid_awareness from hospital h 
join most_recent_complete_update_by_hospital mrubh using (id_hospital)
join protocol p using (id_update)
where p.covid_awareness = true ;

-- View de hospitales y si tienen campaña de awareness ordenados por sus casos
create view hospitals_awareness_cases as
select h.id_hospital, p.covid_awareness, cc.positive_patients from hospital h 
join most_recent_complete_update_by_hospital mrubh using (id_hospital)
join protocol p using (id_update)
join covid_cases cc using (id_update)
order by cc.positive_patients desc ;

--Vista con el nombre de hospitales que tienen <=1 números de telefono
create view hospitals_w_few_contacts as (
with aux as (
select h.id_hospital as id, h.hospital_name as nam, t.telephone as tel, t.active as status from hospital h join telephone t using (id_hospital)
), telefonos as ( 
select aux.id as id, aux.nam as hospital, count(aux.tel) as num_tel from aux where aux.status=true group by aux.id, aux.nam
) select telefonos.hospital, telefonos.id, telefonos.num_tel from telefonos where telefonos.num_tel<=1);

--Vista con hospitales registrados y el número de telefonos que tienen divididos en activos y no activos 
create view hospital_telephone as (
select id_hospital, h.hospital_name, count(t.id_telephone), t.active from hospital h join telephone t using (id_hospital) group by t.active, h.id_hospital order by h.id_hospital
);

--Vista con el número de updates realizados por cada empleado el último mes
create view last_month_updates as (
select pv.id_personel_vm as "Employee id",pv.employee_name as "Employee name",count(uh.id_update)as "Updates number" from update_hospital uh join 
personel_vm pv using (id_personel_vm) where 
((extract('month' from age(now(),uh.update_date)))=0 and (extract('year' from age(now(),uh.update_date)))=0 and (extract('day' from age(now(),uh.update_date)))<=31) 
or ((extract('month' from age(now(),uh.update_date)))<=1 and (extract('year' from age(now(),uh.update_date)))=0 and (extract('day' from age(now(),uh.update_date)))=0) 
group by pv.id_personel_vm
);

-- View de porcentajes de muertos, recuperados y positivos por hospital, no jala si covid cases está vacía porque all patients va a estar vacía
create view patient_percentages as (
with all_patients as(
select id_hospital, cc.covid_recovered+cc.covid_deaths+cc.positive_patients as patient_no 
from most_recent_complete_update_by_hospital mrubh 
join covid_cases cc using (id_update))
select mrubh2.id_hospital, cc2.covid_deaths/all_patients.patient_no as death_percentage, 
cc2.covid_recovered/all_patients.patient_no as recovered_percentage,
cc2.positive_patients/all_patients.patient_no as positive_percentage
from most_recent_update_by_hospital mrubh2 
join covid_cases cc2 );

-- View de provincias sin capacidad de hacer pruebas
create view provinces_wout_covid_test_cap as
select p.id_province , p.province_name, p2.test_capacity 
from most_recent_complete_update_by_hospital mrubh 
join hospital h using (id_hospital)
join province p on h.province = p.id_province 
join protocol p2 using (id_update)
where exists (select * from protocol p3 where p3.test_capacity = false)

-- View de distritos sin capacidad de hacer pruebas
create view districts_wout_covid_test_cap as
select d.id_district, d.district_name , p2.test_capacity 
from most_recent_complete_update_by_hospital mrubh 
join hospital h using (id_hospital)
join district d on h.district = d.id_district 
join protocol p2 using (id_update)
where exists (select * from protocol p3 where p3.test_capacity = false)

-- para probar la primera view (deben salir los días 23 y 24)
insert into update_hospital 
(name_responder, id_personel_vm,id_hospital,id_questionnare_status,id_problem_status,id_action_status,funds,additional_comments,update_date)
values
('Abdul -Ghani', 1,1,1,1,1,  'No','','2021-06-22 19:10:25-07'),
('Abdul -Ghani', 1,2,3,1,1,  'Yes-Private','','2021-06-23 19:10:25-07'),
('Abdul -Ghani', 1,1,1,1,1,  'No','','2021-06-24 19:10:25-07'),
('Abdul -Ghani', 1,2,3,1,1,  'Yes-Private','','2021-06-20 19:10:25-07');
