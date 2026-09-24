# Arquitetura — v0.3

## Fluxos
1. Cloud automático: gatilho SharePoint a cada 5 min -> PDF -> buscar por ID do arquivo -> obter conteúdo -> criar item se ausente.
2. Cloud imediato: “Para um arquivo selecionado” -> propriedades -> PDF -> buscar por ID -> obter conteúdo -> criar se ausente.
3. Desktop (próximo marco): selecionar/varrer PDF local -> extrair texto -> parsear campos fiscais -> localizar/criar registro -> atualizar apenas campos fiscais.

## Invariantes
- SharePoint é a fonte de controle compartilhada.
- O identificador do arquivo protege contra duplicidade do mesmo documento.
- CNPJ + número + série será a segunda chave de deduplicação depois que a extração fiscal existir.
- OS/validade/observações pertencem ao usuário e não são sobrescritas pelos fluxos de intake.
- Connection reference carrega vínculo; credencial não é embutida no pacote.
