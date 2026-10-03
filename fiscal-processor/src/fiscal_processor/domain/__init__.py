"""Domain types and deterministic validation for fiscal documents."""

from .fields import CandidateSource, FieldCandidate, FiscalField
from .invoice import FiscalExtraction, ManualFields
from .nfe_access_key import NfeAccessKey, normalize_nfe_access_key
from .resolution import FieldResolution, ResolutionStatus, resolve_field_candidates
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
    "CandidateSource",
    "DocumentType",
    "DomainValidationError",
    "ExtractionMode",
    "FieldCandidate",
    "FiscalField",
    "FieldResolution",
    "FiscalExtraction",
    "ManualFields",
    "NfeAccessKey",
    "ProcessingStatus",
    "QualityFlag",
    "ResolutionStatus",
    "format_cnpj",
    "normalize_cnpj",
    "parse_br_date",
    "parse_brl_money",
    "resolve_field_candidates",
    "normalize_nfe_access_key",
    "validate_cnpj",
]
