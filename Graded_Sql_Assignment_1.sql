-- Using a CTE, find out the total number of films rented for each rating (like 'PG', 'G', etc.) in the year 2005. 
-- List the ratings that had more than 50 rentals.
WITH film_rentals_by_rating AS(
	SELECT
		f.rating,
		COUNT(r.rental_id) AS total_film_count
	FROM public.film AS f
	INNER JOIN public.inventory AS i
	 ON f.film_id = i.film_id
	INNER JOIN public.rental AS r
	 ON i.inventory_id = r.inventory_id
	WHERE
		EXTRACT(YEAR FROM r.rental_date) = 2005
	GROUP BY
		f.rating
	HAVING (COUNT(r.rental_id))> 50
)

SELECT * FROM film_rentals_by_rating;

-- Identify the categories of films that have an average rental duration greater than 5 days. 
-- Only consider films rated 'PG' or 'G'.
SELECT
	ca.name AS category_name,
	AVG(f.rental_duration) AS avg_rental_duration
FROM public.category AS ca
INNER JOIN public.film_category AS fc
 ON fc.category_id = ca.category_id
INNER JOIN public.film AS f
 ON f.film_id = fc.film_id
WHERE 
	LOWER (CAST (f.rating AS TEXT)) IN ('pg','g')
GROUP BY 
	ca.name
HAVING(AVG(f.rental_duration)) >5

--  Determine the total rental amount collected from each customer. 
--  List only those customers who have spent more than $100 in total.
SELECT
	CONCAT(cu.first_name, '',cu.last_name) AS full_name,
	SUM (py.amount) AS total_rental_amount
FROM public.customer AS cu
INNER JOIN public.payment AS py
 ON py.customer_id = cu.customer_id
GROUP BY 
	CONCAT(cu.first_name, '',cu.last_name)
HAVING(SUM (py.amount)) > 100

-- Create a temporary table containing the names and email addresses of customers who have rented more than 10 films
DROP TABLE IF EXISTS temp_customer_rentals;
CREATE TEMPORARY TABLE temp_customer_rentals AS (
	SELECT
		cu.customer_id,
		CONCAT(cu.first_name, ' ', cu.last_name) AS full_name,
        cu.email
    FROM public.customer AS cu
    INNER JOIN public.rental AS r 
	 ON r.customer_id = cu.customer_id
    GROUP BY
		cu.customer_id,
        CONCAT(cu.first_name, ' ', cu.last_name),
        cu.email
    HAVING COUNT(r.rental_id) > 10
);
--CREATE INDEX idx_customer_id ON customer (customer_id);
SELECT * FROM temp_customer_rentals;

--  From the temporary table created in Task 3.1, identify customers who have a Gmail email address
SELECT *
FROM temp_customer_rentals
WHERE 
	temp_customer_rentals.email = '%@gmail.com'

-- 1) Start by creating a CTE that finds the total number of films rented for each category.
-- 2) Create a temporary table from this CTE.
-- 3) Using the temporary table, list the top 5 categories with the highest number of rentals. Ensure the results are in descending order.
-- 1)
WITH films_rented_by_category AS(
	SELECT
		fc.category_id,
		COUNT (r.rental_id) AS total_rental_count
	FROM public.film_category AS fc
	INNER JOIN film AS f
	 ON fc.film_id = f.film_id
	INNER JOIN public.inventory AS i
	 ON i.film_id = f.film_id
	INNER JOIN public.rental AS r
	 ON r.inventory_id = i.inventory_id
	GROUP BY 
		fc.category_id
)

SELECT * FROM films_rented_by_category;

--2)
DROP TABLE IF EXISTS temp_films_rented_by_category;
CREATE TEMPORARY TABLE temp_films_rented_by_category AS
	WITH films_rented_by_category AS(
	SELECT
		fc.category_id AS cat_id,
		COUNT (r.rental_id) AS total_rental_count
	FROM public.film_category AS fc
	INNER JOIN film AS f
	 ON fc.film_id = f.film_id
	INNER JOIN public.inventory AS i
	 ON i.film_id = f.film_id
	INNER JOIN public.rental AS r
	 ON r.inventory_id = i.inventory_id
	GROUP BY 
		fc.category_id
)
SELECT * FROM films_rented_by_category;
SELECT * FROM temp_films_rented_by_category;

