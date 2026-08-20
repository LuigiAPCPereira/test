# Performance — Controle de Frotas Nordeste

## Diagnóstico confirmado

O DataMashup original mostrou 11 consultas carregadas:

- ConsultarFrotasNordeste
- SuasTrans
- MaxTrack
- Tableu
- CIV
- Crono
- CIPP
- TH
- Medidores
- Mássico
- CRLV

`CIV`, `Crono`, `CIPP`, `TH`, `Medidores`, `Mássico` e `CRLV` são filtros simples de `SuasTrans` via `FiltrarTidoDoc`.

`Medidores` no arquivo original filtra somente o documento 02.03 Termômetro; portanto não implementava a regra correta de Mano/Ter.

As quatro consultas-base também estavam configuradas com:

- atualização em segundo plano;
- atualizar ao abrir;
- intervalo automático de 60 minutos.

## Por que isso pesa

Consultas referenciadas não funcionam como cache persistente entre cargas independentes. Uma árvore pode ser reavaliada mais de uma vez durante o refresh.

Por isso o custo não está nas 57 placas ou 513 linhas finais; está principalmente em:

- enumeração de SharePoint;
- múltiplas cargas derivadas da mesma fonte;
- refresh automático concorrente/desnecessário;
- consultas de auditoria/visual que podem forçar novas avaliações.

## Otimizações já preparadas

### Medidor e Mano/Ter

Usam `SuasTrans` como fonte operacional e não consultam novamente `ConsultarFrotasNordeste`.

Isso também corrigiu o problema `Núcleo` x `NUCLEO` que fazia o medidor aparecer com núcleo nulo.

### AtualizacaoMae

Consolida em uma linha por placa:

- CIV
- Crono
- CIPP
- TH
- Medidor Mássico
- Mano/Ter
- Documento Mano/Ter mais próximo
- CRLV

Depois de validada, pode substituir as sete cargas documentais simples antigas.

### Camada visual

`ResumoOperacional` foi removida.

Os cartões da página Ações Operacionais devem usar fórmulas sobre `tbAcoesOperacionais`, evitando uma consulta Power Query adicional só para contagem.

### Auditoria

`QualidadeDados` e `ValidacaoMigracao_v2` devem ser usadas manualmente depois da estabilização, não como refresh pesado de rotina.

## SharePoint — caminhos confirmados

Teste728:

- `Documentos Compartilhados/Dados Suastrans`
- `Documentos Compartilhados/Dados MaxTrack`
- `Documentos Compartilhados/Dados Tableau`

Frotas:

- `Documentos Compartilhados/Manutenção e Disponibilidade`

## Estratégia SharePoint.Contents

A migração de menor risco não reescreve as consultas inteiras.

Foram criadas quatro consultas de fonte:

- `FonteSuasTrans_Contents`
- `FonteMaxTrack_Contents`
- `FonteTableu_Contents`
- `FontePlanilhaMae_Contents`

Cada uma chama `SharePoint.Contents` na URL do **site** e navega pela hierarquia `[Content]` até a pasta necessária.

Elas preservam `Folder Path` e `Extension` para que as transformações atuais possam continuar praticamente inalteradas.

A troca exata está em `MIGRACAO_SHAREPOINT_CONTENTS.md`.

## Próxima sequência de teste

1. criar as quatro fontes como somente conexão;
2. abrir cada uma e confirmar que mostra somente a pasta esperada;
3. trocar a origem de `ConsultarFrotasNordeste`;
4. trocar a origem de `SuasTrans`;
5. medir `SuasTrans`, `Medidor` e `ManoTer`;
6. trocar MaxTrack;
7. trocar Tableu;
8. validar `AtualizacaoMae`;
9. retirar as sete cargas documentais redundantes;
10. medir `Atualizar Tudo` novamente.

## Política de refresh alvo

Depois de estabilizar, o fluxo preferido é:

`adicionar novos exports -> Atualizar Tudo -> aguardar conclusão -> trabalhar`

Se esse fluxo atender o uso real, desativar:

- intervalo de 60 minutos;
- atualizar ao abrir, se não for necessário.

Manter apenas o refresh deliberado reduz atualizações inesperadas durante o trabalho.

## Como medir

Sempre na mesma rede/arquivo:

- SuasTrans isolada;
- Medidor isolado;
- ManoTer isolado;
- Atualizar Tudo;
- repetir após SharePoint.Contents;
- repetir após remover as sete cargas antigas.

O tempo relevante é o refresh normal do Excel, não apenas o preview do Editor do Power Query.

## Segurança

Não alterar níveis de privacidade corporativos para contornar `Formula.Firewall`.

Se o firewall aparecer, registrar consulta e etapa. O diagnóstico anterior mostrou que combinar sites diretamente numa consulta nova pode ativar a barreira de privacidade; por isso as fontes foram separadas por site/pasta.
