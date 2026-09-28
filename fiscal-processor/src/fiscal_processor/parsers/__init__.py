"""Deterministic fiscal parsers; no PDF, OCR, filesystem or network dependencies."""

from .labelled import parse_invoice

__all__ = ["parse_invoice"]
