# Padrão global de colunas

Para todas as tabelas operacionais/visíveis que possuam esses campos, a identificação deve aparecer sempre nesta ordem:

1. `NUCLEO` / `Núcleo`
2. `FILIAL` / `Filial`
3. `PLACA` / `Placa`

Depois dessas três, todas as demais colunas preservam a ordem funcional já definida para cada consulta.

A regra vale para:

- ConsultarFrotasNordeste
- SuasTrans
- Preventiva Rodante
- Mano/Ter
- Medidor
- Documentos Operacionais
- OS Operacional
- Ações Operacionais
- Atualização Mãe
- Qualidade dos Dados quando houver os três campos

Consultas de staging `Fonte..._Contents` não precisam obedecer a essa ordem, porque não são páginas operacionais.

A mudança é exclusivamente visual/estrutural: nenhuma regra de cálculo, filtro, merge, status ou priorização deve ser alterada por causa da reordenação.
