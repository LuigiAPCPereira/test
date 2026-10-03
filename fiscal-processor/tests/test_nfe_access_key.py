import pytest

from fiscal_processor.domain import (
    CandidateSource,
    DomainValidationError,
    FiscalField,
    NfeAccessKey,
    normalize_nfe_access_key,
)

SYNTHETIC_KEY = "29261046395687000455550990042418851123456780"


def test_parses_valid_synthetic_nfe_access_key() -> None:
    key = NfeAccessKey.parse(SYNTHETIC_KEY)

    assert key.uf_code == "29"
    assert key.aamm == "2610"
    assert key.issuer_cnpj == "46395687000455"
    assert key.model == "55"
    assert key.series == "099"
    assert key.invoice_number == "004241885"
    assert key.emission_type == "1"
    assert key.numeric_code == "12345678"
    assert key.check_digit == "0"


def test_accepts_printed_key_split_by_whitespace() -> None:
    grouped = "2926 1046 3956 8700 0455 5509 9004 2418 8511 2345 6780"
    assert normalize_nfe_access_key(grouped) == SYNTHETIC_KEY
    assert NfeAccessKey.parse(grouped).digits == SYNTHETIC_KEY


def test_rejects_invalid_check_digit() -> None:
    invalid = SYNTHETIC_KEY[:-1] + "1"
    with pytest.raises(DomainValidationError, match="check digit"):
        NfeAccessKey.parse(invalid)


@pytest.mark.parametrize(
    "value",
    [
        SYNTHETIC_KEY[:-1],
        "29.2610." + SYNTHETIC_KEY[6:],
        "A" + SYNTHETIC_KEY[1:],
    ],
)
def test_rejects_malformed_access_key(value: str) -> None:
    with pytest.raises(DomainValidationError):
        NfeAccessKey.parse(value)


def test_validated_access_key_exposes_structural_field_candidates() -> None:
    candidates = NfeAccessKey.parse(SYNTHETIC_KEY).field_candidates(page=0)

    assert [(candidate.field, candidate.normalized_value) for candidate in candidates] == [
        (FiscalField.INVOICE_NUMBER, "004241885"),
        (FiscalField.SERIES, "099"),
        (FiscalField.ISSUER_CNPJ, "46395687000455"),
    ]
    assert all(candidate.source == CandidateSource.NFE_ACCESS_KEY for candidate in candidates)
    assert all(candidate.page == 0 for candidate in candidates)
    assert all(candidate.ocr_score is None for candidate in candidates)
