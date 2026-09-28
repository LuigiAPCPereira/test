"""Deterministic fiscal parsers; no PDF, OCR, filesystem or network dependencies."""

from .labelled import parse_invoice
from .spatial import parse_spans

__all__ = ["parse_invoice", "parse_spans"]
