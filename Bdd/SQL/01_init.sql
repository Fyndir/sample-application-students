CREATE TABLE public.departments
(
    id  Serial PRIMARY KEY,
    name    varchar(20) NOT NULL
);

CREATE TABLE public.students
(
    id serial PRIMARY KEY,
    department_id int not null references departments(id),
    first_name varchar(20) NOT NULL,
    last_name varchar(20) not null
);