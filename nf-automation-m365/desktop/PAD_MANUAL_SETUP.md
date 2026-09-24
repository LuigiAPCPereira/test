# Configuração manual do parser no Power Automate Desktop

## Motivo
O PAD do tenant reconhece a ação visual **Executar script do PowerShell**, mas o importador Robin dessa instalação não reconhece os identificadores internos testados (`Scripting.RunPowershellScript` e `System.RunPowershellScript`). Por isso o parser deve ser montado usando a ação nativa pelo designer.

## Pré-requisito
O fluxo já deve ter:
1. **Exibir caixa de diálogo de seleção de arquivos** → `SelectedFile`
2. **Extrair texto do PDF** → `ExtractedPDFText`

## Montagem
3. Adicione **Área de transferência → Definir texto da área de transferência**.
   - Texto: `%ExtractedPDFText%`

4. Adicione manualmente **Criação de scripts → Executar script do PowerShell**.
   - Cole o conteúdo integral de `NF_Parser_Completo.ps1`.
   - Saída do PowerShell: renomeie para `ParserJson`.
   - Saída de erro: mantenha/renomeie para `ParserError`.

5. Adicione **Área de transferência → Limpar área de transferência**.

6. Adicione **Variáveis → Converter JSON em objeto personalizado**.
   - JSON: `%ParserJson%`
   - Objeto personalizado produzido: `NF`

7. Adicione **Caixas de mensagens → Exibir mensagem** com:
```
Status: %NF.StatusParser%
Tipo: %NF.TipoDocumento%
Número NF: %NF.NumeroNF%
Série: %NF.Serie%
Data emissão: %NF.DataEmissao%
Empresa prestadora: %NF.EmpresaPrestadora%
CNPJ prestadora: %NF.CNPJPrestadora%
Empresa tomadora: %NF.EmpresaTomadora%
Valor: %NF.ValorLiquido%
Campos ausentes: %NF.CamposAusentes%
Erro: %NF.Erro%
```

## Estado dos arquivos Robin
Os arquivos `NF_Parser_Completo_Apos_Extracao*.robin` permanecem apenas como histórico de tentativa de portabilidade e **não devem ser usados nesta instalação do PAD**.
