USE CATALOG workspace;
USE SCHEMA default;

DROP VIEW IF EXISTS workspace.default.vw_consolidados_norm;
CREATE VIEW workspace.default.vw_consolidados_norm AS
SELECT
  origem,
  id,
  data,
  CASE
    WHEN cidade_std IN ('S PAULO')       THEN 'SAO PAULO'
    WHEN cidade_std IN ('FLORIPA')       THEN 'FLORIANOPOLIS'
    WHEN cidade_std IN ('RIO')           THEN 'RIO DE JANEIRO'
    WHEN cidade_std IN ('BELO HORIZOTE') THEN 'BELO HORIZONTE'
    WHEN cidade_std IN ('LOCALVENDA','LOCALCOTACAO') THEN 'DESCONHECIDO'
    ELSE cidade_std
  END AS cidade_padronizada,
  tipo_maquina,
  revendedor_id,
  valor_total,
  needs_review
FROM workspace.default.dados_consolidados
WHERE id NOT IN ('id_venda','id_cotacao');

DROP TABLE IF EXISTS workspace.default.metricas_locais;
CREATE TABLE workspace.default.metricas_locais AS
WITH v AS (
  SELECT cidade_padronizada, COUNT(*) AS qtd_vendas, SUM(COALESCE(valor_total,0)) AS total_vendas
  FROM workspace.default.vw_consolidados_norm
  WHERE origem='VENDA'
  GROUP BY cidade_padronizada
),
c AS (
  SELECT cidade_padronizada, COUNT(*) AS qtd_cotacoes
  FROM workspace.default.vw_consolidados_norm
  WHERE origem='COTACAO'
  GROUP BY cidade_padronizada
)
SELECT
  COALESCE(v.cidade_padronizada,c.cidade_padronizada) AS cidade_padronizada,
  COALESCE(v.qtd_vendas,0) AS qtd_vendas,
  COALESCE(v.total_vendas,0) AS total_vendas,
  COALESCE(c.qtd_cotacoes,0) AS qtd_cotacoes,
  CASE WHEN COALESCE(c.qtd_cotacoes,0)>0
       THEN ROUND(COALESCE(v.qtd_vendas,0) / c.qtd_cotacoes,4)
       ELSE NULL END AS taxa_conversao
FROM v
FULL OUTER JOIN c ON v.cidade_padronizada=c.cidade_padronizada;

SELECT * FROM workspace.default.metricas_locais ORDER BY total_vendas DESC;
