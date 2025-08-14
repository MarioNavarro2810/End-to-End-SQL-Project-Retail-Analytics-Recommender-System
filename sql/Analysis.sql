/* =========================================================
   ANALYSIS OVERVIEW
   =========================================================
   In this section, I perform a complete business analysis 
   using the prepared dataset. I start with a high-level 
   overview, then explore sales performance, product 
   portfolio insights, and customer segmentation to uncover 
   opportunities for growth and optimization.
*/
     
/* =========================================================
   1. HIGH-LEVEL BUSINESS OVERVIEW
   =========================================================
   I begin by getting a quick understanding of the business 
   through basic descriptive queries. Specifically, I check:*/
     
		-- how many orders we have in our historical data
        select max(id_pedido)
		from v_ventas_agr_pedido;
        
        -- the date range covered by the dataset
        select min(fecha) as primer_dia, max(fecha) as ult_dia
		from ventas_agr;
        
        -- how many distinct products are in our catalog
        select count(distinct id_prod) from productos;
        
        -- how many different stores we distribute to
        select count(distinct id_tienda) from tiendas;
        
        -- through which sales channels orders can be placed.
        select distinct canal from canales;
        
        
/* =========================================================
   2. SALES PERFORMANCE ANALYSIS
   =========================================================
   With the basic context established, I move on to a deeper 
   look at sales performance. I:		*/

		-- identify the top 3 sales channels by total revenue
        SELECT 
			canal, SUM(facturacion) AS facturacion
		FROM
			ventas_agr AS v		INNER JOIN	canales AS c 
            ON v.id_canal = c.id_canal
		GROUP BY canal
		ORDER BY facturacion DESC
		LIMIT 3;
        
        -- analyze the monthly revenue trend per channel over the last 12 complete months
        SELECT 
			canal,	MONTH(fecha) AS mes,	SUM(facturacion) AS facturacion_canal
		FROM
			ventas_agr AS v	INNER JOIN	canales AS c 
            ON v.id_canal = c.id_canal
		WHERE
			fecha BETWEEN '2017-07-01' AND '2018-06-30'
		GROUP BY v.id_canal , 2
		ORDER BY v.id_canal , mes;
        
        -- list the names of our 50 best customers (stores with the highest revenue)
        SELECT 
		nombre_tienda,	ROUND(SUM(facturacion), 0) AS facturacion_tienda
		FROM
			ventas_agr AS v	INNER JOIN	tiendas AS t 
            ON v.id_tienda = t.id_tienda
		GROUP BY v.id_tienda
		ORDER BY facturacion_tienda DESC
		LIMIT 50;
        
        -- examine the quarterly revenue trend for each country since 2017.
        SELECT 
			pais,	YEAR(fecha) AS año,	QUARTER(fecha) AS trimestre,	SUM(facturacion) facturacion_trimestre
		FROM	ventas_agr AS v	LEFT JOIN	tiendas AS t 
			ON v.id_tienda = t.id_tienda
		WHERE
			fecha BETWEEN '2017-01-01' AND '2018-06-30'
		GROUP BY pais , año , trimestre
		ORDER BY pais , año , trimestre;


/* =========================================================
   3. PRODUCT-LEVEL ANALYSIS
   =========================================================
   I now focus on the product portfolio to detect margin 
   opportunities and optimize our offering. In this section, I:	*/

	-- Determine the top 20 products with the highest margin — calculated as ((price - cost) / cost) * 100 within each product line.
		with tabla_margen as (
			select *, round((precio - coste) / coste,2) * 100 as margen
			from productos)
	select *
	from 
		(select id_prod, linea, producto, margen, row_number() over (partition by linea order by margen desc) as ranking
		from tabla_margen) as ranking
	where ranking <= 5;
    
	-- identify products where we are applying unusually high discounts, specifically those 
	-- with a discount percentage above the 90th percentile of all discounts 
    
    with tabla_descuentos as (
		select *, round(((precio_oficial_medio - precio_oferta_medio) / precio_oficial_medio),2) as descuento
		from (select id_prod, avg(precio_oficial) as precio_oficial_medio, avg(precio_oferta) as precio_oferta_medio
		  from ventas_agr
		  group by id_prod) nivel_producto)
	select *
	from (select id_prod, descuento, cume_dist() over(order by descuento) as distr_acum from tabla_descuentos) as acumulados
	where distr_acum >= 0.9;

	/* I also check how many distinct products we are currently selling, and from there, 
    -- determine which products we would need to keep to maintain 90% of the current revenue. 
    -- This also tells us which specific products could be removed without significantly impacting total sales*/
    
    select count(distinct producto)
	from productos;
    
    with fact_prod_acum_porc as (
		select *, round((fact_prod_acum / fact_prod_total),2) as fact_prod_acum_porc
		from (select id_prod,
			  sum(facturacion_prod) over (order by facturacion_prod desc) as fact_prod_acum,
			  sum(facturacion_prod) over() as fact_prod_total
			 from (select id_prod, sum(facturacion) as facturacion_prod
				   from ventas_agr
				   group by id_prod
				   order by facturacion_prod desc) as tabla_fact_prod) as tabla_temporal)
	select id_prod, fact_prod_acum, fact_prod_acum_porc
	from fact_prod_acum_porc
	where fact_prod_acum_porc <= 0.9;
    
    with a_mantener as (
		with fact_prod_acum_porc as (
			select *, round((fact_prod_acum / fact_prod_total),2) as fact_prod_acum_porc
			from (select id_prod,
				  sum(facturacion_prod) over (order by facturacion_prod desc) as fact_prod_acum,
				  sum(facturacion_prod) over() as fact_prod_total
				  from (select id_prod, sum(facturacion) as facturacion_prod
						from ventas_agr
						group by id_prod
						order by facturacion_prod desc) as tabla_fact_prod) as tabla_temporal)
	select id_prod, fact_prod_acum, fact_prod_acum_porc
	from fact_prod_acum_porc
	where fact_prod_acum_porc <= 0.9)

