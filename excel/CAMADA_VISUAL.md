# Camada Visual — Controle de Frotas Nordeste

Objetivo: operação rápida, pouca duplicação e nenhum Power Query criado apenas para alimentar cartões.

## 1. Ações Operacionais

Carregar `AcoesOperacionais` como tabela `tbAcoesOperacionais`, iniciando aproximadamente em `A9`.

### Topo

- `A1:M1` — **CONTROLE OPERACIONAL — FROTAS NORDESTE**
- `A2:M2` — **Atualize os dados e filtre somente o que exige ação**

### Cartões

Os cartões devem usar **a própria tabela carregada**, sem `ResumoOperacional` e sem aba `_Apoio`. Isso evita uma nova avaliação de `AcoesOperacionais` durante o refresh.

Sugestão:

- `A4:B6` — AÇÕES PENDENTES
- `C4:D6` — URGENTES
- `E4:F6` — FECHAR NO MÁXIMO
- `G4:H6` — COBRAR MECÂNICA
- `I4:J6` — DOC. VENCIDOS
- `K4:L6` — PREVENTIVAS

Fórmulas conceituais em Excel PT-BR:

```excel
=LINHAS(tbAcoesOperacionais[PLACA])
=CONT.SE(tbAcoesOperacionais[PRIORIDADE];"URGENTE")
=CONT.SE(tbAcoesOperacionais[AÇÃO];"FECHAR NO MÁXIMO")
=CONT.SE(tbAcoesOperacionais[AÇÃO];"COBRAR MECÂNICA")
=CONT.SE(tbAcoesOperacionais[AÇÃO];"REGULARIZAR DOCUMENTO")
=CONT.SE(tbAcoesOperacionais[AÇÃO];"PROGRAMAR PREVENTIVA")+CONT.SE(tbAcoesOperacionais[AÇÃO];"TRATAR PREVENTIVA")
```

Esses cartões mostram o total geral da fila. Os segmentadores controlam a tabela operacional; não criar outra consulta apenas para fazer os cartões reagirem ao filtro.

### Colunas visíveis

1. PRIORIDADE
2. NUCLEO
3. PLACA
4. FROTA
5. CATEGORIA
6. ITEM
7. SITUAÇÃO
8. AÇÃO
9. DATA
10. DIAS
11. KM RESTANTE
12. REFERÊNCIA
13. INTEGRIDADE

Colunas técnicas como `ORDEM GERAL`, `ORIGEM` e `MÉTRICA DIAS` podem ficar no final/ocultas.

### Segmentadores

No máximo seis:

- NUCLEO
- PRIORIDADE
- CATEGORIA
- AÇÃO
- MÊS-ANO
- PLACA

### Formatação

- URGENTE → destaque forte;
- AÇÃO → destaque médio;
- ATENÇÃO → destaque leve;
- MONITORAR → neutro;
- `INTEGRIDADE <> OK` → sempre destacar.

Sem gráficos decorativos.

## 2. Preventiva Rodante

Página detalhada própria.

Colunas principais:

- Placa
- Frota
- Núcleo
- KM Atual
- KM Últ. Prev.
- KM Próx. Prev.
- KM Restante
- Faixa KM
- Data Próx. Prev.
- Dias para a data
- Situação Geral
- Integridade

Segmentadores:

- Núcleo
- Situação Geral
- Faixa KM
- Mês-Ano
- Integridade
- Placa

Maior destaque visual em `KM Restante`, `Data Próx. Prev.` e `Situação Geral`.

## 3. SuasTrans

Manter a página atual porque ela já é usada nos filtros e prints operacionais.

`DocumentosOperacionais` fica somente como consulta auxiliar de `AcoesOperacionais`; não precisa de página própria.

## 4. OS Operacional

Durante a validação, comparar com a página `Tableu` atual.

Depois:

- consulta `Tableu` continua existindo como staging;
- carga/aba `Tableu` pode ser retirada;
- `OSOperacional` vira a página visível.

Nunca excluir a consulta `Tableu` enquanto `OSOperacional` depender dela.

Segmentadores:

- NUCLEO
- AÇÃO OPERACIONAL
- STATUS
- RECORRENCIA
- PERÍODO
- PLACA

Ação deve ficar próxima do status:

- COMP → FECHAR NO MÁXIMO
- APROG → COBRAR MECÂNICA
- FECHAR → SEM AÇÃO

## 5. Atualização Mãe

Página única para PROCV/XLOOKUP após validação.

Ordem:

1. Placa
2. Frota
3. NUCLEO
4. Filial
5. CIV
6. Crono
7. CIPP
8. TH
9. Medidor
10. Mano/Ter
11. Documento Mano/Ter mais próximo
12. CRLV
13. Integridade
14. Documentos faltantes
15. Documentos duplicados

Segmentadores úteis:

- NUCLEO
- Documento Mano/Ter mais próximo
- Integridade
- Placa

`Documento Mano/Ter mais próximo` permite filtrar quem está sendo limitado por Termômetro, Manômetro Vertical ou Manômetro Horizontal, enquanto a data usada no PROCV continua sendo a coluna `Mano/Ter`.

Após comparação, essa página pode substituir como fonte de atualização as sete cargas simples antigas:

- CIV
- Crono
- CIPP
- TH
- Medidores
- Mássico
- CRLV

## 6. Mano-Ter e Medidor

Manter durante a validação.

Depois são opcionais: `Atualização Mãe` já contém os dois resultados e a origem do Mano/Ter.

Se deixarem de agregar valor visual, não carregar essas páginas reduz duplicação e refresh.

## 7. Qualidade dos Dados

Página de exceções, não dashboard.

Por performance, recomenda-se **não atualizar automaticamente a cada abertura/Atualizar Tudo** depois da estabilização. Usar quando houver suspeita de problema, mudança de layout das fontes ou auditoria.

Segmentadores opcionais:

- Gravidade
- Origem
- NUCLEO

## 8. Validação de Migração

`ValidacaoMigracao_v2` também é consulta manual. Não deve entrar no refresh normal diário.

Ela serve para conferir cobertura de placas, documentos, KM, núcleo e integridade depois de mudanças estruturais.

## 9. Estrutura final preferida

Páginas principais:

1. Ações Operacionais
2. Preventiva Rodante
3. SuasTrans
4. OS Operacional
5. Atualização Mãe
6. Qualidade dos Dados

Páginas opcionais durante transição:

- Mano-Ter
- Medidor

Consultas de fonte/staging sem página:

- FontePlanilhaMae_Contents
- FonteSuasTrans_Contents
- FonteMaxTrack_Contents
- FonteTableu_Contents
- ConsultarFrotasNordeste
- Tableu
- DocumentosOperacionais

## 10. Princípio de performance

Não criar consultas Power Query quando uma fórmula simples na tabela já resolve o visual.

O refresh caro deve ser reservado para buscar/transformar dados; contadores e apresentação ficam no Excel.
