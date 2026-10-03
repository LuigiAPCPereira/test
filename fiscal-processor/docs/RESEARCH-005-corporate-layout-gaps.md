# RESEARCH-005 — lacunas de layout observadas no smoke corporativo

Data: 2026-09-29. Estado: evidência parcial; reteste requerido.

## Regra de privacidade
Nenhum documento fiscal, nome de arquivo, valor, identificador, CNPJ ou texto
extraído real é armazenado aqui. Esta nota registra apenas classes estruturais
observadas pelo usuário e resultados sanitizados.

## Observações
1. Um PDF com camada visual/textual inadequada terminou em revisão/layout não
   suportado. O usuário indicou que a leitura pela imagem é mais apropriada para
   esse formato.
2. Um DANFE/NF-e teve o tipo reconhecido, mas os campos visíveis no workbook não
   foram preenchidos corretamente. A captura mostra `MISSING_AMOUNT`, mas não
   permite reconstruir o objeto intermediário; não atribuir a causa ao Excel sem
   nova evidência.

## Hipóteses testadas
- Texto nativo longo/imprimível pode satisfazer a heurística inicial mesmo sem
  estrutura fiscal suficiente, impedindo OCR.
- O baseline espacial era estreito: valor apenas abaixo do rótulo, alinhado em X.
  Layouts DANFE podem posicionar valores na mesma linha e repetem Nº/Série.
- O adapter Excel foi revalidado com todas as colunas automáticas principais e
  persiste os valores quando o domínio os fornece.

## Mudança
`extract_and_parse` agora tenta parse nativo primeiro e só faz retry OCR local
quando o resultado fica em REVIEW por layout não suportado ou campo obrigatório
ausente. O resultado OCR só substitui o primeiro quando melhora uma ordenação
determinística de tipo reconhecido, quantidade de campos preenchidos e flags.
Falha do retry preserva o REVIEW original.

O parser espacial aceita associação horizontal apenas quando a sintaxe é
compatível com o campo; não usa texto arbitrário como valor. Foram adicionados
aliases/seções observáveis no DANFE oficial e tratamento de Nº/Série repetidos
com valores idênticos.

## Referência externa
Portal Nacional da NF-e, MOC 7.0 — Anexo de especificações do DANFE:
https://www.nfe.fazenda.gov.br/portal/exibirArquivo.aspx?conteudo=f+NhsSn3%2F5M%3D

A referência oficial mostra DANFE, Nº, SÉRIE, identificação do emitente,
DESTINATÁRIO / REMETENTE, DATA DA EMISSÃO e VALOR TOTAL DA NOTA, entre outros.

## Evidência automatizada
Commit candidato: `74047e2a87d3bb6d72e4cbf0799f3e3be6cbf460`.
Run: `36584471585`.
Ubuntu: 137 PASS, 1 skip.
Windows: 137 PASS, 1 skip.
Job portátil + smoke sem Python no PATH: PASS.
Artefato: `FiscalProcessor-windows-x64.zip`, ID 11041063334.
SHA-256: `76bef9b697c9b486e8444e151649839f77d4def499b8779fd49b1f191e39ad5f`.

## Limite
A mudança é candidata, não prova suporte aos dois documentos reais. O mesmo
smoke corporativo precisa ser repetido com reprocessamento explícito; se ainda
falhar, capturar somente estados/flags/estrutura necessários, sem versionar dados
fiscais.
