"""Sequential batch processing with explicit persistence and failure boundaries."""

import hashlib
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path
from typing import Protocol

from fiscal_processor.domain import FiscalExtraction


class InvoiceStore(Protocol):
    def contains(self, source_sha256: str) -> bool: ...
    def upsert(self, extraction: FiscalExtraction) -> object: ...


@dataclass(frozen=True, slots=True)
class DocumentResult:
    index: int
    outcome: str
    source_sha256: str | None = None
    error_code: str | None = None


@dataclass(frozen=True, slots=True)
class BatchResult:
    total: int
    documents: tuple[DocumentResult, ...]
    error_code: str | None = None


def discover_pdfs(folder: Path) -> tuple[Path, ...]:
    """Only immediate regular PDFs; never follow file symlinks or recurse."""
    if not folder.is_dir():
        raise ValueError("INPUT_FOLDER_INVALID")
    return tuple(
        sorted(
            (
                p
                for p in folder.iterdir()
                if p.suffix.lower() == ".pdf" and not p.is_symlink() and p.is_file()
            ),
            key=lambda p: (p.name.casefold(), p.name),
        )
    )


def file_sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def process_batch(
    paths: tuple[Path, ...],
    store: InvoiceStore,
    extract: Callable[[Path, str], FiscalExtraction],
    *,
    reprocess: bool = False,
    progress: Callable[[DocumentResult, int], None] | None = None,
) -> BatchResult:
    """Save each completed document. Never replace good rows with extraction failures.

    Progress is emitted only after persistence or a terminal per-document outcome.
    KeyboardInterrupt propagates: previously saved rows remain valid.
    """
    results: list[DocumentResult] = []

    def record(result: DocumentResult) -> None:
        results.append(result)
        if progress is not None:
            progress(result, len(paths))

    for index, path in enumerate(paths, 1):
        try:
            if path.is_symlink():
                raise ValueError("INPUT_SYMLINK")
            digest = file_sha256(path)
        except Exception:
            record(DocumentResult(index, "FAILED", error_code="INPUT_READ_FAILED"))
            continue
        try:
            exists = store.contains(digest)
        except Exception:
            record(DocumentResult(index, "FAILED", digest, "WORKBOOK_READ_FAILED"))
            return BatchResult(len(paths), tuple(results), "WORKBOOK_READ_FAILED")
        if exists and not reprocess:
            record(DocumentResult(index, "SKIPPED", digest))
            continue
        try:
            extraction = extract(path, digest)
            if extraction.source_sha256 != digest or file_sha256(path) != digest:
                raise ValueError("INPUT_CHANGED")
        except Exception:
            # Exception text can contain invoice content/paths: never expose it.
            record(DocumentResult(index, "FAILED", digest, "EXTRACTION_FAILED"))
            continue
        try:
            store.upsert(extraction)
        except Exception:
            record(DocumentResult(index, "FAILED", digest, "WORKBOOK_WRITE_FAILED"))
            return BatchResult(len(paths), tuple(results), "WORKBOOK_WRITE_FAILED")
        record(DocumentResult(index, extraction.status.value, digest))
    return BatchResult(len(paths), tuple(results))
