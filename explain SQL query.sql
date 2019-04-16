


















use mydb;




explain select * from R1 where (select count(*) from R1 where C=4) =2;


explain select * from R1 where A = 2;

explain select * from R1 where B = 2;
