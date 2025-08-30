USE CATALOG workspace;
USE SCHEMA default;

DROP TABLE IF EXISTS dados_consolidados_delta;
CREATE TABLE dados_consolidados_delta
USING DELTA
AS
SELECT origem, id, data, cidade_std, tipo_maquina, revendedor_id, valor_total, needs_review
FROM dados_consolidados;

DROP TABLE IF EXISTS metricas_locais_delta;
CREATE TABLE metricas_locais_delta
USING DELTA
AS
SELECT * FROM metricas_locais;

OPTIMIZE dados_consolidados_delta ZORDER BY (data, cidade_std);
OPTIMIZE metricas_locais_delta    ZORDER BY (cidade_padronizada);

SELECT 'dados_consolidados_delta' AS tabela, COUNT(*) AS linhas FROM dados_consolidados_delta
UNION ALL
SELECT 'metricas_locais_delta'    AS tabela, COUNT(*) AS linhas FROM metricas_locais_delta;
