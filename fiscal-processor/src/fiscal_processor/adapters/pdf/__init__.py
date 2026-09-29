"""PDF extraction and rendering adapters."""

from fiscal_processor.domain.text import (
    PdfDocumentContent,
    PdfPageContent,
    PdfTextBlock,
    RenderedPage,
)

from .pdfium import PdfAdapterError, PdfiumAdapter

__all__ = [
    "PdfAdapterError",
    "PdfDocumentContent",
    "PdfPageContent",
    "PdfTextBlock",
    "PdfiumAdapter",
    "RenderedPage",
]
