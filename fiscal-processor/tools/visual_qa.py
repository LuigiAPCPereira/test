"""Development-only visual QA harness for deterministic synthetic desktop states."""

from __future__ import annotations

import argparse
import tkinter as tk
from decimal import Decimal
from pathlib import Path
from tempfile import TemporaryDirectory

from openpyxl import Workbook

from fiscal_processor.application.batch import BatchResult, DocumentResult
from fiscal_processor.domain.invoice import FiscalExtraction
from fiscal_processor.domain.status import (
    DocumentType,
    ExtractionMode,
    ProcessingStatus,
    QualityFlag,
)
from fiscal_processor.presentation.desktop import Desktop
from fiscal_processor.presentation.worker import WorkerEvent

STATES = (
    "initial",
    "selected",
    "processing",
    "empty",
    "success",
    "partial",
    "error",
    "cancelled",
    "long",
)


def _extraction(index: int, *, review: bool = False) -> FiscalExtraction:
    return FiscalExtraction(
        source_sha256=f"{index:064x}",
        source_filename=f"nota-sintetica-{index:02d}.pdf",
        document_type=DocumentType.NFSE if index % 2 else DocumentType.NFE,
        extraction_mode=ExtractionMode.NATIVE_TEXT,
        status=ProcessingStatus.REVIEW if review else ProcessingStatus.OK,
        invoice_number=f"2026{index:04d}",
        issuer_name="EMPRESA SINTETICA",
        recipient_name="CLIENTE SINTETICO",
        amount=Decimal("1234.56") + index,
        quality_flags=(QualityFlag.AMBIGUOUS_FIELD,) if review else (),
        parser_id="qa-synthetic",
    )


def _select_synthetic_folder(app: Desktop) -> None:
    app.folder = Path("C:/QA-SINTETICO/Notas-Fiscais")
    app.folder_text.set(str(app.folder))
    app.process.configure(state="normal")
    app.open_button.configure(state="disabled")
    app.status.set(
        "Pasta selecionada. A planilha será salva como Controle_Notas_Fiscais.xlsx nesta pasta."
    )
    app.current.set("Pronto para processar. Subpastas não serão incluídas.")
    app.clear_results()


def _add_document(
    app: Desktop,
    index: int,
    total: int,
    outcome: str,
    *,
    filename: str | None = None,
    error_code: str | None = None,
    review: bool = False,
) -> DocumentResult:
    extraction = _extraction(index, review=review) if outcome in {"OK", "REVIEW"} else None
    result = DocumentResult(
        index,
        outcome,
        source_sha256=f"{index:064x}",
        error_code=error_code,
        extraction=extraction,
    )
    app.handle(
        WorkerEvent(
            "document",
            total=total,
            filename=filename or f"nota-sintetica-{index:02d}.pdf",
            document=result,
        )
    )
    return result


def _create_synthetic_workbook(folder: Path) -> Path:
    output = folder / "Controle_Notas_Fiscais.xlsx"
    book = Workbook()
    sheet = book.active
    sheet.title = "QA sintético"
    sheet.append(["ARQUIVO", "TIPO", "NF", "VALOR", "SITUACAO"])
    sheet.append(["nota-sintetica-01.pdf", "NFSE", "20260001", 1235.56, "OK"])
    book.save(output)
    book.close()
    return output


def apply_state(app: Desktop, state: str, scratch: Path) -> None:
    if state == "initial":
        return

    _select_synthetic_folder(app)

    if state == "selected":
        return
    if state == "processing":
        app.busy = True
        for widget in (app.choose, app.process, app.reprocess_check, app.open_button):
            widget.configure(state="disabled")
        app.stop.configure(state="normal")
        app.status.set("Processando notas fiscais…")
        app.handle(WorkerEvent("ready", total=7))
        app.bar.configure(value=3)
        app.handle(WorkerEvent("started", total=7, index=4, filename="nota-sintetica-04.pdf"))
        return
    if state == "empty":
        app.handle(WorkerEvent("ready", total=0))
        app.handle(WorkerEvent("done", batch=BatchResult(0, ())))
        return

    app.handle(WorkerEvent("ready", total=4))
    rows: list[DocumentResult] = []
    if state in {"success", "long"}:
        rows.extend(_add_document(app, index, 4, "OK") for index in range(1, 5))
        if state == "long":
            key = app.table.get_children()[0]
            app.table.item(
                key,
                values=(
                    "nome-muito-longo-" * 18 + ".pdf",
                    "NFSE",
                    "20260001",
                    "R$ 1.235,56",
                    "Processada",
                ),
            )
        app.output = _create_synthetic_workbook(scratch)
        app.handle(WorkerEvent("done", batch=BatchResult(4, tuple(rows))))
        app.open_button.configure(state="normal")
        return
    if state == "partial":
        rows.append(_add_document(app, 1, 4, "OK"))
        rows.append(_add_document(app, 2, 4, "REVIEW", review=True))
        rows.append(_add_document(app, 3, 4, "SKIPPED"))
        rows.append(_add_document(app, 4, 4, "FAILED", error_code="EXTRACTION_FAILED"))
        app.output = _create_synthetic_workbook(scratch)
        app.handle(WorkerEvent("done", batch=BatchResult(4, tuple(rows))))
        app.open_button.configure(state="normal")
        return
    if state == "error":
        failed = _add_document(app, 1, 4, "FAILED", error_code="WORKBOOK_WRITE_FAILED")
        app.handle(
            WorkerEvent(
                "done",
                batch=BatchResult(4, (failed,), error_code="WORKBOOK_WRITE_FAILED"),
            )
        )
        return
    if state == "cancelled":
        rows.append(_add_document(app, 1, 4, "OK"))
        app.handle(WorkerEvent("done", batch=BatchResult(4, tuple(rows), cancelled=True)))
        return
    raise ValueError(f"unsupported state: {state}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Open synthetic Fiscal Processor states for visual QA"
    )
    parser.add_argument("state", choices=STATES, nargs="?", default="partial")
    parser.add_argument(
        "--scale",
        type=float,
        default=1.0,
        help="Tk scaling multiplier; use 2.0 for the 200%% text-scale check.",
    )
    parser.add_argument(
        "--geometry",
        default="1000x680",
        help="Initial window geometry, e.g. 760x540",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if not 0.75 <= args.scale <= 3.0:
        raise SystemExit("--scale must be between 0.75 and 3.0")

    with TemporaryDirectory(prefix="fiscal-processor-qa-") as temp_dir:
        root = tk.Tk()
        root.tk.call("tk", "scaling", args.scale)
        app = Desktop(root)
        root.title(f"Fiscal Processor — QA VISUAL SINTÉTICO — {args.state}")
        root.geometry(args.geometry)
        apply_state(app, args.state, Path(temp_dir))
        root.mainloop()


if __name__ == "__main__":
    main()
