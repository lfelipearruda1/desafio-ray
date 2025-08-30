USE CATALOG workspace;
USE SCHEMA default;

CREATE OR REPLACE FUNCTION fn_norm_cidade(s STRING)
RETURNS STRING
RETURN regexp_replace(
         regexp_replace(
           upper(translate(element_at(split(trim(s), '-'), 1),
           'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
           'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC')),
         '[^A-Z0-9 ]',''),
       '\\s+',' '
);

DROP TABLE IF EXISTS vendas_limpo;
DROP TABLE IF EXISTS cotacoes_limpo;

CREATE TABLE vendas_limpo AS
WITH base AS (
  SELECT row_number() OVER (ORDER BY _c0) AS rn, _c0 AS line
  FROM vendas
),
sem_header AS (
  SELECT line FROM base WHERE rn > 1
),
parsed AS (
  SELECT from_csv(
           regexp_replace(line,';+',','),
           'id_venda string,data_venda string,local_venda string,tipo_maquina string,valor_total string,revendedor_id string',
           map('delimiter',',')
         ) AS r
  FROM sem_header
)
SELECT
  r.id_venda,
  CASE
    WHEN r.data_venda RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN to_date(r.data_venda,'yyyy-MM-dd')
    WHEN r.data_venda RLIKE '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN to_date(r.data_venda,'dd/MM/yyyy')
    WHEN r.data_venda RLIKE '^[0-9]{2}/[0-9]{2}/[0-9]{2,4}$' THEN to_date(r.data_venda,'MM/dd/yyyy')
    ELSE NULL
  END AS data_venda,
  coalesce(fn_norm_cidade(nullif(trim(r.local_venda),'')),'DESCONHECIDO') AS cidade_std,
  nullif(trim(r.tipo_maquina),'') AS tipo_maquina,
  coalesce(
    TRY_CAST(
      NULLIF(
        regexp_replace(
          regexp_replace(coalesce(r.valor_total,''),'[^0-9,.-]',''),
          ',', '.'
        ), ''
      ) AS DECIMAL(18,2)
    ),
    0.00
  ) AS valor_total,
  nullif(trim(r.revendedor_id),'') AS revendedor_id,
  CASE WHEN data_venda IS NULL OR cidade_std='DESCONHECIDO' THEN true ELSE false END AS needs_review
FROM parsed;

CREATE TABLE cotacoes_limpo AS
WITH base AS (
  SELECT row_number() OVER (ORDER BY _c0) AS rn, _c0 AS line
  FROM cotacoes
),
sem_header AS (
  SELECT line FROM base WHERE rn > 1
),
parsed AS (
  SELECT from_csv(
           regexp_replace(line,';+',','),
           'id_cotacao string,data_cotacao string,local_cotacao string,tipo_maquina string,revendedor_id string',
           map('delimiter',',')
         ) AS r
  FROM sem_header
)
SELECT
  r.id_cotacao,
  CASE
    WHEN r.data_cotacao RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN to_date(r.data_cotacao,'yyyy-MM-dd')
    WHEN r.data_cotacao RLIKE '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN to_date(r.data_cotacao,'dd/MM/yyyy')
    WHEN r.data_cotacao RLIKE '^[0-9]{2}/[0-9]{2}/[0-9]{2,4}$' THEN to_date(r.data_cotacao,'MM/dd/yyyy')
    ELSE NULL
  END AS data_cotacao,
  coalesce(fn_norm_cidade(nullif(trim(r.local_cotacao),'')),'DESCONHECIDO') AS cidade_std,
  nullif(trim(r.tipo_maquina),'') AS tipo_maquina,
  nullif(trim(r.revendedor_id),'') AS revendedor_id,
  CASE WHEN data_cotacao IS NULL OR cidade_std='DESCONHECIDO' THEN true ELSE false END AS needs_review
FROM parsed;

SELECT 'vendas_limpo' AS tabela, COUNT(*) AS total FROM vendas_limpo
UNION ALL
SELECT 'cotacoes_limpo' AS tabela, COUNT(*) AS total FROM cotacoes_limpo;
