
use mydb2;


create table builder
(License_number INT PRIMARY KEY,
Builder_name varchar(30),
Address varchar(40)
);

/*----------------------------------------------------Insert Trigger -------------------------------------------------------------*/
Delimiter $
create trigger licenseTrig before insert on builder 
for each row
begin
if((new.License_number > 99999) OR (new.License_number <10000))
then
	signal sqlstate '45000'
    set message_text='License_number must be a 5 digit number';
end if;
end $

/*test query*/
insert into builder values(1234,'Builder-1','6426 Meadow Rd, Dallas,TX');

/*------------------------------------------------------------------------------------------------------------------------------------*/


create table building
(Builder_number INT NOT NULL,
Address varchar(40) PRIMARY KEY,
Type varchar(40),
Size BIGINT,
DateFirstActivity datetime,
foreign key(Builder_number) references builder(License_number)
);


create table inspector
(Inspector_ID INT PRIMARY KEY,
Inspector_name varchar(200),
Hire_date datetime NOT NULL
);

/*---------------------------------------------------Insert Trigger------------------------------------------------------------*/
Delimiter $
create trigger inspectorTrig before insert on inspector
for each row
begin
if((new.Inspector_ID > 999) OR (new.Inspector_ID <100))
then
	signal sqlstate '45000'
    set message_text='Inspector ID must be a 3 digit number';
end if;
end $

/*test query*/
insert into inspector values(10,'Inspector-1','1984-11-08'); 
/*------------------------------------------------------------------------------------------------------------------------------------*/


create table inspectionType
(Code varchar(3) PRIMARY KEY,
Inspection_type varchar(40) NOT NULL,
Cost INT NOT NULL
);

/*-------------------------------------------------------Cost Insert Trigger -----------------------------------------------------------------*/
Delimiter $
create trigger costTrigger before insert on inspectionType
for each row
begin
if(new.Cost < 0)
then
	signal sqlstate '45000'
    set message_text = 'The cost can not be negative';
end if;
end$


drop trigger costTrigger;

create table prerequisites
(Inspection_code varchar(3),
Prerequisite varchar(3),
Foreign key(Inspection_code) references inspectionType(Code)
);

/*-------------------------------------------------------Insert Trigger -----------------------------------------------------------------*/

Delimiter $
create trigger inspectionCodeTrigger before insert on inspectionType
for each row
begin
declare codeLength int;
set codeLength = (select length(new.Code));
if((codeLength>3)OR(codeLength < 3))
then
	signal sqlstate '45000'
    set message_text = 'The inspection code must be a 3 character code';
end if;
end $

/*test query */
insert into inspectionType values('FR','Framing',100);
/*------------------------------------------------------------------------------------------------------------------------------------------------*/


create table inspection
(Inspection_ID INT PRIMARY KEY,
Inspection_date datetime,
Inspection_type varchar(3) NOT NULL,
Inspector_ID INT NOT NULL,
Score INT,
Notes varchar(200),
Building_address varchar(40) NOT NULL,
Foreign key(Building_address) references building(Address),
Foreign key(Inspector_ID) references inspector(Inspector_ID),
Foreign key(Inspection_type) references inspectionType(Code)
);

/*----------------------------------------------------   Insert Trigger     ---------------------------------------------------------------------*/
Delimiter $
create trigger inspectionTrig before insert on inspection
for each row
begin
declare numOfInspections int;
declare numOfPrereq int;
declare actualPreReq int;
/*Get the number of inspections that are done by particular inspector in one month of a particular year*/
set numOfInspections = (select count(*) from inspection where ((Inspector_ID = new.Inspector_ID) AND
(year(Inspection_date)= year(new.Inspection_date)) AND (month(Inspection_date) = month(new.Inspection_date))));

/*Get the number of prerequisite inspections for a given inspection*/
set numOfPrereq = ((select count(prerequisite) from prerequisites where 
Inspection_code = new.Inspection_type));

/*get the number of inspections that have actually been passed for the given building*/
set actualPreReq = (select count(*) from inspection where Inspection_type in
( select prerequisite from prerequisites where 
Inspection_code = new.Inspection_type) AND (Building_address = new.Building_address) AND Score>=75);

if(numOfInspections >= 5)
then
	signal sqlstate '45000'
    set message_text = 'A inspector cannot perform more than 5 inspections per month';
elseif( actualPreReq < numOfPrereq)
then
        signal sqlstate '45000'
        set message_text = 'An inspection can not be requested unless all its prerequisite inspections are passed';
	
end if;
end $

