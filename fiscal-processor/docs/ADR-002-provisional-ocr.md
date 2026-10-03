# ADR-002 — OCR provisório e validação corporativa após pacote portátil

Data: 2026-09-28. Estado: aceito pelo usuário nesta conversa.

## Contexto
O usuário informou que os testes representativos ocorrerão no PC da empresa,
sem Python instalado. Não dispõe de PDFs equivalentes no computador pessoal.
Exigir agora o harness Python e gabaritos bloqueia a implementação sem oferecer
um caminho de teste utilizável. Evidência sintética disponível: RESEARCH-003/004.

## Decisão
Usar RapidOCR + PP-OCRv6 small + ONNX Runtime como escolha provisória da POC.
Prosseguir FP-005 → FP-007 → FP-008 → FP-009. FP-004 continua parcialmente
validada; sua validação representativa passa a ocorrer com o pacote Windows,
junto a FP-010/FP-011. Não condiciona mais o início dos parsers.
O pacote deve conter runtime e modelos locais, sem instalação de Python,
sem download em execução e sem privilégios administrativos no caminho nominal.
O usuário testará pelo fluxo do aplicativo com PDFs autorizados no PC da empresa.
O harness permanece ferramenta de desenvolvimento opcional.

## Referência visual
Foto fornecida pelo usuário mostra NFS-e de Teresina: cabeçalho com data/hora e
Número/Série combinados, seções separadas de prestador e tomador com labels
repetidos, cálculo do ISSQN e valor líquido em outra seção. Isso exige contexto
de seção para CNPJ/nome e distinção entre valor total, base tributária e líquido.
Anotações manuscritas não autorizam preencher campos manuais OS/validade/observações.
Usar somente a estrutura para fixtures totalmente sintéticas. Não versionar foto,
identificadores ou valores reais. Observação visual não é teste da engine OCR
nem prova de suporte geral às notas municipais. Entrada JPEG não entra no escopo
por causa desta referência; o produto continua orientado a PDFs.

## Consequências
Qualidade em layouts reais, compatibilidade Windows, execução sem admin e
políticas corporativas continuam não comprovadas. Campos ausentes/ambíguos
exigem revisão. A escolha de engine pode mudar com evidência local posterior.
