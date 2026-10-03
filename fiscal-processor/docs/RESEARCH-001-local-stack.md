# Pesquisa técnica — stack local-only

**Data:** 2026-09-27  
**Objetivo:** escolher base técnica para PDF/OCR/Excel/GUI/empacotamento sem nuvem.

## Conclusões

### PDF
**Selecionado para POC:** pypdfium2/PDFium.

Motivos:
- extração textual e renderização no mesmo boundary;
- multiplataforma;
- wheels pré-compilados;
- licença do wrapper Apache-2.0/BSD-3-Clause e PDFium BSD-style;
- evita o copyleft forte do PyMuPDF.

**Não selecionado como base:** PyMuPDF.
A documentação atual informa dual licensing AGPL/comercial. Isso pode ser válido em outros contextos, mas não é a opção de menor atrito para um utilitário empresarial fechado.

### OCR
**Decisão pendente por benchmark.**

Tesseract:
- Apache 2.0;
- offline;
- pacote oficial de idioma português (`por`);
- ecossistema maduro;
- exige distribuir/achar engine + traineddata no Windows.

RapidOCR/ONNX:
- Apache 2.0;
- offline/multiplataforma;
- PP-OCRv6 lista português (`pt`);
- Python 3.8–3.13 na release 3.9.2;
- modelos podem ser empacotados, mas runtime deve ser configurado para não baixá-los.

A escolha será feita por corpus sintético/anonimizado, considerando precisão em NFS-e, startup, tamanho e latência.

### Excel
**Selecionado para POC:** openpyxl.

- lê e escreve XLSX/XLSM;
- MIT;
- atende merge/preservação das colunas manuais;
- workbook será controlado pelo app, evitando dependência de features OOXML avançadas que a biblioteca não preserva integralmente.

### Empacotamento
**Selecionado para POC:** PyInstaller `onedir`.

- usuário final não precisa instalar Python;
- `onedir` é default e mais fácil de diagnosticar;
- `onefile` inicia mais lentamente e fica para depois;
- PyInstaller não é cross-compiler, então o artefato Windows será construído em Windows CI.

GitHub oferece runners Windows hospedados; o pipeline de build contém somente código/modelos/fixtures sintéticas.

### GUI
**Decisão adiada até o core POC.**

- PySide6: toolkit maduro e acessível, mas LGPLv3/comercial e footprint maior.
- pywebview: BSD e pode reutilizar WebView2; Windows 11 traz WebView2 Runtime e a maioria dos Windows 10 elegíveis também, mas a presença deve ser detectada.
- toolkit nativo simples continua candidato para minimizar runtime.

O Frontend DNA é aplicado ao contrato de estados e interação antes do framework.

## Fontes verificadas

- pypdfium2 licensing/intro: https://pypdfium2-team.github.io/pypdfium2/readme.html
- pypdfium2 text API: https://pypdfium2-team.github.io/pypdfium2/python_api.html
- PyMuPDF licensing: https://pymupdf.readthedocs.io/en/latest/about.html
- Tesseract install/license: https://tesseract-ocr.github.io/tessdoc/Installation.html
- Tesseract data files: https://tesseract-ocr.github.io/tessdoc/Data-Files.html
- RapidOCR project/license: https://github.com/RapidAI/RapidOCR
- RapidOCR model languages: https://github.com/RapidAI/RapidOCRDocs/blob/main/docs/model_list.md
- RapidOCR 3.9.2: https://pypi.org/project/rapidocr/
- ONNX Runtime Python: https://onnxruntime.ai/docs/get-started/with-python.html
- openpyxl 3.1 tutorial: https://openpyxl.readthedocs.io/en/3.1/tutorial.html
- openpyxl package/license: https://pypi.org/project/openpyxl/
- PyInstaller: https://pyinstaller.org/en/stable/
- PyInstaller onedir/onefile: https://pyinstaller.org/en/stable/operating-mode.html
- PyInstaller license: https://pyinstaller.org/en/stable/license.html
- GitHub hosted runners: https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- Qt for Python licensing: https://doc.qt.io/qtforpython-6/
- WebView2 distribution: https://learn.microsoft.com/microsoft-edge/webview2/concepts/distribution
- pywebview metadata: https://github.com/r0x0r/pywebview/blob/master/pyproject.toml

## Hipóteses a falsificar

- RapidOCR supera Tesseract no corpus de NFS-e sem tornar o bundle excessivo.
- pypdfium2 extrai com qualidade suficiente os PDFs digitais reais do domínio.
- pacote `onedir` não é bloqueado pela política corporativa.
- WebView2 está disponível na máquina alvo se pywebview for escolhido.

Nenhuma hipótese acima é tratada como fato até smoke/benchmark.
