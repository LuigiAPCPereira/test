# Parser completo de NF — Power Automate Desktop

Cole `NF_Parser_Completo_Apos_Extracao.robin` depois da ação `Extrair texto do PDF`. O fluxo deve já possuir `ExtractedPDFText`.

O bloco cria o objeto `NF` com: tipo do documento, número, série, data de emissão, empresa/CNPJ prestadora, empresa tomadora, valor e versões normalizadas para integração.

Ele cobre os dois formatos já observados no projeto:
- NF-e/DANFE;
- NFS-e de serviço.

O parser não inventa campos ausentes; retorna `StatusParser` e `CamposAusentes` para revisão.

A atualização automática do SharePoint ainda não está no bloco porque os nomes internos das colunas fiscais não foram confirmados. Eles não devem ser inferidos.