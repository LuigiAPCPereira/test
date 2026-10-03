"""Text evidence shared by PDF/OCR adapters and parsers, in PDF points."""

import math
from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class TextSpan:
    text: str
    left: float
    top: float
    right: float
    bottom: float
    page: int = 0

    def __post_init__(self) -> None:
        if type(self.page) is not int or self.page < 0:
            raise ValueError("page must be a nonnegative integer")
        if not all(math.isfinite(v) for v in (self.left, self.top, self.right, self.bottom)):
            raise ValueError("coordinates must be finite")
        if self.right < self.left or self.bottom < self.top:
            raise ValueError("coordinates must use a top-left origin")


@dataclass(frozen=True, slots=True)
class PdfTextBlock:
    text: str
    left: float
    bottom: float
    right: float
    top: float


@dataclass(frozen=True, slots=True)
class PdfPageContent:
    page_index: int
    width_points: float
    height_points: float
    text: str
    blocks: tuple[PdfTextBlock, ...]


@dataclass(frozen=True, slots=True)
class PdfDocumentContent:
    pages: tuple[PdfPageContent, ...]

    @property
    def text(self) -> str:
        return "\n\f\n".join(page.text for page in self.pages)


@dataclass(frozen=True, slots=True)
class RenderedPage:
    page_index: int
    width: int
    height: int
    stride: int
    mode: str
    pixels: bytes
    dpi: int


@dataclass(frozen=True, slots=True)
class OcrPage:
    spans: tuple[TextSpan, ...]
    low_quality: bool = False