-- 3)
SELECT
	cat_id,
	total_rental_count
FROM temp_films_rented_by_category
ORDER BY 
	total_rental_count DESC
LIMIT 5

--  Identify films that have never been rented out. Use a combination of CTE and LEFT JOIN for this task
WITH film_rented AS (
	SELECT
		DISTINCT i.film_id AS rented_film_id
	FROM public.rental AS r
	INNER JOIN public.inventory AS i
	 ON r.inventory_id = i.inventory_id
),

unrented_film AS (
	SELECT 
		f.film_id AS unrented_film_id,
		f.title AS film_title
	FROM public.film AS f
	LEFT OUTER JOIN film_rented AS f_r
	 ON f_r.rented_film_id = f.film_id
	WHERE 
		f_r.rented_film_id IS NULL
)

SELECT 
	unrented_film_id,
	film_title
FROM unrented_film;

-- (INNER JOIN): Find the names of customers who rented films with a replacement cost greater than $20 
-- and which belong to the 'Action' or 'Comedy' categories
SELECT
	DISTINCT cu.first_name,
	cu.last_name
FROM public.rental AS r
INNER JOIN public.customer AS cu
	ON r.customer_id = cu.customer_id
INNER JOIN public.inventory AS i
	ON i.inventory_id = r.inventory_id
INNER JOIN public.film AS f
	ON f.film_id = i.film_id
INNER JOIN public.film_category AS fc
	ON f.film_id = fc.film_id
INNER JOIN public.category AS ca
	ON ca.category_id = fc.category_id
WHERE
	f.replacement_cost > 20
AND
	ca.name IN ('Comedy','Action')
	
-- (LEFT JOIN): List all actors who haven't appeared in a film with a rating of 'R'.
SELECT
	DISTINCT ac.first_name AS actor_first_name,
	ac.last_name AS actor_last_name
FROM public.actor AS ac
LEFT OUTER JOIN public.film_actor AS fa
	ON fa.actor_id = ac.actor_id
LEFT OUTER JOIN public.film AS f
	ON fa.film_id = f.film_id AND LOWER(CAST(f.rating AS TEXT)) ='r'
WHERE
	f.film_id IS NULL
	
-- (Combination of INNER JOIN and LEFT JOIN): Identify customers who have never rented a film from 
-- the 'Horror' category.
WITH horror_rentals AS (
	SELECT
		DISTINCT cu.customer_id,
        cu.first_name,
        cu.last_name
    FROM customer cu
    INNER JOIN rental AS r 
		ON cu.customer_id = r.customer_id
    INNER JOIN inventory AS i 
		ON r.inventory_id = i.inventory_id
    INNER JOIN film_category AS fc 
		ON i.film_id = fc.film_id
    INNER JOIN category ca 
		ON fc.category_id = ca.category_id
    WHERE
        ca.name = 'Horror'
)
SELECT
    cu.customer_id AS cutomer_id_no_hr,
    cu.first_name AS first_name_no_hr,
    cu.last_name AS last_name_no_hr
FROM customer AS cu
LEFT JOIN horror_rentals AS hr 
	ON cu.customer_id = hr.customer_id
WHERE
    hr.customer_id IS NULL;

-- (Multiple INNER JOINs): Find the names and email addresses of customers who rented films directed by a specific actor 
-- (let's say, for the sake of this task, that the actor's first name is 'Nick' and last name is 'Wahlberg', 
--  although this might not match actual data in the DVD Rental database).
SELECT
	CONCAT(cu.first_name,'',cu.last_name),
	cu.email AS customer_email
FROM public.customer AS cu 
INNER JOIN public.rental AS r
	ON r.customer_id = cu.customer_id
INNER JOIN public.inventory AS i
	ON i.inventory_id = r.inventory_id
INNER JOIN film AS f 
	ON i.film_id = f.film_id
INNER JOIN public.film_actor AS fa
	ON fa.film_id = f.film_id
INNER JOIN public.actor As ac
	ON ac.actor_id = fa.actor_id
WHERE
	LOWER(ac.first_name) = 'nick' AND 
	LOWER(ac.last_name) = 'wahlberg'