/*test query for part 1*/
/*Insert 5 rows for inspector ID 103, in the month of november*/
insert into inspection values (4,'2018-11-14','FN3',103,100,'no problems noted','100 Industrial Ave.,Fort Worth,TX'),
(5,'2018-11-01','FRM',103,100,'no problems noted','100 Winding Wood,Carrollton,TX'),
(6,'2018-11-20','PLU',103,100,'everything working','100 Winding Wood,Carrollton,TX'),
(7,'2018-11-25','ELE',103,100,'no problems noted','100 Winding Wood,Carrollton,TX'),
(8,'2018-11-02','HAC',103,100,'no problems noted','100 Winding Wood,Carrollton,TX');


/*Try to insert 6th row for inspector 103 in the same month same year*/
insert into inspection values (3,'2018-11-14','FN2',103,100,'no problems noted','100 Industrial Ave.,Fort Worth,TX');

/*test query part 2*/
insert into inspection values(17,'2018-10-04','HAC',101,50,'duct needs taping','100 Industrial Ave.,Fort Worth,TX');
insert into inspection values(12,'2018-11-03','ELE',103,80,'exposed junction box','100 Industrial Ave.,Fort Worth,TX');
delete from inspection;
insert into inspection values(1,'2018-11-06','FRM',105,70,'okay','100 Industrial Ave.,Fort Worth,TX');
insert into inspection values(12,'2018-11-03','ELE',103,80,'exposed junction box','100 Industrial Ave.,Fort Worth,TX');
delete from inspection;
insert into inspection values(1,'2018-11-06','FRM',105,100,'okay','100 Industrial Ave.,Fort Worth,TX');
insert into inspection values(12,'2018-11-03','ELE',103,80,'exposed junction box','100 Industrial Ave.,Fort Worth,TX');

insert into inspection values(17,'2018-10-04','HAC',101,50,'duct needs taping','100 Industrial Ave.,Fort Worth,TX');

/*------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

/*-------------------------------------------------- Update trigger ----------------------------------------------------------*/
Delimiter $
create trigger updateInspectionTrig before update on inspection
for each row
begin
if((new.Score <> old.Score)AND((select Score from inspection where (Inspection_ID = new.Inspection_ID)) >= 0))
then
	signal sqlstate '45000'
    set message_text = 'The score once recorded can not be updated';
end if;
end $

drop trigger updateInspectionTrig;

/*test query*/
insert into inspection values(1,'2018-11-06','FRM',105,100,'okay','100 Industrial Ave.,Fort Worth,TX');
update inspection set Score= 90 where Inspection_ID=1;

/*------------------------------------------------------------------------------------------------------------------------------------*/

create table pending_inspection(
inspection_date datetime NOT NULL,
inspection_type varchar(3) NOT NULL,
building_address varchar(40) NOT NULL,
foreign key(building_address) references building(Address)
);



/*------------------------------------------------ Insert Trigger  -------------------------------------------------------------------*/
Delimiter $
create trigger prerequisiteCodeTrigger before insert on prerequisites
for each row
begin
declare codeLength int;
declare prereqLength int;
set codeLength = (select length(new.Inspection_code));
set prereqLength = (select length(new.Prerequisite));
if((codeLength>3)OR(codeLength < 3))
then
	signal sqlstate '45000'
    set message_text = 'The inspection code must be a 3 character code';
elseif(((prereqLength>3)OR(prereqLength < 3)))
then
	signal sqlstate '45000'
    set message_text = 'The prerequisite code must be a 3 character code';
end if;
end $

/*test query*/
insert into prerequisites values('FR','ELE');
insert into prerequisites values('FRM','EL');
/*--------------------------------------------------------------------------------------------------------------   ----------------------*/



insert into builder values(12345,'Builder-1','6426 Meadow Rd, Dallas,TX'),
(23456,'Builder-2','10501 N Central Expy, Dallas,TX'),
(34567,'Builder-3','6060 N Central Expy, Dallas,TX'),
(45678,'Builder-4','3100 Monticello Ave , Dallas,TX'),
(12321,'Builder-5','4145 Travis St , Dallas, TX');

select * from builder;

