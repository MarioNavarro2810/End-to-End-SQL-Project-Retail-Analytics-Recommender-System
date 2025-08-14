/* =========================================================
   ITEM–ITEM PRODUCT RECOMMENDER
   =========================================================
   This final section of the project closes our case study 
   by implementing an item–item recommendation system based 
   on historical transaction data.

   The goal is twofold:
     1. Identify products that are frequently purchased 
        together in the same order.
     2. Provide store-specific recommendations by analyzing 
        each store’s purchase history and suggesting 
        products they have not yet bought.*/

   /*To achieve this:
     - I create a master recommendations table where each 
       row contains a pair of products purchased together 
       along with the frequency of their co-occurrence.*/
       create table recomendador
select v1.id_prod as antecedente, v2.id_prod as consecuente, count(v1.id_pedido) as frecuencia
from v_ventas_agr_pedido as v1
	inner join v_ventas_agr_pedido as v2
     on v1.id_pedido = v2.id_pedido 
        and v1.id_prod != v2.id_prod 
        and v1.id_prod < v2.id_prod 
group by v1.id_prod, v2.id_prod; 
     
     /*I then query this table for a specific store to 
       generate tailored recommendations.*/
       with input_cliente as (
		SELECT distinct id_prod, id_tienda
		FROM ventas_agr
		where id_tienda = '1201'),
    productos_recomendados as (
		select consecuente, sum(frecuencia) as frecuencia
		from input_cliente as c
			left join
			 recomendador as r
			on c.id_prod = r.antecedente
		group by consecuente
		order by frecuencia desc)
        


     /* I ensure that recommended products are filtered to 
       exclude any items the store has already purchased 
       (using an anti–JOIN).*/
       select consecuente as recomendado, frecuencia
	   from productos_recomendados as r
			left join
			input_cliente as c
				on r.consecuente = c.id_prod
	   where id_prod is null;
   
   /*Note: To avoid timeouts when running the full co-occurrence 
   calculation, adjust MySQL Workbench settings:  
     Edit → Preferences → SQL Editor → Increase 
     "DBMS connection read timeout interval" (in seconds).
*/
