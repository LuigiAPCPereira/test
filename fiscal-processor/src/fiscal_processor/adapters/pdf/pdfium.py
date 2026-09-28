"""PDFium adapter for native text extraction and page rasterization.

This module owns the pypdfium2 dependency. It deliberately does not perform OCR or
fiscal parsing; those concerns live behind different boundaries.
"""

from dataclasses import dataclass
from pathlib import Path
from typing import Any


class PdfAdapterError(RuntimeError):
    """Raised when a PDF cannot be opened or processed safely."""


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


class PdfiumAdapter:
    """Read PDF native text and render pages without OCR."""

    def __init__(self, pdfium_module: Any | None = None, pdfium_raw_module: Any | None = None) -> None:
        if pdfium_module is None or pdfium_raw_module is None:
            try:
                import pypdfium2 as pdfium
                import pypdfium2.raw as pdfium_c
            except ImportError as exc:  # pragma: no cover - deployment/configuration failure
                raise PdfAdapterError("pypdfium2 is required for PDF processing") from exc
            pdfium_module = pdfium
            pdfium_raw_module = pdfium_c

        self._pdfium = pdfium_module
        self._pdfium_c = pdfium_raw_module

    def extract_document(self, path: str | Path) -> PdfDocumentContent:
        pdf = self._open_document(path)
        try:
            pages = tuple(self._extract_page(pdf, index) for index in range(len(pdf)))
            return PdfDocumentContent(pages=pages)
        except PdfAdapterError:
            raise
        except Exception as exc:
            raise PdfAdapterError(f"failed to extract PDF: {Path(path).name}") from exc
        finally:
            pdf.close()

    def render_page(self, path: str | Path, page_index: int, *, dpi: int = 300) -> RenderedPage:
        if dpi <= 0:
            raise ValueError("dpi must be greater than zero")

        pdf = self._open_document(path)
        try:
            page_count = len(pdf)
            if page_index < 0 or page_index >= page_count:
                raise IndexError(f"page_index {page_index} outside document with {page_count} pages")

            page = pdf[page_index]
            try:
                bitmap = page.render(
                    scale=dpi / 72.0,
                    prefer_bgrx=True,
                    maybe_alpha=True,
                    rev_byteorder=True,
                )
                try:
                    pixels = bytes(bitmap.buffer)
                    return RenderedPage(
                        page_index=page_index,
                        width=bitmap.width,
                        height=bitmap.height,
                        stride=bitmap.stride,
                        mode=bitmap.mode,
                        pixels=pixels,
                        dpi=dpi,
                    )
                finally:
                    bitmap.close()
            finally:
                page.close()
        except (IndexError, ValueError):
            raise
        except Exception as exc:
            raise PdfAdapterError(f"failed to render page {page_index} of {Path(path).name}") from exc
        finally:
            pdf.close()

    def _open_document(self, path: str | Path) -> Any:
        source = Path(path)
        try:
            return self._pdfium.PdfDocument(source)
        except Exception as exc:
            raise PdfAdapterError(f"unable to open PDF: {source.name}") from exc

    def _extract_page(self, pdf: Any, page_index: int) -> PdfPageContent:
        page = pdf[page_index]
        try:
            width, height = page.get_size()
            textpage = page.get_textpage()
            try:
                page_text = self._normalize_text(textpage.get_text_bounded())
                blocks: list[PdfTextBlock] = []
                for obj in page.get_objects(
                    filter=[self._pdfium_c.FPDF_PAGEOBJ_TEXT],
                    textpage=textpage,
                ):
                    text = self._normalize_text(obj.extract()).strip()
                    if not text:
                        continue
                    left, bottom, right, top = obj.get_bounds()
                    blocks.append(
                        PdfTextBlock(
                            text=text,
                            left=float(left),
                            bottom=float(bottom),
                            right=float(right),
                            top=float(top),
                        )
                    )
                return PdfPageContent(
                    page_index=page_index,
                    width_points=float(width),
                    height_points=float(height),
                    text=page_text,
                    blocks=tuple(blocks),
                )
            finally:
                textpage.close()
        finally:
            page.close()

    @staticmethod
    def _normalize_text(value: str) -> str:
        return value.replace("\r\n", "\n").replace("\r", "\n")
