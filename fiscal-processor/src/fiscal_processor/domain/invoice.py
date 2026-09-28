"""Core fiscal document models.

Automatic extraction and manual operator-owned fields are separate types on purpose.
That boundary prevents reprocessing from silently taking ownership of OS, validity,
or observations.
"""

from dataclasses import dataclass, field
from datetime import date
from decimal import Decimal
import re

from .status import DocumentType, ExtractionMode, ProcessingStatus, QualityFlag

_SHA256_RE = re.compile(r"^[0-9a-f]{64}$")


@dataclass(frozen=True, slots=True)
class FiscalExtraction:
    source_sha256: str
    source_filename: str
    document_type: DocumentType
    extraction_mode: ExtractionMode
    status: ProcessingStatus
    invoice_number: str | None = None
    series: str | None = None
    issue_date: date | None = None
    issuer_name: str | None = None
    issuer_cnpj: str | None = None
    recipient_name: str | None = None
    amount: Decimal | None = None
    quality_flags: tuple[QualityFlag, ...] = field(default_factory=tuple)
    parser_id: str | None = None

    def __post_init__(self) -> None:
        if not _SHA256_RE.fullmatch(self.source_sha256):
            raise ValueError("source_sha256 must be a lowercase 64-character SHA-256 hex digest")
        if not self.source_filename.strip():
            raise ValueError("source_filename must not be blank")
        if self.amount is not None and self.amount < 0:
            raise ValueError("amount must not be negative")
        if len(set(self.quality_flags)) != len(self.quality_flags):
            raise ValueError("quality_flags must not contain duplicates")


@dataclass(frozen=True, slots=True)
class ManualFields:
    os_number: str | None = None
    validity: date | None = None
    observations: str | None = None
