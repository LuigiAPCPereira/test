"""PDFium adapter for native text extraction and page rasterization.

This module owns the pypdfium2 dependency. It deliberately does not perform OCR or
fiscal parsing; those concerns live behind different boundaries.
"""

import math
from pathlib import Path
from typing import Any

from fiscal_processor.domain.text import (
    PdfDocumentContent,
    PdfPageContent,
    PdfTextBlock,
    RenderedPage,
    TextSpan,
)


class PdfAdapterError(RuntimeError):
    """Raised when a PDF cannot be opened or processed safely."""


class PdfiumAdapter:
    """Read PDF native text and render pages without OCR."""

    def __init__(
        self,
        pdfium_module: Any | None = None,
        pdfium_raw_module: Any | None = None,
        *,
        max_pages: int = 500,
        max_render_pixels: int = 40_000_000,
    ) -> None:
        if max_pages <= 0 or max_render_pixels <= 0:
            raise ValueError("PDF limits must be positive")
        self._max_pages = max_pages
        self._max_render_pixels = max_render_pixels
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
            self._check_page_count(pdf)
            pages = tuple(self._extract_page(pdf, index) for index in range(len(pdf)))
            return PdfDocumentContent(pages=pages)
        except PdfAdapterError:
            raise
        except Exception as exc:
            raise PdfAdapterError(f"failed to extract PDF: {Path(path).name}") from exc
        finally:
            pdf.close()

    def extract_spans(self, path: str | Path) -> tuple[TextSpan, ...]:
        """Return native evidence in the same top-left coordinate system as OCR."""
        document = self.extract_document(path)
        return tuple(
            TextSpan(
                block.text,
                block.left,
                page.height_points - block.top,
                block.right,
                page.height_points - block.bottom,
                page.page_index,
            )
            for page in document.pages
            for block in page.blocks
        )

    def render_page(self, path: str | Path, page_index: int, *, dpi: int = 300) -> RenderedPage:
        if type(dpi) is not int or not 1 <= dpi <= 600:
            raise ValueError("dpi must be an integer between 1 and 600")

        pdf = self._open_document(path)
        try:
            page_count = len(pdf)
            self._check_page_count(pdf)
            if page_index < 0 or page_index >= page_count:
                raise IndexError(
                    f"page_index {page_index} outside document with {page_count} pages"
                )

            page = pdf[page_index]
            try:
                width, height = page.get_size()
                pixels_count = math.ceil(width * (dpi / 72)) * math.ceil(height * (dpi / 72))
                if pixels_count > self._max_render_pixels:
                    raise PdfAdapterError("page exceeds render pixel limit")
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
        except (IndexError, ValueError, PdfAdapterError):
            raise
        except Exception as exc:
            raise PdfAdapterError(
                f"failed to render page {page_index} of {Path(path).name}"
            ) from exc
        finally:
            pdf.close()

    def _check_page_count(self, pdf: Any) -> None:
        if len(pdf) > self._max_pages:
            raise PdfAdapterError("document exceeds page limit")

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