insert into building values(12345,'100 Main St.,Dallas,TX','commerical',250000,'	1999-12-31'),
(12345,'300 Oak St.,Dallas,TX','residential',3000,'2000-01-01'),
(12345,'302 Oak St.,Dallas,TX','residential',4000,'2001-02-01'),
(12345,'304 Oak St.,Dallas,TX','residential',1500,'2002-03-01'),
(12345,'306 Oak St.,Dallas,TX','residential',1500,'2003-04-01'),
(12345,'308 Oak St.,Dallas,TX','residential',2000,'2003-04-01'),
(23456,'100 Industrial Ave.,Fort Worth,TX','commerical',100000,'2005-06-01'),
(23456,'101 Industrial Ave.,Fort Worth,TX','commerical',80000,'2005-06-01'),
(23456,'102 Industrial Ave.,Fort Worth,TX','commerical',75000,'2005-06-01'),
(23456,'103 Industrial Ave.,Fort Worth,TX','commerical',50000,'2005-06-01'),
(23456,'104 Industrial Ave.,Fort Worth,TX','commerical',80000,'2005-06-01'),
(23456,'105 Industrial Ave.,Fort Worth,TX','commerical',90000,'2005-06-01'),
(45678,'100 Winding Wood,Carrollton,TX','residential',2500,null),
(45678,'102 Winding Wood,Carrollton,TX','residential',2800,null),
(12321,'210 Cherry Bark Lane,Plano,TX','residential',3200,'2016-10-01'),
(12321,'212 Cherry Bark Lane,Plano,TX','residential',null,null),
(12321,'214 Cherry Bark Lane,Plano,TX','residential',null,null),
(12321,'216 Cherry Bark Lane,Plano,TX','residential',null,null);


select * from building;


insert into inspectionType values('FRM','Framing',100),
('PLU','Plumbing',100),
('POL','Pool',50),
('ELE','Electrical',100),
('SAF','Safety',50),
('HAC','Heating/Cooling',100),
('FNL','Final',200),
('FN2','Final - 2 needed',150),
('FN3','Final - plumbing',150),
('HIS','Historical accuracy',100);

select * from inspectionType;

insert into prerequisites values('PLU','FRM'),
('POL','PLU'),
('ELE','FRM'),
('HAC','ELE'),
('FNL','HAC'),('FNL','PLU'),
('FN2','ELE'),('FN2','PLU'),
('FN3','PLU');


select * from prerequisites;


insert into inspector values(101,'Inspector-1','1984-11-08'),
(102,'Inspector-2','1994-11-08'),
(103,'Inspector-3','2004-11-08'),
(104,'Inspector-4','2014-11-01'),
(105,'Inspector-5','2018-11-01');

select * from inspector;



insert into inspection values(1,'2018-11-06','FRM',105,100,'okay','100 Industrial Ave.,Fort Worth,TX'),
(2,'2018-11-08','PLU',102,100,'no leaks','100 Industrial Ave.,Fort Worth,TX'),
(3,'2018-11-12','POL',102,80,'pool equipment okay','100 Industrial Ave.,Fort Worth,TX'),
(4,'2018-11-14','FN3',102,100,'no problems noted','100 Industrial Ave.,Fort Worth,TX'),
(5,'2018-10-01','FRM',103,100,'no problems noted','100 Winding Wood,Carrollton,TX'),
(6,'2018-10-20','PLU',103,100,'everything working','100 Winding Wood,Carrollton,TX'),
(7,'2018-10-25','ELE',103,100,'no problems noted','100 Winding Wood,Carrollton,TX'),
(8,'2018-11-02','HAC',103,100,'no problems noted','100 Winding Wood,Carrollton,TX'),
(9,'2018-11-01','FRM',103,100,'no problems noted','102 Winding Wood,Carrollton,TX'),
(10,'2018-11-02','PLU',103,90,'minor leak, corrected','102 Winding Wood,Carrollton,TX'),
(11,'2018-11-03','ELE',103,80,'exposed junction box','102 Winding Wood,Carrollton,TX'),
(12,'2018-11-02','FRM',105,100,'tbd','105 Industrial Ave.,Fort Worth,TX'),
(13,'2018-10-01','FRM',101,100,'no problems noted','300 Oak St.,Dallas,TX'),
(14,'2018-10-02','PLU',101,90,'minor leak, corrected','300 Oak St.,Dallas,TX'),
(15,'2018-10-03','ELE',101,80,'exposed junction box','300 Oak St.,Dallas,TX'),
(16,'2018-10-04','HAC',101,80,'duct needs taping','300 Oak St.,Dallas,TX'),
(17,'2018-10-05','FNL',101,90,'ready for owner','300 Oak St.,Dallas,TX'),
(18,'2018-10-01','FRM',102,100,'no problems noted','302 Oak St.,Dallas,TX'),
(19,'2018-10-02','PLU',102,25,'massive leaks','302 Oak St.,Dallas,TX'),
(20,'2018-10-08','PLU',102,50,'still leaking','302 Oak St.,Dallas,TX'),
(21,'2018-10-12','FRM',103,85,'no issues but messy','210 Cherry Bark Lane,Plano,TX'),
(22,'2018-10-14','SAF',104,100,'no problems noted','210 Cherry Bark Lane,Plano,TX'),
(23,'2018-11-04','PLU',103,80,'duct needs sealing','210 Cherry Bark Lane,Plano,TX'),
(24,'2018-11-05','POL',105,90,'ready for owner','210 Cherry Bark Lane,Plano,TX'),
(25,'2018-10-12','PLU',102,80,'no leaks, but messy','302 Oak St.,Dallas,TX'),
(26,'2018-10-14','ELE',102,100,'no problems noted','302 Oak St.,Dallas,TX');

