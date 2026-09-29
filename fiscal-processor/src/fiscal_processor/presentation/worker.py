"""Worker events contain local data; no Tk calls, networking or logging."""

from dataclasses import dataclass
from pathlib import Path
from queue import Queue
from threading import Event

from fiscal_processor.adapters.excel.openpyxl_store import OpenpyxlInvoiceStore
from fiscal_processor.application.batch import (
    BatchResult,
    DocumentResult,
    discover_pdfs,
    process_batch,
)
from fiscal_processor.composition import build_extractor


@dataclass(frozen=True, slots=True)
class WorkerEvent:
    kind: str
    total: int = 0
    index: int = 0
    filename: str = ""
    document: DocumentResult | None = None
    batch: BatchResult | None = None


def run_batch(
    folder: Path,
    output: Path,
    models: Path | None,
    reprocess: bool,
    cancel: Event,
    events: Queue[WorkerEvent],
) -> None:
    try:
        paths = discover_pdfs(folder)
        events.put(WorkerEvent("ready", total=len(paths)))
        if not paths:
            result = BatchResult(0, ())
        else:
            result = process_batch(
                paths,
                OpenpyxlInvoiceStore(output),
                build_extractor(models),
                reprocess=reprocess,
                cancelled=cancel.is_set,
                started=lambda index, path: events.put(
                    WorkerEvent("started", index=index, filename=path.name)
                ),
                progress=lambda item, total: events.put(
                    WorkerEvent(
                        "document", total=total, filename=paths[item.index - 1].name, document=item
                    )
                ),
            )
        events.put(WorkerEvent("done", batch=result))
    except Exception:
        events.put(WorkerEvent("error"))
