-- ===============================
-- AdventurePro Retail - setup.sql
-- Requires: MySQL 8.0+
-- ===============================


-- First, I import the database from the provided dump file (adventurepro_dump.sql).
	-- This step allows me to load all the base tables — sales, products, channels, and stores — so I can start working with the complete dataset in MySQL.


-- Next, I set the adventurepro database as the default active schema. 
	-- By doing this, every query I run will be executed directly on this database, without having to specify its name in each statement.
use adventurepro;


-- After importing, I review the contents of the four base tables (sales, products, channels, and stores).
select * from canales;
select * from productos;
select * from tiendas;
select * from ventas;

-- By running a quick query, I notice that the sales table is at the individual product level.
select count(*) as conteo
from ventas
group by id_tienda, id_prod, id_canal, fecha
having conteo > 1;


-- Even for the same product, there can be multiple separate records if it appears in different lines of the same order.
select count(*) as conteo
from ventas
group by id_tienda, id_prod, id_canal, fecha
having conteo > 1;

-- For example: 
select * from ventas
where id_tienda = "1115" and id_prod = "127110" and id_canal = "5" and fecha = "22/12/2016";



-- To make the analysis more efficient, I create a new table called sales_agg, where I aggregate sales at the order level,
-- grouping together those sales that share the same date, sales channel, and store (client). In this process, I sum the quantities 
-- for each product within the same order, so each row represents the total units sold per product in that order, rather than multiple split records.
-- Additionally, I convert the date column to the DATE type for easier manipulation in later queries, and I create a new field for revenues called "facturacion"
-- that calculates the total amount for each aggregated row by multiplying quantity by the offer price.

create table ventas_agr as
select str_to_date(fecha, '%d/%m/%Y') as fecha,
	   id_prod, id_tienda, id_canal,
       sum(cantidad) as cantidad,
       avg(precio_oficial) as precio_oficial,
       avg(precio_oferta) as precio_oferta,
       sum(cantidad) * avg(precio_oferta) as facturacion
from ventas
group by 1, 2, 3, 4;   

-- As we can see, the new aggregated table contains fewer records, since multiple product-line entries have been consolidated 
-- into single rows. There are no longer duplicates or multiple records where the sales channel, store, and date are the same, 
-- making the dataset much cleaner and easier to work with for analysis.



-- Although I could already run queries on the new aggregated table using JOIN clauses, I decide to modify it so that it is 
-- formally related to the existing dimension tables (products, stores, and channels).
alter table ventas_agr add id_venta int auto_increment primary key,
					   add foreign key(id_prod) references productos(id_prod) on delete cascade,
                       add foreign key(id_tienda) references tiendas(id_tienda) on delete cascade,
                       add foreign key(id_canal) references canales(id_canal) on delete cascade;
                       
-- In addition, I create a view that I will use later in the project.
-- This view takes the newly created aggregated sales table and adds a new column called order_id, which I generate using the ROW_NUMBER() window function.
-- The purpose of this column is to assign a unique identifier to each order based on the combination of date, store, and sales channel, allowing me to 
-- group and analyze sales at the order level more easily in subsequent queries.
create view v_ventas_agr_pedido as
with maestro_pedidos as (
	select fecha, id_tienda, id_canal, row_number() over() as id_pedido
	from ventas_agr
	group by fecha, id_tienda, id_canal)
select v.id_venta, id_pedido, v.fecha, v.id_prod, v.id_tienda, v.id_canal, v.cantidad, v.precio_oficial, v.precio_oferta, v.facturacion
from ventas_agr as v
	left join
     maestro_pedidos as m
     on (v.fecha = m.fecha) and (v.id_tienda = m.id_tienda) and (v.id_canal = m.id_canal);