select distinct v.id_prod
from ventas_agr as v
	left join 
     a_mantener as m
	on v.id_prod = m.id_prod
where m.id_prod is null;

    
	/* Additionally, I analyze the diversity of our product portfolio by listing all 
     different product lines we sell, measuring the contribution of each line to the total revenue, 
     and identifying any low-performing lines. In this case, I find that the Outdoor Protection line 
     contributes only 1% of total revenue, meaning it could potentially be discontinued without much impact */
    select distinct linea
	from productos;
    
		with facturacion_por_linea as (
			select linea, sum(facturacion) as facturacion_linea
			from ventas_agr as v inner join productos as p on v.id_prod = p.id_prod
			group by linea)
	select linea, facturacion_linea, round(facturacion_linea / sum(facturacion_linea) over(),2) as pct_linea
	from facturacion_por_linea
	order by pct_linea desc;
    
	/* Finally, I investigate whether the top-grossing product line contains any trending products. 
     I define “trending” as products whose revenue in Q2 2018 shows growth compared to Q1 2018 */
    with producto_trimestre as (
		select linea, producto, quarter(fecha) as trimestre, sum(facturacion) facturacion_prod
		from ventas_agr as v	left join	productos as p
			on v.id_prod = p.id_prod
		where linea = 'Personal Accessories' and fecha between '2018-01-01' and '2018-06-30'
		group by producto, 3
		order by 2,3)
select producto, crecimiento
from (select linea, producto, trimestre, facturacion_prod,
	   facturacion_prod / lag(facturacion_prod) over (partition by producto order by trimestre) as crecimiento
	  from producto_trimestre) as subconsulta
where crecimiento is not null
order by crecimiento desc;


/* =========================================================
   4. CUSTOMER MANAGEMENT
   =========================================================
   Finally, I turn to customer-focused analysis to support 
   segmentation, development, and reactivation strategies.
   Steps include:*/
   --  building a 4-quadrant segmentation matrix (Orders × Revenue) by splitting customers above/below the mean for each axis
		
        create view v_segmentacion_matriz as
	with pedidos_fact_tienda as (
		select id_tienda, count(id_tienda) as num_pedidos, sum(facturacion) as facturacion
		from v_ventas_agr_pedido
		group by id_tienda),

		medias as (
		select avg(num_pedidos) as media_pedidos, avg(facturacion) as media_facturacion
		from pedidos_fact_tienda
		)
	select *,
		case
			when num_pedidos <= media_pedidos and facturacion <= media_facturacion then 'P- F-'
			when num_pedidos <= media_pedidos and facturacion > media_facturacion then 'P- F+'
			when num_pedidos > media_pedidos and facturacion <= media_facturacion then 'P+ F-'
			when num_pedidos > media_pedidos and facturacion > media_facturacion then 'P+ F+'
			else 'ERROR'
		end as segmentacion
	from pedidos_fact_tienda, medias;
    
	-- Once the segmentation is complete, I calculate how many customers fall into each of the four segments 
    -- to understand the overall distribution of our client base.
        select segmentacion, count(*)
		from v_segmentacion_matriz
		group by segmentacion;

	/* Next, I assess development potential by segmenting stores by type and calculating the 
	 75th percentile (P75) of revenue within each store type. For any store below its type’s P75, 
     I calculate a potential growth value (the difference between its current revenue and the P75 benchmark) 
    to highlight specific opportunities for revenue uplift.*/
		with nivel_tienda as (
select t.id_tienda, tipo, facturacion
	from tiendas as t
		inner join (
			select id_tienda, sum(facturacion) as facturacion
			from ventas_agr
			group by id_tienda
			) as v
		on t.id_tienda = v.id_tienda
	),
	p75_por_tienda as (
		select tipo, facturacion as ideal
        from (
			select tipo, facturacion, percentil, row_number() over(partition by tipo order by percentil) as ranking
			from (
				select *, round(percent_rank() over(partition by tipo order by facturacion),2) * 100 as percentil
				from nivel_tienda
				) as con_percentil
			where percentil >= 75) as ranking
		where ranking = 1)
select t.id_tienda, t.tipo, t.facturacion, ideal,
	   case
			when (ideal - facturacion) <= 0 then 0
            when (ideal - facturacion) > 0 then (ideal - facturacion)
	   end as potencial
from nivel_tienda as t
	inner join
	 p75_por_tienda as p
	 on t.tipo = p.tipo;
     
	/* Finally, I focus on customer reactivation. I identify stores that have not placed an order 
     for more than 3 months compared to the latest date in our dataset. To do this, I use the DATEDIFF() 
     function to measure the gap in days between a store’s last purchase and the dataset’s maximum date, 
     flagging those beyond the 90-day threshold as inactive customers.*/
		with ultima_fecha_total as (
			select max(fecha) as ult_fecha_total
			from ventas_agr),
		ultima_fecha_tienda as(
			select id_tienda, max(fecha) as ult_fecha_tienda
			from ventas_agr
			group by id_tienda)
	select *
	from (
			select *, datediff(ult_fecha_total, ult_fecha_tienda) as dias_sin_comprar
			from ultima_fecha_tienda, ultima_fecha_total) as dias_sin_comprar
	where dias_sin_comprar > 90;


/* =========================================================
   END OF ANALYSIS
   =========================================================
   This end-to-end analysis provides a clear understanding 
   of the business from different perspectives, highlighting 
   key revenue drivers, high-margin products, and customer 
   segments with the greatest potential for growth.
*/




