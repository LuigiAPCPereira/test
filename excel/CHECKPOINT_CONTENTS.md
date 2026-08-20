# Checkpoint — migração SharePoint.Contents

## Estado atual

Três consultas `Fonte..._Contents` já foram abertas no Excel e o preview funcionou sem erro.

A partir deste ponto, a migração deixa de ser apenas diagnóstico e passa a testar as consultas de negócio com **troca mínima da etapa de origem**.

## Primeiro bloco de substituição

### ConsultarFrotasNordeste

Na consulta existente, substituir apenas o bloco `SharePoint.Files(...)` da variável `Fonte` por:

```powerquery
Fonte = FontePlanilhaMae_Contents,
```

Não alterar nenhuma etapa posterior.

Aceite inicial:

- 57 linhas/placas da frota Nordeste;
- sem placa vazia;
- colunas `Placa`, `Frota`, `Proprietário`, `Mercado`, `Filial`, `Núcleo` preservadas.

Existe no repositório uma cópia completa de referência: `power-query/ConsultarFrotasNordeste_Contents.m`.

### SuasTrans

Na consulta existente, substituir somente:

```powerquery
Connect_SharePointSite = SharePoint.Files(
    "https://grupoultracloud.sharepoint.com/teams/Teste728",
    [ApiVersion = 15]
),
```

por:

```powerquery
Connect_SharePointSite = FonteSuasTrans_Contents,
```

As etapas posteriores permanecem intactas.

Aceite inicial:

- 57 placas quando a origem estiver completa;
- 9 tipos documentais;
- referência de 513 linhas para 57 x 9 no conjunto previamente analisado;
- `NUCLEO` sem nulos;
- datas/status iguais à consulta anterior.

### Medidor

Não alterar sua fonte. Ele continua derivando de `SuasTrans`.

Depois de atualizar a nova `SuasTrans`, atualizar **somente `Medidor`** e medir o tempo. Esse teste deve ser comparado com o comportamento anterior de aproximadamente 7 minutos.

Também conferir:

- uma linha por placa;
- `NUCLEO` preenchido;
- `Validade Medidor` corresponde ao 02.02;
- `Integridade = OK` quando a origem estiver íntegra.

## Segundo bloco

Se os três testes acima passarem:

1. substituir `MaxTrack` para `FonteMaxTrack_Contents`;
2. conferir KM/ODOMETRO e cobertura das placas;
3. testar a Preventiva Rodante;
4. somente depois migrar `Tableu` para `FonteTableu_Contents` quando essa fonte também estiver validada.

## Segurança

- trabalhar em cópia da pasta de trabalho;
- não alterar configurações corporativas de privacidade;
- não excluir as consultas antigas documentais ainda;
- se surgir `Formula.Firewall`, registrar a consulta e a etapa exata e parar aquela migração.
