"""Local composition root and CLI. Output contains no fiscal values or paths."""

import argparse
from collections import Counter
from pathlib import Path
from typing import NoReturn

from fiscal_processor.adapters.excel.openpyxl_store import OpenpyxlInvoiceStore
from fiscal_processor.adapters.ocr import RapidSmallAdapter
from fiscal_processor.adapters.pdf import PdfiumAdapter
from fiscal_processor.application.batch import DocumentResult, discover_pdfs, process_batch
from fiscal_processor.application.extraction import extract_evidence, parse_evidence
from fiscal_processor.domain import FiscalExtraction


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Processa PDFs localmente para Excel.")
    parser.add_argument("input", type=Path, help="Pasta de PDFs (sem subpastas)")
    parser.add_argument("--output", type=Path, required=True, help="Planilha .xlsx de destino")
    parser.add_argument("--models", type=Path, help="Pasta com modelos OCR já preparados")
    parser.add_argument("--reprocess", action="store_true", help="Atualiza campos automáticos")
    parser.add_argument("--dpi", type=int, default=200, help="DPI do OCR, de 72 a 300")
    args = parser.parse_args(argv)
    if args.output.suffix.lower() != ".xlsx" or not 72 <= args.dpi <= 300:
        parser.error("Destino deve ser .xlsx; DPI deve estar entre 72 e 300.")

    def progress(result: DocumentResult, total: int) -> None:
        code = f" {result.error_code}" if result.error_code else ""
        print(f"{result.index}/{total} {result.outcome}{code}", flush=True)

    try:
        paths = discover_pdfs(args.input)
        if not paths:
            print("EMPTY: nenhum PDF regular na pasta; planilha não alterada.")
            return 0
        pdf = PdfiumAdapter()
        ocr = RapidSmallAdapter(args.models) if args.models is not None else None

        def extract(path: Path, digest: str) -> FiscalExtraction:
            # Missing configuration fails only when a page actually needs OCR.
            evidence = extract_evidence(path, pdf, ocr or _UnavailableOcr(), dpi=args.dpi)
            return parse_evidence(evidence, source_sha256=digest, source_filename=path.name)

        result = process_batch(
            paths,
            OpenpyxlInvoiceStore(args.output),
            extract,
            reprocess=args.reprocess,
            progress=progress,
        )
        counts = Counter(document.outcome for document in result.documents)
        print(" ".join(f"{key}={counts[key]}" for key in ("OK", "REVIEW", "FAILED", "SKIPPED")))
        if result.error_code:
            print("Lote interrompido: verifique acesso, contrato e bloqueio da planilha.")
            return 2
        return 1 if counts["FAILED"] or counts["REVIEW"] else 0
    except KeyboardInterrupt:
        print("CANCELLED: registros já salvos foram preservados.")
        return 130
    except Exception:
        print("BATCH_FAILED: verifique a pasta e as dependências locais.")
        return 2


class _UnavailableOcr:
    def recognize(self, page: object, page_index: int) -> NoReturn:
        raise RuntimeError("OCR_NOT_CONFIGURED")
