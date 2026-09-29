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

Tkinter/ttk adotado provisoriamente para a primeira fatia (ADR-003).
A decisão final depende de renderização, acessibilidade e bundle Windows medidos.

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



## Implementação inicial — FP-008
Tese visual: utilitário de revisão documental, com título compacto, pasta e ação
primária no topo, progresso sem ETA e tabela como superfície principal. Widgets
temáticos nativos; sem decoração adicional ou informações de engine na tela.

`presentation.desktop` usa o batch existente por worker thread e fila. Tk é
atualizado somente na thread principal. `state` prepara mensagens e linhas de
resultado sem acessar adapters. Cancelamento cooperativo entre documentos;
fechar durante trabalho solicita cancelamento e mantém a janela aberta até o
worker concluir (fechar novamente após conclusão).

Resultados locais mostram arquivo/tipo/número/valor/situação somente após save.
Duplicatas mostram valores não reavaliados como travessão. Falhas e revisões
mantêm resultados úteis na tabela. A planilha fica na pasta de entrada; o botão
para abri-la só é habilitado fora do processamento quando o arquivo existe.

Validação: 128 testes PASS, 2 skips (Tk sem display e OCR sem modelos). Testados
estados/read models, worker real PDF→Excel, cancelamento e falhas de descoberta.
**Não validado:** renderização, foco/teclado reais, contraste, escala 200%, nomes
longos, leitor de tela, abertura por associação do SO, tamanho/startup do bundle
ou execução Windows. O smoke Tk incluído verificará controles iniciais quando
houver display. FP-008 permanece parcial, sem alegação de qualidade visual pronta.
