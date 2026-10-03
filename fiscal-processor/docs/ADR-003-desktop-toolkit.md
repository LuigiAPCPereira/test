# ADR-003 — Tkinter/ttk provisório para a primeira interface

Data: 2026-09-29. Estado: decisão de implementação provisória; gate visual aberto.

A tarefa é escolher uma pasta, acompanhar processamento local e revisar o Excel.
Usar Tkinter/ttk permite reutilizar Python sem servidor/webview ou nova dependência
Python obrigatória. Isto não demonstra menor bundle, melhor acessibilidade ou
compatibilidade Windows: medir antes de consolidar a escolha. PySide6 e pywebview
continuam alternativas caso os gates visuais/acessíveis não sejam atendidos.

Uma janela com seleção de pasta, ação de processamento, cancelamento, tabela e
abertura da planilha. Worker sequencial fora do loop de eventos; comunicação por
Queue, widgets apenas na thread principal. Sem rede, downloads ou logs fiscais
adicionados. Campos da tabela são dados locais, não dados de demonstração.

Cancelamento é observado antes do próximo documento e nunca interrompe save.
O processamento de uma página longa ainda pode atrasar cancelamento; sem timeout
forçado nesta fatia. CLI e desktop usam o mesmo composition root de extração.

Fonte técnica consultada: https://docs.python.org/3/library/tkinter.html
(Threading model). Ambiente atual importa Tk 9.0, mas não abre janela porque não
há DISPLAY/servidor gráfico. Sem evidência renderizada, FP-008 não está concluída.

Gate seguinte: renderizar estados inicial/vazio/parcial/erro e resultados com
nomes longos; verificar teclado/foco/escala e fechar/cancelar; medir bundle e
startup no Windows antes de distribuir para o PC corporativo.
