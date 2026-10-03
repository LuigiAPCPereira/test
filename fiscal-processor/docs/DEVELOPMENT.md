# Development gates

## Supported development environment

- Python 3.11+
- Linux, macOS or Windows for core development
- Windows CI will be required only when packaging begins in FP-009

## Local bootstrap

```bash
python -m venv .venv
. .venv/bin/activate          # Linux/macOS
# .venv\Scripts\activate    # Windows PowerShell
python -m pip install -e '.[dev]'
```

## Gates for FP-002+

Run from `fiscal-processor/`:

```bash
ruff check .
ruff format --check .
mypy src
pytest
```

A green gate means only that the checked code passed those static/unit checks. It does not prove
PDF extraction, OCR quality, Windows packaging, no-admin execution, or corporate policy compatibility.

## Privacy rule

Development tests and CI must use synthetic/anonymized fixtures. No real corporate invoice is
permitted in the repository or CI artifacts.