insert into inspection values(28,'2018-10-31','HIS',101,90,'ok','306 Oak St.,Dallas,TX');

select * from inspection;

insert into pending_inspection values ('2018-09-01','FNL','105 Industrial Ave.,Fort Worth,TX'),
('2018-10-26','FRM','212 Cherry Bark Lane,Plano,TX'),
('2018-11-04','PLU','212 Cherry Bark Lane,Plano,TX');

select * from pending_inspection;

/*----------------------------------------------- QUERIES on PROJRCT DATA ----------------------------------------*/

/*1.	List all buildings (building#, address, type) that have not passed a final (FNL, FN2, FN3) inspection.*/

select Builder_number, Address, Type from 
building join inspection on (building.Address = inspection.Building_address)
where ((Inspection_type = 'FNL') OR (Inspection_type = 'FN2') OR (Inspection_type = 'FN3')) AND
(Score < 75) union
select Builder_number, Address, Type from 
building join inspection on (building.Address = inspection.Building_address)
where Inspection_type != 'FNL';


/*2.	List the id, name of inspectors who have given at least one failing score.*/

select distinct(inspector.Inspector_ID), Inspector_name from
inspector join inspection on (inspector.Inspector_ID = inspection.Inspector_ID)
where inspector.Inspector_ID  in 
(select inspector.inspector_ID from inspector join inspection on (inspector.Inspector_ID = inspection.Inspector_ID)
where (Score < 75));

/*3.	What inspection type(s) have never been failed?*/
select distinct(Inspection_type) from inspection where 
Inspection_type not in 
(select inspection.Inspection_type from inspection
where score < 75);

/*4.	What is the total cost of all inspections for builder 12345?*/
select sum(inspectionType.Cost) from
inspectionType join (building,inspection) on (inspectionType.Code = inspection.Inspection_type) AND
(building.Address = inspection.Building_address)
where building.Builder_number = 12345;

/*5.	What is the average score for all inspections performed by Inspector 102?*/

select avg(Score) from inspection
where Inspector_ID = 102;

/*6.	How much revenue did FODB receive for inspections during October 2018?*/
select sum(Cost) from inspection join inspectionType
on (inspectionType.Code = inspection.Inspection_type)
where(Inspection_date >= '2018-10-01') AND (Inspection_date <= '2018-10-31');

/*7.	How much revenue was generated in 2018 by inspectors with more than 15 years seniority?*/
select sum(Cost) from inspection join inspectionType
on (inspectionType.Code = inspection.Inspection_type) where
inspection.Inspector_ID in
(select Inspector_ID from inspector where
 datediff(CURDATE(),Hire_date)>15);
 
 /*8.	Demonstrate the adding of a new 1600 sq ft residential building for builder #34567, 
 located at 1420 Main St., Lewisville TX.*/
 
insert into building values(34567,'1420 Main St., Lewisville TX','residential',1600,'2018-11-20');

/*9.	Demonstrate the adding of an inspection on the building you just added. 
This framing inspection occurred on 11/21/2018 by inspector 104, 
with a score of 50, and note of “work not finished.”*/
insert into inspection values(27,'2018-11-21','FRM',104,50,'work not finished','1420 Main St., Lewisville TX');

/*10.	Demonstrate changing the cost of an ELE inspection changed to $150 effective today.  */
update inspectionType set cost = 150 where Code = 'ELE';

select cost from inspectiontype where Code = 'ELE';

/*
11.	Demonstrate adding of an inspection on the building you just added. 
This electrical inspection occurred on 11/22/2018 by inspector 104, with a score of 60, and note of “lights not completed.”
*/
insert into inspection values(28,'2018-11-22','ELE',104,60,'lights not completed','1420 Main St., Lewisville TX');


/*12.	Demonstrate changing the message of the FRM inspection on 11/2/2018 
by inspector #105 to “all work completed per checklist.”*/
update inspection set Notes='all work completed per checklist' where 
(Inspector_ID = 105) AND (Inspection_type = 'FRM') AND (Inspection_date='2018-11-02');

select Notes from inspection  where 
(Inspector_ID = 105) AND (Inspection_type = 'FRM') AND (Inspection_date='2018-11-02');


/*13.	Demonstrate the adding of a POL inspection by inspector #103 on 
11/28/2018 on the first building associated with builder 45678.*/
insert into inspection values(28,'2018-11-28','POL',103,NULL,NULL,'100 Winding Wood,Carrollton,TX');

select count(*) from inspection;


