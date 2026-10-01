"""Domain types and deterministic validation for fiscal documents."""

from .invoice import FiscalExtraction, ManualFields
from .nfe_access_key import NfeAccessKey, normalize_nfe_access_key
from .status import DocumentType, ExtractionMode, ProcessingStatus, QualityFlag
from .validation import (
    DomainValidationError,
    format_cnpj,
    normalize_cnpj,
    parse_br_date,
    parse_brl_money,
    validate_cnpj,
)

__all__ = [
    "DocumentType",
    "DomainValidationError",
    "ExtractionMode",
    "FiscalExtraction",
    "ManualFields",
    "NfeAccessKey",
    "ProcessingStatus",
    "QualityFlag",
    "format_cnpj",
    "normalize_cnpj",
    "parse_br_date",
    "parse_brl_money",
    "normalize_nfe_access_key",
    "validate_cnpj",
]
