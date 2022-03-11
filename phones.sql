create database phone_numbers_database;


-- Tables creation 

create table account_table
(
	account_id int not null,
	operator text not null,
	month_price int not null,
	balance int not null,
	status varchar(50) not null
);

create unique index account_table_account_id_uindex
	on account_table (account_id);

alter table account_table
	add constraint account_table_pk
		primary key (account_id);


create table shops_table
(
	buyer_id serial not null,
	shop_name text not null,
	shop_address text not null,
	buying_data date not null
);

create unique index shops_table_buyer_id_uindex
	on shops_table (buyer_id);

alter table shops_table
	add constraint shops_table_pk
		primary key (buyer_id);


create table personal_data
(
	person_id serial not null,
	phone_number varchar(12) not null,
	firstname text not null,
	lastname text not null,
	middlename text not null,
	active boolean not null
);

create unique index personal_data_person_id_uindex
	on personal_data (person_id);

alter table personal_data
	add constraint personal_data_pk
		primary key (person_id); Смена:
     CREATE TABLE shift_time (
    	stime_id  serial  not null,
    	wterm_id  integer,
    	shifttime integer not null,
    	PRIMARY KEY (stime_id),
    	FOREIGN KEY (wterm_id)
        REFERENCES working_term (wterm_id)
        ON DELETE CASCADE
);


create table subs_table
(
	subscriber_id serial not null,
	buyer_id int not null
		constraint subs_table_shops_table_buyer_id_fk
			references shops_table,
	person_id int not null
		constraint subs_table_personal_data_person_id_fk
			references personal_data,
	email text not null,
	account_id int not null
		constraint subs_table_account_table_account_id_fk
			references account_table,
	phone text not null,
	active bool not null;
);

create unique index subs_table_account_id_uindex
	on subs_table (account_id);

create unique index subs_table_buyer_id_uindex
	on subs_table (buyer_id);

create unique index subs_table_persone_id_uindex
	on subs_table (person_id);

create unique index subs_table_subscriber_id_uindex
	on subs_table (subscriber_id);

alter table subs_table
	add constraint subs_table_pk
		primary key (subscriber_id);


-- Insert data

