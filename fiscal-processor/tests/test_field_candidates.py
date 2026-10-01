import pytest

from fiscal_processor.domain import CandidateSource, FieldCandidate, FiscalField


def test_field_candidate_preserves_provenance_without_inventing_confidence() -> None:
    candidate = FieldCandidate(
        field=FiscalField.INVOICE_NUMBER,
        raw_value="004241885",
        normalized_value="004241885",
        source=CandidateSource.NFE_ACCESS_KEY,
        page=0,
    )

    assert candidate.raw_value == "004241885"
    assert candidate.normalized_value == "004241885"
    assert candidate.ocr_score is None


def test_ocr_candidate_accepts_bounded_recognition_score() -> None:
    candidate = FieldCandidate(
        field=FiscalField.AMOUNT,
        raw_value="R$ 1.234,56",
        normalized_value="1234.56",
        source=CandidateSource.OCR,
        page=0,
        bbox=(10.0, 20.0, 100.0, 35.0),
        ocr_score=0.92,
    )

    assert candidate.ocr_score == pytest.approx(0.92)


def test_non_ocr_candidate_cannot_claim_ocr_score() -> None:
    with pytest.raises(ValueError, match="only valid for OCR"):
        FieldCandidate(
            field=FiscalField.SERIES,
            raw_value="099",
            normalized_value="099",
            source=CandidateSource.NFE_ACCESS_KEY,
            ocr_score=0.9,
        )
