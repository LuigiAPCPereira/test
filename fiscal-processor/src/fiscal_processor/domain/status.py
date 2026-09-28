"""Explicit domain states.

Unknown and partial results are represented as first-class states instead of being
collapsed into false/empty/success values.
"""

from enum import StrEnum


class DocumentType(StrEnum):
    NFE = "NFE"
    NFSE = "NFSE"
    UNKNOWN = "UNKNOWN"


class ExtractionMode(StrEnum):
    NATIVE_TEXT = "NATIVE_TEXT"
    OCR = "OCR"
    MIXED = "MIXED"


class ProcessingStatus(StrEnum):
    OK = "OK"
    REVIEW = "REVIEW"
    FAILED = "FAILED"


class QualityFlag(StrEnum):
    MISSING_INVOICE_NUMBER = "MISSING_INVOICE_NUMBER"
    MISSING_SERIES = "MISSING_SERIES"
    MISSING_ISSUE_DATE = "MISSING_ISSUE_DATE"
    MISSING_ISSUER = "MISSING_ISSUER"
    MISSING_ISSUER_CNPJ = "MISSING_ISSUER_CNPJ"
    MISSING_RECIPIENT = "MISSING_RECIPIENT"
    MISSING_AMOUNT = "MISSING_AMOUNT"
    INVALID_CNPJ = "INVALID_CNPJ"
    AMBIGUOUS_AMOUNT = "AMBIGUOUS_AMOUNT"
    OCR_LOW_QUALITY = "OCR_LOW_QUALITY"
    UNSUPPORTED_LAYOUT = "UNSUPPORTED_LAYOUT"
    AMBIGUOUS_FIELD = "AMBIGUOUS_FIELD"
    INVALID_ISSUE_DATE = "INVALID_ISSUE_DATE"
    INVALID_AMOUNT = "INVALID_AMOUNT"
    INVALID_IDENTIFIER = "INVALID_IDENTIFIER"
