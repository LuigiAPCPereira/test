"""Page-level native text / local OCR selection through narrow ports."""

from dataclasses import dataclass, replace
from pathlib import Path
from typing import Protocol

from fiscal_processor.domain import (
    DocumentType,
    ExtractionMode,
    FiscalExtraction,
    ProcessingStatus,
    QualityFlag,
)
from fiscal_processor.domain.text import OcrPage, PdfDocumentContent, RenderedPage, TextSpan
from fiscal_processor.parsers import parse_spans


class PdfReader(Protocol):
    def extract_document(self, path: str | Path) -> PdfDocumentContent: ...
    def render_page(self, path: str | Path, page_index: int, *, dpi: int = 300) -> RenderedPage: ...


class OcrReader(Protocol):
    def recognize(self, page: RenderedPage, page_index: int) -> OcrPage: ...


@dataclass(frozen=True, slots=True)
class DocumentEvidence:
    spans: tuple[TextSpan, ...]
    mode: ExtractionMode
    flags: tuple[QualityFlag, ...]


def native_text_is_useful(text: str) -> bool:
    """Conservative initial heuristic, not a claim of fiscal completeness."""
    visible = [c for c in text if not c.isspace()]
    return sum(c.isalnum() for c in visible) >= 40 and sum(
        c.isprintable() and c != "\ufffd" for c in visible
    ) >= 0.95 * len(visible)


def extract_evidence(
    path: Path, pdf: PdfReader, ocr: OcrReader, *, dpi: int = 200
) -> DocumentEvidence:
    if type(dpi) is not int or not 72 <= dpi <= 300:
        raise ValueError("DPI must be an integer between 72 and 300")
    document = pdf.extract_document(path)
    if not document.pages:
        raise ValueError("EMPTY_DOCUMENT")
    spans: list[TextSpan] = []
    modes = set()
    flags = []
    for page in document.pages:
        if native_text_is_useful(page.text):
            modes.add(ExtractionMode.NATIVE_TEXT)
            spans.extend(
                TextSpan(
                    b.text,
                    b.left,
                    page.height_points - b.top,
                    b.right,
                    page.height_points - b.bottom,
                    page.page_index,
                )
                for b in page.blocks
            )
        else:
            modes.add(ExtractionMode.OCR)
            result = ocr.recognize(pdf.render_page(path, page.page_index, dpi=dpi), page.page_index)
            if any(span.page != page.page_index for span in result.spans):
                raise ValueError("OCR_PAGE_MISMATCH")
            spans.extend(result.spans)
            if result.low_quality:
                flags.append(QualityFlag.OCR_LOW_QUALITY)
    mode = next(iter(modes)) if len(modes) == 1 else ExtractionMode.MIXED
    return DocumentEvidence(tuple(spans), mode, tuple(dict.fromkeys(flags)))


def parse_evidence(
    evidence: DocumentEvidence, *, source_sha256: str, source_filename: str
) -> FiscalExtraction:
    result = parse_spans(
        evidence.spans,
        source_sha256=source_sha256,
        source_filename=source_filename,
        extraction_mode=evidence.mode,
    )
    flags = tuple(dict.fromkeys((*result.quality_flags, *evidence.flags)))
    return replace(
        result, quality_flags=flags, status=ProcessingStatus.REVIEW if flags else result.status
    )


_MISSING_FLAGS = {
    QualityFlag.MISSING_INVOICE_NUMBER,
    QualityFlag.MISSING_SERIES,
    QualityFlag.MISSING_ISSUE_DATE,
    QualityFlag.MISSING_ISSUER,
    QualityFlag.MISSING_ISSUER_CNPJ,
    QualityFlag.MISSING_RECIPIENT,
    QualityFlag.MISSING_AMOUNT,
}


def _result_rank(result: FiscalExtraction) -> tuple[int, int, int]:
    """Prefer recognized documents with more validated fields and fewer review flags."""
    filled = sum(
        value is not None
        for value in (
            result.invoice_number,
            result.series,
            result.issue_date,
            result.issuer_name,
            result.issuer_cnpj,
            result.recipient_name,
            result.amount,
        )
    )
    return (
        int(result.document_type != DocumentType.UNKNOWN),
        filled,
        -len(result.quality_flags),
    )


def _needs_ocr_retry(result: FiscalExtraction, evidence: DocumentEvidence) -> bool:
    if evidence.mode == ExtractionMode.OCR or result.status == ProcessingStatus.OK:
        return False
    flags = set(result.quality_flags)
    return QualityFlag.UNSUPPORTED_LAYOUT in flags or bool(flags & _MISSING_FLAGS)


def _extract_all_ocr(
    path: Path,
    pdf: PdfReader,
    ocr: OcrReader,
    *,
    dpi: int,
) -> DocumentEvidence:
    document = pdf.extract_document(path)
    if not document.pages:
        raise ValueError("EMPTY_DOCUMENT")
    spans: list[TextSpan] = []
    flags: list[QualityFlag] = []
    for page in document.pages:
        result = ocr.recognize(pdf.render_page(path, page.page_index, dpi=dpi), page.page_index)
        if any(span.page != page.page_index for span in result.spans):
            raise ValueError("OCR_PAGE_MISMATCH")
        spans.extend(result.spans)
        if result.low_quality:
            flags.append(QualityFlag.OCR_LOW_QUALITY)
    return DocumentEvidence(
        tuple(spans),
        ExtractionMode.OCR,
        tuple(dict.fromkeys(flags)),
    )


def extract_and_parse(
    path: Path,
    pdf: PdfReader,
    ocr: OcrReader,
    *,
    source_sha256: str,
    source_filename: str,
    dpi: int = 200,
) -> FiscalExtraction:
    """Parse native evidence first, then retry locally with OCR only when it can help."""
    evidence = extract_evidence(path, pdf, ocr, dpi=dpi)
    first = parse_evidence(
        evidence,
        source_sha256=source_sha256,
        source_filename=source_filename,
    )
    if not _needs_ocr_retry(first, evidence):
        return first
    try:
        ocr_evidence = _extract_all_ocr(path, pdf, ocr, dpi=dpi)
        retried = parse_evidence(
            ocr_evidence,
            source_sha256=source_sha256,
            source_filename=source_filename,
        )
    except Exception:
        # Retry is optional for a document that already produced safe REVIEW evidence.
        return first
    return retried if _result_rank(retried) > _result_rank(first) else first
