-- drop all tables for database
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE REQUEST_SEQ'; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN EXECUTE IMMEDIATE 'DROP TABLE MECHANIC CASCADE CONSTRAINT'; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN EXECUTE IMMEDIATE 'DROP TABLE SKILL'; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN EXECUTE IMMEDIATE 'DROP TABLE SPECIALTIES CASCADE CONSTRAINT'; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AIRCRAFT CASCADE CONSTRAINT'; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN EXECUTE IMMEDIATE 'DROP TABLE MAINTENANCE CASCADE CONSTRAINT'; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN EXECUTE IMMEDIATE 'DROP TABLE INSPECTION_SCHEDULE CASCADE CONSTRAINT'; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AIRCRAFT_BASES'; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ANALYSIST_REQUEST CASCADE CONSTRAINT'; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ORDER_PARTS CASCADE CONSTRAINT'; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AIRCRAFT_PARTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN EXECUTE IMMEDIATE 'DROP TABLE REQUEST_TYPE'; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN EXECUTE IMMEDIATE 'DROP TABLE CAPABLE_AIRCRAFTS'; EXCEPTION WHEN OTHERS THEN NULL; END;

