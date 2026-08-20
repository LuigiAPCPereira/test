# Migração SharePoint.Contents — caminho de baixo risco

## Por que mudou a abordagem

Os `Folder Path` reais foram confirmados no Excel. A migração agora preserva as consultas atuais e troca **somente a etapa de origem**.

A função `SharePoint.Contents` recebe a URL do **site** e a navegação segue pela coluna `[Content]` até a biblioteca/pasta desejada. Por isso foram criadas quatro consultas de fonte pequenas, em vez de reescrever toda a lógica de SuasTrans, MaxTrack, Tableau e frota.

## Consultas de fonte

Criar como **Somente Criar Conexão**:

- `FontePlanilhaMae_Contents`
- `FonteSuasTrans_Contents`
- `FonteMaxTrack_Contents`
- `FonteTableu_Contents`

Cada consulta navega somente até a pasta necessária e devolve uma tabela compatível com os campos usados pelas consultas antigas, incluindo `Folder Path` e `Extension` quando o conector não os fornecer diretamente.

## Ordem de validação

### 1. Testar as quatro fontes sozinhas

Abra cada consulta no Editor do Power Query.

Esperado:

- `FontePlanilhaMae_Contents` → arquivos existentes somente em `Manutenção e Disponibilidade`;
- `FonteSuasTrans_Contents` → arquivos somente de `Dados Suastrans`;
- `FonteMaxTrack_Contents` → arquivos somente de `Dados MaxTrack`;
- `FonteTableu_Contents` → arquivos somente de `Dados Tableau`.

Se aparecer `Biblioteca não encontrada` ou `Pasta não encontrada`, não altere privacidade/credenciais: registrar o nome mostrado pelo navegador do Power Query e ajustar o segmento de navegação.

### 2. ConsultarFrotasNordeste

Na consulta existente, substituir apenas:

```powerquery
Fonte = SharePoint.Files(
    "https://grupoultracloud.sharepoint.com/teams/UG-ExcelnciaemFrotas",
    [ApiVersion = 15]
),
```

por:

```powerquery
Fonte = FontePlanilhaMae_Contents,
```

Não mudar nenhuma etapa posterior.

Validar:

- mesma quantidade de veículos da versão anterior;
- placas sem duplicidade;
- `F18736`, `F18746` e `F18748` continuam presentes enquanto permanecerem na planilha mãe;
- nenhuma coluna esperada desapareceu.

### 3. SuasTrans

Substituir somente:

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

O filtro atual que procura `Dados Suastrans` pode permanecer porque a fonte otimizada mantém uma coluna `Folder Path` compatível.

Validar:

- mesma quantidade de placas da frota Nordeste;
- 9 tipos documentais por placa quando a origem estiver completa;
- `NUCLEO`, `Filial`, `Placa`, `Frota`, `Tipo de Documento`, `Validade`, `Mês-Ano` e `Status` preservados.

### 4. Medidor e Mano/Ter

Não mudar a origem deles. Eles continuam derivando de `SuasTrans`.

Após atualizar a nova SuasTrans, medir:

- tempo de atualização do `Medidor`;
- tempo de atualização do `ManoTer`;
- se `NUCLEO` deixou de ficar nulo;
- integridade e quantidade de linhas.

### 5. MaxTrack

Substituir somente o bloco `SharePoint.Files` de `Connect_SharePointSite` por:

```powerquery
Connect_SharePointSite = FonteMaxTrack_Contents,
```

Validar:

- mesmas placas da frota Nordeste;
- ausência de duplicidade por placa;
- odômetro continua em KM inteiro;
- nenhuma placa da frota oficial fica sem KM por causa da migração.

### 6. Tableu

Substituir somente o bloco `SharePoint.Files` de `Connect_SharePointSite` por:

```powerquery
Connect_SharePointSite = FonteTableu_Contents,
```

Validar:

- filtros originais permanecem (`FILIAL = 34`, tipo `GP` e cruzamento com frota Nordeste);
- status `APROG`, `COMP` e `FECHAR` continuam iguais ao resultado antigo;
- `OSOperacional` atualiza sem alteração de regra.

### 7. Preventiva Rodante

Na versão atual da `PreventivaRodante`, substituir a enumeração ampla da planilha mãe por:

```powerquery
FonteMae = FontePlanilhaMae_Contents,
```

Manter as etapas posteriores que selecionam `Programações Paradas Frotas.xlsm`.

## Depois que tudo bater

Aí sim fazer a segunda otimização:

1. validar `AtualizacaoMae`;
2. retirar as cargas redundantes de `CIV`, `Crono`, `CIPP`, `TH`, `Medidores`, `Mássico` e `CRLV`;
3. deixar `Tableu` como staging/somente conexão após validar `OSOperacional`;
4. desativar refresh automático de 60 minutos se o fluxo operacional for `adicionar exportações → Atualizar Tudo → trabalhar`;
5. medir novamente o tempo total.

## Regra de segurança

Não alterar configurações corporativas de privacidade para fazer a migração funcionar. Se surgir `Formula.Firewall`, registrar em qual consulta/etapa ocorreu antes de qualquer mudança de credencial ou nível de privacidade.
