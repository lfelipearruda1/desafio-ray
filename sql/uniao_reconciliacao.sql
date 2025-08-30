USE CATALOG workspace;
USE SCHEMA default;

DROP TABLE IF EXISTS workspace.default.dados_consolidados;

CREATE TABLE workspace.default.dados_consolidados AS
SELECT 'VENDA' AS origem,
       id_venda AS id,
       data_venda AS data,
       cidade_std,
       tipo_maquina,
       revendedor_id,
       valor_total,
       needs_review
FROM workspace.default.vendas_limpo
UNION ALL
SELECT 'COTACAO' AS origem,
       id_cotacao AS id,
       data_cotacao AS data,
       cidade_std,
       tipo_maquina,
       NULL AS revendedor_id,
       NULL AS valor_total,
       needs_review
FROM workspace.default.cotacoes_limpo;

SELECT origem, COUNT(*) AS qtd
FROM workspace.default.dados_consolidados
GROUP BY origem;

SELECT *
FROM workspace.default.dados_consolidados
ORDER BY origem, data DESC
