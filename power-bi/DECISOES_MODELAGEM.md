# Decisões de Modelagem — Power BI Controle de Frotas Nordeste

## Documentos — política de colunas

Registrado em 2026-09-01 durante a validação do Gate 2C.

A camada de staging detalhada pode preservar temporariamente campos da origem que sejam úteis para auditoria e investigação, mesmo quando não houver uso analítico definido.

Exemplos atuais vindos do SuaTrans:

- `Nº Chamado`;
- `Ação`;
- `Responsável`;
- `Restritivo`;
- outros campos operacionais da origem.

Esses campos **não devem ser promovidos automaticamente para `FactDocumentos`** e não devem permanecer em uma camada canônica/model-facing apenas porque existem na fonte.

Regra adotada:

1. `stg_SuaTransRaw`: preserva a estrutura necessária para rastreabilidade e diagnóstico;
2. `stg_Documentos`: pode manter campos adicionais enquanto o comportamento da origem ainda estiver sendo investigado;
3. `stg_DocumentosAuditoria`: mantém apenas o necessário para diagnosticar multiplicidade/qualidade;
4. `stg_DocumentosCorrentes`: deve ser enxugada antes da criação de `FactDocumentos`, removendo campos sem finalidade analítica ou de rastreabilidade comprovada;
5. `FactDocumentos`: conterá somente chaves, atributos factuais e metadados estritamente necessários ao modelo e à auditoria de qualidade.

A presença temporária de uma coluna no staging **não implica** que ela fará parte do modelo final.

## Gate 2C.4 — Documentos correntes

Validado no Power BI Desktop em 2026-09-01.

Resultado:

- `stg_DocumentosCorrentes` abriu sem erro;
- a seleção canônica funcionou;
- a granularidade pretendida é uma linha por `Placa + Tipo de Documento`;
- duplicidades entre filiais continuam rastreáveis pelas colunas de auditoria;
- o staging corrente está apto a servir de base para a futura `FactDocumentos`, após enxugamento das colunas model-facing.
