"""Local adapter wiring shared by CLI and desktop."""

from collections.abc import Callable
from pathlib import Path
from typing import NoReturn

from fiscal_processor.adapters.ocr import RapidSmallAdapter
from fiscal_processor.adapters.pdf import PdfiumAdapter
from fiscal_processor.application.extraction import extract_and_parse
from fiscal_processor.domain import FiscalExtraction


class UnavailableOcr:
    def recognize(self, page: object, page_index: int) -> NoReturn:
        raise RuntimeError("OCR_NOT_CONFIGURED")


def build_extractor(
    model_dir: Path | None, dpi: int = 200
) -> Callable[[Path, str], FiscalExtraction]:
    pdf = PdfiumAdapter()
    ocr = RapidSmallAdapter(model_dir) if model_dir is not None else UnavailableOcr()

    def extract(path: Path, digest: str) -> FiscalExtraction:
        return extract_and_parse(
            path,
            pdf,
            ocr,
            source_sha256=digest,
            source_filename=path.name,
            dpi=dpi,
        )

    return extract