INSERT INTO account_table(account_id, operator, month_price, balance, status)
VALUES ('111222', 'билайн', '250', 600, 'активен');
INSERT INTO account_table(account_id, operator, month_price, balance, status
VALUES ('222333', 'VNC', '450', 300, 'активен');
INSERT INTO account_table(account_id, operator, month_price, balance, status)
VALUES ('444555', 'Мегафон', '350', 1000, 'активен');

INSERT INTO personal_data(person_id, phone_number, firstname, lastname, middlename)
VALUES ('1', '+71231231122', 'Иван', 'Иванов', 'Иванович');
INSERT INTO personal_data(person_id, phone_number, firstname, lastname, middlename)
VALUES ('2', '+74514455522', 'Пётр', 'Петров', 'Петрович');
INSERT INTO personal_data(person_id, phone_number, firstname, lastname, middlename)
VALUES ('3', '+79877776655', 'Василий', 'Васильев', 'Васильевич');

INSERT INTO shops_table(buyer_id, shop_name, shop_address, buying_data)
VALUES ('1', 'связной', 'Бабаевская 10', '01.01.2019');
INSERT INTO shops_table(buyer_id, shop_name, shop_address, buying_data)
VALUES ('2', 'связной', 'Авнгардная 12', '08.15.2020');
INSERT INTO shops_table(buyer_id, shop_name, shop_address, buying_data)
VALUES ('3', 'цифрус', 'Магаданская 21', '03.21.2018');

INSERT INTO subs_table(subscriber_id, buyer_id, person_id, email, account_id, phone)
VALUES ('1', '2', '3', 'vasiliy@mail.ru', '3', 'мобильный');
INSERT INTO subs_table(subscriber_id, buyer_id, person_id, email, account_id, phone)
VALUES ('2', '3', '2', 'petrov@mail.ru', '2', 'домашний');
INSERT INTO subs_table(subscriber_id, buyer_id, person_id, email, account_id, phone)
VALUES ('3', '1', '1', 'ivanov@mail.ru', '1', 'офисный');


-- Add admin and user roles

CREATE ROLE mainuser LOGIN PASSWORD '123';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO mainuser;

GRANT USAGE ON SCHEMA public TO mainuser;

CREATE USER mainadmin SUPERUSER LOGIN PASSWORD 'admin';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO mainadmin;

-- Database requests

-- CASE request
-- Clients with tariff more expensive then 400 rubles

SELECT lastname, firstname, lastname,
CASE
WHEN month_price < 400
THEN 'цена тарифа меньше 400 рублей'
ELSE CAST(month_price AS CHAR(20))
END month_price
FROM public.personal_data
LEFT JOIN public.subs_table
ON public.personal_data.person_id=public.subs_table.persone_id
LEFT JOIN public.account_table ON public.subs_table.account_id=public.account_table.account_id;

-- Create view
-- Client full information

CREATE VIEW view1 AS SELECT p.firstname, p.lastname, p.phone_number, a.operator, a.balance
FROM public.personal_data AS p
LEFT JOIN public.subs_table AS s
ON s.persone_id=p.person_id
LEFT JOIN public.account_table AS a
ON s.account_id=a.account_id;


SELECT * FROM view1
ORDER BY firstname;

-- Correlated and uncorrelated subqueries
-- Clients with tariff price higher then average

SELECT e.firstname,
       e.lastname,
       (SELECT email FROM public.subs_table WHERE person_id =e.person_id) AS main,
       (SELECT s.balance FROM (SELECT balance, account_id FROM public.account_table WHERE account_id=(SELECT account_id FROM public.subs_table WHERE person_id=e.person_id)) AS s)
FROM (SELECT firstname, lastname, person_id FROM public.personal_data) AS e
WHERE (SELECT s.balance FROM (SELECT balance, account_id FROM public.account_table WHERE account_id=(SELECT account_id FROM public.subs_table WHERE person_id=e.person_id)) AS s) > (SELECT AVG(balance) FROM public.account_table);

-- Correlated and uncorrelated subqueries in WHERE
-- Clients with negative balance

SELECT i.email, i.phone
FROM public.subs_table AS i
WHERE (SELECT balance FROM public.account_table WHERE account_id=i.account_id) < 0
ORDER BY i.email;

-- Correlated and uncorrelated subqueries in SELECT
-- Clients with positive balance

SELECT email, phone, ((SELECT balance FROM public.account_table WHERE account_id=i.account_id) > 0) AS positive_balance
FROM public.subs_table AS i;

-- Correlated and uncorrelated subqueries in FROM
-- Client's balance at the beginning of the month

SELECT d.phone_number, (a.balance - a.month_price) AS result
FROM public.personal_data AS d, (SELECT person_id, account_id FROM public.subs_table) AS t, (SELECT account_id, balance, month_price FROM public.account_table ) AS a
WHERE d.person_id=t.person_id AND t.account_id=a.account_id
GROUP BY d.phone_number, result;

-- HAVING request
-- Clients with balance higher then average

SELECT firstname, lastname, phone_number, operator, balance
FROM public.account_table AS a, public.subs_table AS s, public.personal_data AS p
WHERE a.account_id=s.account_id AND s.person_id=p.person_id
GROUP BY firstname, lastname, phone_number, operator, balance
HAVING (balance) > (SELECT AVG(balance) FROM public.account_table);

-- ALL request
-- Clients with mobile phone and positive balance

SELECT e.firstname, e.lastname, s.phone, d.balance
FROM public.personal_data AS e
LEFT JOIN public.subs_table AS s
ON e.person_id=s.person_id
LEFT JOIN public.account_table AS d
ON s.account_id=d.account_id
WHERE (SELECT ALL(s.phone='мобильный' AND d.balance>0));

-- Index creation 

CREATE INDEX idx_firstname ON public.personal_data (firstname);
CREATE INDEX idx_lastname ON public.personal_data (lastname);
CREATE INDEX idx_phonenumber ON public.personal_data (phone_number);
CREATE INDEX idx_balance ON public.account_table (balance);

-- Trigger creation
-- If uset is inactive changes it's status

CREATE OR REPLACE FUNCTION activity_check()
RETURNS trigger AS
$$
BEGIN
if(new.active!=false)
then
UPDATE public.account_table AS a SET status='активен' WHERE account_id= new.person_id;
ELSE
UPDATE public.account_table AS a SET status='заблокирован' WHERE account_id= new.person_id;
end if;
return new;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER status
AFTER INSERT OR UPDATE
ON public.personal_data
FOR EACH ROW
EXECUTE PROCEDURE activity_check();

-- Trigget to update view 

CREATE OR REPLACE FUNCTION update_view() RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.firstname <> OLD.firstname THEN
        UPDATE personal_data
        SET firstname = NEW.firstname WHERE firstname = OLD.firstname;
    END IF;
    IF NEW.lastname <> OLD.lastname THEN
        UPDATE personal_data SET lastname = NEW.lastname WHERE lastname = OLD.lastname;
    END IF;
    IF NEW.phone_number <> OLD.phone_number THEN
        UPDATE personal_data SET phone_number = NEW.phone_number WHERE phone_number = OLD.phone_number;
    END IF;
    IF NEW.operator <> OLD.operator THEN
        UPDATE account_table SET operator = NEW.operator WHERE operator = OLD.operator;
    END IF;
    IF NEW.balance <> OLD.balance THEN
        UPDATE account_table SET balance = NEW.balance WHERE balance = OLD.balance;
    END IF;
    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;

CREATE TRIGGER update_view
    INSTEAD OF UPDATE
    ON view1
    FOR EACH ROW
EXECUTE FUNCTION update_view();

-- Function to insert data

CREATE OR REPLACE FUNCTION insert_data(pn varchar(12), fn text, ln text, mn text, act bool, oper text, mp int, bl int, sn text, sa text, bd date, em text, ph text) RETURNS VOID AS
$$
BEGIN

    IF (act != false) then
    INSERT INTO public.account_table(account_id, operator, month_price, balance, status)
    VALUES ((SELECT (SELECT MAX(account_id) FROM public.account_table) + 1), oper, mp, bl, 'активен');
    ELSE
    INSERT INTO public.account_table(account_id, operator, month_price, balance, status)
    VALUES ((SELECT (SELECT MAX(account_id) FROM public.account_table) + 1), oper, mp, bl, 'заблокирован');
    end if;
    INSERT INTO public.personal_data(person_id, phone_number, firstname, lastname, middlename, active)
    VALUES ((SELECT (SELECT MAX(person_id) FROM public.personal_data) + 1), pn, fn, ln, mn, act);
    INSERT INTO public.shops_table(buyer_id, shop_name, shop_address, buying_data)
    VALUES ((SELECT (SELECT MAX(buyer_id) FROM public.shops_table) + 1), sn, sa, bd);
    INSERT INTO public.subs_table(subscriber_id, buyer_id, person_id, email, account_id, phone)
    VALUES ((SELECT (SELECT MAX(subscriber_id) FROM public.subs_table) + 1), (SELECT (SELECT MAX(buyer_id) FROM public.shops_table)), (SELECT (SELECT MAX(person_id) FROM public.personal_data)),
            em, (SELECT (SELECT MAX(account_id) FROM public.account_table)), ph);
END
$$
  LANGUAGE 'plpgsql';

SELECT insert_data('+79999999999', 'Арсений', 'Арсениев', 'Арсениевич', 'true', 'МТС', '150', '100', 'связной', 'Бабаевская 45', '2010-01-01', 'arыутшум@mail.ru', 'мобильный');

-- Function to delet data 

create or replace function delete_data(main_id int) returns void
    language plpgsql
as
$$
DECLARE
    p_id int;
    a_id int;
    b_id int;
    s_id int;
BEGIN
    p_id = (SELECT person_id FROM public.subs_table WHERE subscriber_id=main_id);
    a_id = (SELECT account_id FROM public.subs_table WHERE subscriber_id=main_id);
    b_id = (SELECT buyer_id FROM public.subs_table WHERE subscriber_id=main_id);
    s_id = main_id;

    DELETE FROM public.subs_table WHERE subscriber_id=main_id;
    DELETE FROM public.shops_table WHERE buyer_id=b_id;
    DELETE FROM public.account_table WHERE account_id=a_id;
    DELETE FROM public.personal_data WHERE person_id=p_id;
END
$$;

SELECT delete_data('7');

-- Functions to update data for every table

CREATE OR REPLACE FUNCTION update_personal(p_id int, fn text, ln text, mn text, act bool) RETURNS VOID AS
$$
BEGIN
    UPDATE public.personal_data SET firstname=fn, lastname=ln, middlename=mn, active=act WHERE person_id=p_id;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION update_acc(a_id int, oper text, mp int, bl int) RETURNS VOID AS
$$
BEGIN
    UPDATE public.account_table SET operator=oper, month_price=mp, balance=bl WHERE account_id=a_id;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION update_shop(b_id int, sn text, sa text, bd date) RETURNS VOID AS
$$
BEGIN
    UPDATE public.shops_table SET shop_name=sn, shop_address=sa, buying_data=bd WHERE buyer_id=b_id;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION update_subs(s_id int, em text, ph text) RETURNS VOID AS
$$
BEGIN
    UPDATE public.subs_table SET email=em, phone=ph WHERE subscriber_id=s_id;
END
$$
LANGUAGE 'plpgsql';

-- Function to check activity and balance of the client and then insert data, if one of the parameters is incorrect displays and error

create or replace procedure insertAndCheck(pn varchar(12), fn text, ln text, mn text, act bool, oper text, mp int, bl int, sn text, sa text, bd date, em text, ph text)
    language plpgsql
as
$$
begin
    IF (act != false) then
    INSERT INTO public.account_table(account_id, operator, month_price, balance, status)
    VALUES ((SELECT (SELECT MAX(account_id) FROM public.account_table) + 1), oper, mp, bl, 'активен');
    ELSE
    INSERT INTO public.account_table(account_id, operator, month_price, balance, status)
    VALUES ((SELECT (SELECT MAX(account_id) FROM public.account_table) + 1), oper, mp, bl, 'заблокирован');
    end if;
    INSERT INTO public.personal_data(person_id, phone_number, firstname, lastname, middlename, active)
    VALUES ((SELECT (SELECT MAX(person_id) FROM public.personal_data) + 1), pn, fn, ln, mn, act);
    INSERT INTO public.shops_table(buyer_id, shop_name, shop_address, buying_data)
    VALUES ((SELECT (SELECT MAX(buyer_id) FROM public.shops_table) + 1), sn, sa, bd);
    INSERT INTO public.subs_table(subscriber_id, buyer_id, person_id, email, account_id, phone)
    VALUES ((SELECT (SELECT MAX(subscriber_id) FROM public.subs_table) + 1), (SELECT (SELECT MAX(buyer_id) FROM public.shops_table)), (SELECT (SELECT MAX(person_id) FROM public.personal_data)),
            em, (SELECT (SELECT MAX(account_id) FROM public.account_table)), ph);
    if(bl < 100000) then
        commit;
        else
        rollback;
        raise exception 'Слишком большой баланс';
    end if;
end
$$;

call insertAndCheck('+79999999999', 'Арсений', 'Арсениев', 'Арсениевич', 'true', 'МТС', '150', '9999999', 'связной', 'Бабаевская 45', '2010-01-01', 'arыутшум@mail.ru', 'мобильный');

-- Cursor in function usage
-- Funciton to update balance

CREATE OR REPLACE FUNCTION month_balance_update() RETURNS VOID AS
$$
DECLARE
    crs_my CURSOR FOR SELECT account_id, balance, month_price  FROM public.account_table AS a ;
    result int;
    a_id int;
    mp int;
    bl int;
BEGIN
    OPEN crs_my;
    LOOP
        FETCH crs_my INTO a_id, bl, mp;
        IF NOT FOUND THEN EXIT;
        end if;
        result = bl - mp;
        UPDATE public.account_table SET balance=result WHERE account_id=a_id;
    end loop;
    CLOSE crs_my;
END
$$
  LANGUAGE 'plpgsql';

SELECT month_balance_update();

-- Create function and use it in request
-- Function calculates average tariff price and request selects client with price lower then the result of the function

CREATE OR REPLACE FUNCTION avg_monthprice() RETURNS REAL AS
$$
DECLARE
    avgm REAL;
BEGIN
    avgm = (SELECT AVG(month_price) FROM public.account_table);
    RETURN avgm;
END
$$
  LANGUAGE 'plpgsql';

SELECT firstname, lastname, month_price, balance
FROM public.account_table, public.subs_table, public.personal_data
WHERE subs_table.person_id=personal_data.person_id AND subs_table.account_id=account_table.account_id AND month_price<(SELECT (avg_monthprice()))
GROUP BY firstname, lastname, month_price, balance;

-- Function to update operator's name

CREATE OR REPLACE FUNCTION GetInfoOper(oper text)
returns table(a_id int, op text, mp int, bl int, stat varchar(50)) language plpgsql as
    $$
    BEGIN
        return query
        select account_id, operator, month_price, balance, status
        from public.account_table
        where oper=operator;
    end;
    $$;

CREATE or REPLACE FUNCTION UpdInfoOper(oldO text, newO text) returns VOID AS
    $$
    DECLARE
    counter int;

        BEGIN
            counter = (select min(account_id) FROM account_table);
            WHILE counter < (select (max(account_id)+1) FROM account_table)
            LOOP

                UPDATE public.account_table set operator=newO WHERE operator=(select op FROM GetInfoOper(oldO) WHERE a_id=counter);

                counter = counter + 1;
            END LOOP ;

        END
    $$
    LANGUAGE 'plpgsql';


SELECT UpdInfoOper('билайн2', 'билайн');
