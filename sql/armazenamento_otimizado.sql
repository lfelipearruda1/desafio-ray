USE CATALOG workspace;
USE SCHEMA default;

DROP TABLE IF EXISTS dados_consolidados_delta;
CREATE TABLE dados_consolidados_delta
USING DELTA
PARTITIONED BY (origem)
AS
SELECT origem, id, data, cidade_std, tipo_maquina, revendedor_id, valor_total, needs_review
FROM dados_consolidados;

DROP TABLE IF EXISTS metricas_locais_delta;
CREATE TABLE metricas_locais_delta
USING DELTA
PARTITIONED BY (cidade_padronizada)
AS
SELECT *
FROM metricas_locais;

OPTIMIZE dados_consolidados_delta ZORDER BY (data, cidade_std);
OPTIMIZE metricas_locais_delta    ZORDER BY (qtd_vendas, total_vendas);

SELECT 'delta_consolidados' AS tabela, COUNT(*) AS linhas FROM dados_consolidados_delta
UNION ALL
SELECT 'delta_metricas'     AS tabela, COUNT(*) FROM metricas_locais_delta;

DESCRIBE DETAIL dados_consolidados_delta;
DESCRIBE DETAIL metricas_locais_delta;
