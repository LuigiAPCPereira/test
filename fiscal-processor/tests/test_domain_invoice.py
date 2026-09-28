from datetime import date
from decimal import Decimal

import pytest

from fiscal_processor.domain import (
    DocumentType,
    ExtractionMode,
    FiscalExtraction,
    ManualFields,
    ProcessingStatus,
    QualityFlag,
)


def test_fiscal_extraction_keeps_unknowns_explicit() -> None:
    extraction = FiscalExtraction(
        source_sha256="a" * 64,
        source_filename="nf.pdf",
        document_type=DocumentType.UNKNOWN,
        extraction_mode=ExtractionMode.OCR,
        status=ProcessingStatus.REVIEW,
        quality_flags=(QualityFlag.UNSUPPORTED_LAYOUT,),
    )

    assert extraction.invoice_number is None
    assert extraction.amount is None
    assert extraction.status is ProcessingStatus.REVIEW


def test_manual_fields_are_separate_from_automatic_extraction() -> None:
    extraction = FiscalExtraction(
        source_sha256="b" * 64,
        source_filename="nf.pdf",
        document_type=DocumentType.NFE,
        extraction_mode=ExtractionMode.NATIVE_TEXT,
        status=ProcessingStatus.OK,
        invoice_number="004241885",
        issue_date=date(2026, 7, 30),
        amount=Decimal("112000.00"),
    )
    manual = ManualFields(
        os_number="OS-5231",
        validity=date(2026, 12, 31),
        observations="Conferido",
    )

    assert not hasattr(extraction, "os_number")
    assert manual.os_number == "OS-5231"


def test_rejects_invalid_sha256() -> None:
    with pytest.raises(ValueError, match="SHA-256"):
        FiscalExtraction(
            source_sha256="not-a-hash",
            source_filename="nf.pdf",
            document_type=DocumentType.UNKNOWN,
            extraction_mode=ExtractionMode.NATIVE_TEXT,
            status=ProcessingStatus.REVIEW,
        )


def test_rejects_duplicate_quality_flags() -> None:
    with pytest.raises(ValueError, match="duplicates"):
        FiscalExtraction(
            source_sha256="c" * 64,
            source_filename="nf.pdf",
            document_type=DocumentType.UNKNOWN,
            extraction_mode=ExtractionMode.OCR,
            status=ProcessingStatus.REVIEW,
            quality_flags=(QualityFlag.OCR_LOW_QUALITY, QualityFlag.OCR_LOW_QUALITY),
        )
