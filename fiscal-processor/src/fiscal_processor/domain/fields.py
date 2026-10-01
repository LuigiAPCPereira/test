"""Structured field candidates preserve provenance before fiscal resolution."""

import math
from dataclasses import dataclass
from enum import StrEnum


class FiscalField(StrEnum):
    INVOICE_NUMBER = "invoice_number"
    SERIES = "series"
    ISSUE_DATE = "issue_date"
    ISSUER_NAME = "issuer_name"
    ISSUER_CNPJ = "issuer_cnpj"
    RECIPIENT_NAME = "recipient_name"
    AMOUNT = "amount"


class CandidateSource(StrEnum):
    NATIVE_TEXT = "native_text"
    OCR = "ocr"
    NFE_ACCESS_KEY = "nfe_access_key"


@dataclass(frozen=True, slots=True)
class FieldCandidate:
    """Observed candidate; selection belongs to a later deterministic resolver."""

    field: FiscalField
    raw_value: str
    normalized_value: str
    source: CandidateSource
    page: int | None = None
    section: str | None = None
    bbox: tuple[float, float, float, float] | None = None
    ocr_score: float | None = None

    def __post_init__(self) -> None:
        if not self.raw_value.strip():
            raise ValueError("raw_value must not be blank")
        if not self.normalized_value.strip():
            raise ValueError("normalized_value must not be blank")
        if self.page is not None and (type(self.page) is not int or self.page < 0):
            raise ValueError("page must be a nonnegative integer")
        if self.section is not None and not self.section.strip():
            raise ValueError("section must not be blank")
        if self.bbox is not None:
            left, top, right, bottom = self.bbox
            if not all(math.isfinite(value) for value in self.bbox):
                raise ValueError("bbox coordinates must be finite")
            if right < left or bottom < top:
                raise ValueError("bbox must use a top-left origin")
        if self.ocr_score is not None:
            if self.source != CandidateSource.OCR:
                raise ValueError("ocr_score is only valid for OCR candidates")
            if not math.isfinite(self.ocr_score) or not 0 <= self.ocr_score <= 1:
                raise ValueError("ocr_score must be between 0 and 1")
