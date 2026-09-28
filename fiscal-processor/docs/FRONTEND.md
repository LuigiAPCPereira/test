# Frontend — contrato de produto v0.1

## Tarefa principal

O usuário quer transformar uma pasta de PDFs em uma planilha confiável e saber rapidamente quais documentos precisam de revisão.

## Hierarquia

1. Pasta selecionada.
2. Ação primária: **Processar notas fiscais**.
3. Progresso real do lote.
4. Resultado: processadas / revisar / falharam.
5. Tabela escaneável de documentos.
6. Ação secundária: **Abrir planilha**.

Não exibir conta, runtime, tecnologia OCR, telemetria ou detalhes internos como informação principal.

## Composição proposta

```text
┌ Fiscal Processor ────────────────────────────────────┐
│ Pasta: C:\...\Notas Fiscais               [Alterar] │
│ Nenhum arquivo sai deste computador.                │
│                                                     │
│ [ Processar notas fiscais ]                         │
│                                                     │
│ Progresso  12 de 20  ━━━━━━━━━━━━━━━                │
│                                                     │
│ 9 processadas   2 revisar   1 falhou                │
│ ─────────────────────────────────────────────────── │
│ Arquivo       Tipo   NF       Valor      Situação   │
│ ...                                                 │
│                                                     │
│ [Abrir planilha]                                    │
└─────────────────────────────────────────────────────┘
```

O desenho é informacional, não uma exigência visual pixel-perfect.

## Estados

### Initial
- pasta ainda não escolhida;
- CTA disponível após seleção válida.

### Empty
- pasta válida, nenhum PDF encontrado;
- informar ausência sem tratar como erro.

### Processing
- mostrar arquivo atual e progresso conhecido;
- não inventar ETA;
- permitir cancelamento somente quando seguro.

### Success
- lote terminou sem itens pendentes;
- mostrar contagem e caminho da planilha.

### Partial / Review
- dados úteis existem, mas um ou mais documentos precisam de revisão;
- manter resultados válidos visíveis.

### Error
- distinguir erro do documento de erro do lote;
- dizer o que ocorreu e a ação possível;
- nunca mostrar stack trace.

### Excel locked
- explicar que a planilha está aberta/bloqueada;
- preservar todos os dados já existentes;
- permitir repetir save/processamento com segurança.

## Acessibilidade

- navegação por teclado e foco visível;
- controles com rótulos textuais;
- status não depende apenas de cor;
- contraste AA;
- escala de texto/zoom preserva tarefa;
- ações importantes com área confortável;
- mensagens de erro ligadas ao item relevante.

## Linguagem visual

- utilitário desktop, denso quando necessário;
- tipografia e espaçamento antes de bordas;
- tabela real para dados tabulares;
- poucos containers;
- sem glassmorphism, gradientes decorativos ou sombras em todo bloco;
- cor usada semanticamente;
- light/dark somente se o toolkit suportar sem aumentar muito a complexidade.

## Toolkit

Ainda não decidido.

Candidatos para spike:
- UI nativa Python simples;
- pywebview/WebView2;
- PySide6.

A escolha deve medir:
- tamanho do bundle;
- cold start;
- acessibilidade;
- fidelidade visual;
- dependências/licença;
- comportamento sem privilégio administrativo.

A arquitetura do core não dependerá dessa escolha.
