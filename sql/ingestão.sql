USE CATALOG workspace;
USE SCHEMA default;

DROP TABLE IF EXISTS vendas;
DROP TABLE IF EXISTS cotacoes;

CREATE TABLE vendas AS
SELECT * FROM csv.`/Volumes/workspace/default/desafio_ray/vendas_data.csv - Sheet1.csv`;

CREATE TABLE cotacoes AS
SELECT * FROM csv.`/Volumes/workspace/default/desafio_ray/cotacoes_data.csv - Sheet1.csv`;

SELECT 'vendas' AS tabela, COUNT(*) AS total_linhas FROM vendas
UNION ALL
SELECT 'cotacoes' AS tabela, COUNT(*) AS total_linhas FROM cotacoes;
