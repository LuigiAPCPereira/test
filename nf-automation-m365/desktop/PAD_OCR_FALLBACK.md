# PAD — Fallback OCR para PDFs sem camada de texto

## Objetivo
Usar `Extrair texto do PDF` como caminho rápido. Se `ExtractedPDFText` vier vazio, executar OCR local e depois reutilizar o mesmo parser `NF_Parser_Completo.ps1`.

## Fluxo alvo

```
Selecionar PDF
  ↓
Extrair texto do PDF → ExtractedPDFText
  ↓
IF ExtractedPDFText está vazio
  ├─ Criar pasta temporária
  ├─ Extrair imagens do PDF para PNG
  ├─ Obter arquivos da pasta
  ├─ Para cada PNG:
  │    └─ Extrair texto com OCR → OcrText
  │    └─ Acrescentar OcrText a ExtractedPDFText
  └─ Remover pasta temporária
  ↓
Executar script do PowerShell (NF_Parser_Completo.ps1)
  ↓
Converter JSON → NF
```

## Configuração sugerida

### 1. Condição
Logo depois de **Extrair texto do PDF**, adicione uma condição:
- se `%ExtractedPDFText%` estiver vazio.

### 2. Pasta temporária
Crie uma pasta exclusiva para a execução, por exemplo:
- base: `%Temp%`
- nome: `NF_OCR`

Se já existir, use uma subpasta/nome único para evitar misturar páginas de execuções anteriores.

### 3. Extrair imagens do PDF
Ação: **PDF → Extrair imagens do PDF**
- Arquivo PDF: `%SelectedFile%`
- Páginas: Todas
- Nome das imagens: `page`
- Salvar em: pasta temporária

A ação salva PNGs no disco.

### 4. Obter PNGs
Ação: **Pasta → Obter arquivos na pasta**
- Pasta: pasta temporária
- Filtro: `*.png`

### 5. OCR
Para cada arquivo PNG:
- Ação: **OCR → Extrair texto com OCR**
- Mecanismo: Windows OCR
- Idioma: Português
- Origem OCR: Imagem no disco
- Arquivo de imagem: arquivo atual
- Modo: Toda a origem especificada
- Saída: `OcrText`

Após cada página, acrescente:
```
%ExtractedPDFText%%CRLF%%OcrText%
```

### 6. Parser
Quando sair da condição, execute normalmente `NF_Parser_Completo.ps1`. Ele deve receber `%ExtractedPDFText%`, independentemente de o conteúdo ter vindo da camada textual do PDF ou do OCR.

## Observações
- Windows OCR é local e não usa créditos AI Builder.
- Pode exigir o pacote de idioma Português do Windows.
- O OCR é fallback; não deve rodar quando o PDF já tiver texto nativo.
- O caminho OCR precisa de smoke real antes de ser considerado validado.
