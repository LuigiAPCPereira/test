"""Page-level native text / local OCR selection through narrow ports."""

from dataclasses import dataclass, replace
from pathlib import Path
from typing import Protocol

from fiscal_processor.domain import ExtractionMode, FiscalExtraction, ProcessingStatus, QualityFlag
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
