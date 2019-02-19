--return random result every time between 0 and 1
SELECT random();
--return random result every time between 0 and 20
SELECT 20*random();
--return random result every time between -10 and 10
SELECT 20*random() - 10;

--return same random result 
SELECT setseed(.123);
SELECT random();

--generate date
SELECT TO_CHAR(day, 'YYYY-MM-DD') FROM generate_series
        ( '2017-02-01'::date
        , '2017-04-01'::date
        , '1 day'::interval) day;
		
SELECT gs.d::date
FROM generate_series(
  timestamp without time zone '2016-08-14',
  timestamp without time zone '2016-09-15',
  '1 day'
)  AS gs(d);

--generate integers between 5 and 10 inclusive
select floor(random()*(10-5+1))+5
from generate_series(1, 10);

--generate phone numbers
select '+7' || format('(%s%s%s) %s%s%s-%s%s%s%s', 
			  arr[1], arr[2], arr[3], arr[4], arr[5], arr[6], arr[7], arr[8], arr[9], arr[10])::varchar
from (
	 select array (
					SELECT (random() * 10)::int
						FROM   generate_series(1, 10)
		          ) as arr
	 ) as cte;

--generate random string																					  
	select array_to_string(arr, '')
	from (
			select array(
						  select substr('abcdefghjkmnpqrstuvwxyz', ((random()*(28-1)+1)::integer) ,1)
							from generate_series(1,6)
				         ) as arr
	) as cte;

SELECT array_to_string(ARRAY
					   		(SELECT chr((97 + round(random() * 25)) :: integer) 
								FROM generate_series(1,15)  
							), ''
					   );

--generate random columns of strings
with symbols(characters) 
	as (VALUES ('abcdefghjkmnpqrstuvwxyz'))
select string_agg(substr(characters, (random() * length(characters) + 1) :: INTEGER, 1), '')
	from symbols
	join generate_series(1,8) as word(chr_idx) on 1 = 1 -- word length
	join generate_series(1,10) as words(idx) on 1 = 1 -- # of words
group by idx;


with symbols(str1, str2)
  as (select 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghjkmnpqrstuvwxyz' )
select string_agg(substr(str1, (random() * length(str1) + 1) :: INTEGER, 1), '') ||
       string_agg(substr(str2, (random() * length(str2) + 1) :: INTEGER, 1), '')
from symbols
join generate_series(1,8) as word(chr_idx) on 1 = 1 -- word length
join generate_series(1,10) as words(idx) on 1 = 1
group by idx;

--generate test tables with data
DROP TABLE test_employees;
				
create table test_employees (
  employee_id serial primary key,
  first_name varchar,
  last_name varchar,
  phone_number varchar,
  hire_date date,
  department_id integer
);

create or replace function generate_string(word_length int)
returns text as $$
  declare word text;
begin
  with symbols(characters)
	as (VALUES ('abcdefghjkmnpqrstuvwxyz'))
  select string_agg(substr(characters, (random() * length(characters) + 1) :: INTEGER, 1), '') into word
  from symbols
  join generate_series(1, word_length) as word(chr_idx) on 1 = 1;
  return word;
end;$$
language plpgsql;


create or replace function generate_phone()
returns varchar as $$
  declare word varchar;
begin
  select format('(%s%s%s) %s%s%s-%s%s%s%s',
          arr[1], arr[2], arr[3], arr[4], arr[5], arr[6], arr[7], arr[8], arr[9], arr[10])::varchar-- into word
  from (
     select array(
      SELECT (random() * 9)::int
      FROM   generate_series(1, 10)
      ) as arr
    ) as cte;
  return word;
end;$$
language plpgsql;


create or replace function generate_date(start_date date)
returns date as $$
  declare hire_date date;
begin
  select start_date +
               (random() * (current_date - start_date))::int into hire_date;
  return hire_date;
end;$$
language plpgsql;

--select generate_date(date '2010-01-01');
--select generate_phone();
--select generate_string(10);

insert into test_employees (first_name)
with symbols(characters)
	as (VALUES ('abcdefghjkmnpqrstuvwxyz'))
select string_agg(substr(characters, (random() * length(characters) + 1) :: INTEGER, 1), '')
from symbols
join generate_series(1,7) as word(chr_idx) on 1 = 1 -- word length
join generate_series(1,200) as words(idx) on 1 = 1 -- # of words
group by idx;

update test_employees
set last_name = generate_string(10);

update test_employees
set phone_number = generate_phone();

update test_employees
set hire_date = generate_date(date '2010-01-01');

SELECT * FROM test_employees;

create table test_departments
(
  department_id serial,
  department_name varchar,
  location varchar
);


create or replace function generate_location()
  returns varchar as $$
declare location varchar;
begin
  select (array['europe', 'america', 'asia'])[floor(random() * 3 + 1)] into location;
  return location;
end;$$
language plpgsql;

--select generate_location();

insert into test_departments (department_name)
with symbols(characters)
	as (VALUES ('abcdefghjkmnpqrstuvwxyz'))
select string_agg(substr(characters, (random() * length(characters) + 1) :: INTEGER, 1), '')
from symbols
join generate_series(1,10) as word(chr_idx) on 1 = 1 -- word length
join generate_series(1,9) as words(idx) on 1 = 1 -- # of words
group by idx;

update test_departments
set location = generate_location();


create or replace function get_random_department_id()
  returns integer as $$
declare random_department_id integer;
begin
    select department_id into random_department_id from test_departments order by random() limit 1;
  return random_department_id;
end;$$
language plpgsql;

--select get_random_department_id();

update test_employees
set department_id = get_random_department_id();

select * from test_employees order by employee_id;
select * from test_departments;

alter table test_departments add primary key (department_id);
alter table test_departments alter column department_name set not null;
alter table test_departments alter column location set not null;

alter table test_employees alter column first_name set not null;
alter table test_employees alter column last_name set not null;
alter table test_employees alter column phone_number set not null;
alter table test_employees alter column hire_date set not null;
alter table test_employees add constraint test_employees_fk foreign key (department_id) references test_departments(department_id) match full;
