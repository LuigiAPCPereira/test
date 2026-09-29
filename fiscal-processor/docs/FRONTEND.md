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


## Gate gráfico obrigatório na CI — 2026-09-29
`tests/test_desktop_tk.py` separa testes reais de widgets dos read models.
`FISCAL_REQUIRE_DISPLAY=1` faz ausência de Tk/display falhar explicitamente.
A CI prepara Xvfb/xauth no Linux e usa `xvfb-run`; Windows exige Tk diretamente.
Não foi disparado rerun manual: cobrança da conta continua bloqueando jobs.

Cenários preparados, ainda NÃO executados: Tab da seleção para processamento;
botões desabilitados durante o lote; PDF sintético real até a tabela e Excel;
vazio; fechar/cancelar sem destruir janela durante trabalho; falha de workbook
com manutenção de linhas úteis e orientação contextual. Isso não substitui
inspeção visual, leitor de tela ou escala de texto.

Tentativas locais: apt falhou por restrições de setgroups/seteuid. Extração
isolada de Xvfb Debian 21.1.7 com hashes SHA-256 verificados evitou instalação
no sistema, mas Xvfb não conseguiu criar sockets locais. Não há display utilizável
neste ambiente. Não repetir a instalação aqui como se fosse apenas pacote ausente.

Validação atual: 128 PASS e 6 skips (cinco Tk, um OCR). Teste negativo com
FISCAL_REQUIRE_DISPLAY=1 falhou no setup com a mensagem esperada de display
obrigatório indisponível. Gate preparado não equivale a interface validada.


## Harness de QA visual sintético — 2026-09-29
`tools/visual_qa.py` prepara estados determinísticos sem PDFs empresariais, sem OCR
e sem rede: initial, selected, processing, empty, success, partial, error,
cancelled e long. A janela identifica explicitamente `QA VISUAL SINTÉTICO`;
o arquivo XLSX criado para os estados de sucesso é temporário e contém somente
dados sintéticos.

Após instalar o ambiente de desenvolvimento, executar por exemplo:

```sh
python tools/visual_qa.py partial
python tools/visual_qa.py long --scale 2.0 --geometry 760x540
```

O harness serve para inspecionar hierarquia, foco visível, Tab, nomes longos,
scroll, mensagens, 200% de escala e os estados em um display real. Ele não entra
no wheel/runtime do produto e não substitui os testes Tk nem a inspeção renderizada.
FP-008 permanece parcial até essa evidência existir.

Correção associada: término sem nenhuma linha agora mostra
`Não há itens concluídos para detalhar.`, em vez de orientar a selecionar um
item inexistente. O teste Tk de pasta vazia protege esse comportamento.


## Gate gráfico executado em CI — 2026-09-29
Após o bloqueio externo de cobrança deixar de impedir os jobs, o workflow foi
reexecutado com o gate de display obrigatório. No run `36566933575`, revisão
`638bae3f03f804e047a21a3794e95325fff9ff37`, Ubuntu 24.04 e Windows Server
2022 concluíram com sucesso: 133 testes PASS e 1 skip em cada sistema. O skip
foi exclusivamente o smoke OCR, pois os modelos locais não são provisionados
na CI. Os cinco testes reais de widgets Tk executaram — não foram ignorados —
e passaram nos dois ambientes. Ruff check, Ruff format --check, mypy,
compileall e build wheel também passaram.

Depois dos registros documentais do resultado, o run `36573200114` revalidou
o HEAD `a5835e62d07a6f93eb0353e3d9d0e14bed3c6ad7` em Ubuntu e Windows, incluindo
o mesmo gate Tk. Isso comprova execução automatizada cross-platform da interface,
mas não substitui inspeção visual humana de contraste, escala 200%, recorte,
conteúdo longo, leitor de tela ou qualidade de composição. O harness
`tools/visual_qa.py` continua sendo a próxima evidência para encerrar FP-008.
