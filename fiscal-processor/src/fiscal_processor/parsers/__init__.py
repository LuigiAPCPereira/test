"""Deterministic fiscal parsers; no PDF, OCR, filesystem or network dependencies."""

from .labelled import parse_invoice
from .nfe_access_key import find_nfe_access_key_candidates, resolve_nfe_structural_candidates
from .nfe_danfe import resolve_nfe_danfe_candidates
from .spatial import find_nfe_visual_candidates, parse_spans

__all__ = [
    "find_nfe_access_key_candidates",
    "find_nfe_visual_candidates",
    "parse_invoice",
    "parse_spans",
    "resolve_nfe_danfe_candidates",
    "resolve_nfe_structural_candidates",
]
