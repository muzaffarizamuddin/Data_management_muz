student = LOAD '/user/maria_dev/muzaffar/student_details_1.csv' USING PigStorage(',') AS
(
	userID:chararray,
    first_name:chararray,
    second_name:chararray,
    ID_number:chararray,
    city:chararray
);
--DUMP student;

student_fixed = FOREACH student GENERATE 
    REPLACE
    (userID, '001Rajiv', '001') AS userID,
    (userID == '001Rajiv' ? 'Rajiv' : first_name) AS first_name,
    (second_name == 'Khana' ? 'Khanna' : second_name) AS second_name,
    ID_number,
    city;

--DUMP student_fixed;

student_filtered = FILTER student_fixed BY userID IS NOT NULL;

student_distinct = DISTINCT student_filtered;

DUMP student_distinct;

