from fiscal_processor.domain import (
    CandidateSource,
    FieldCandidate,
    FiscalField,
    ResolutionStatus,
)
from fiscal_processor.domain.text import TextSpan
from fiscal_processor.parsers import (
    find_nfe_access_key_candidates,
    resolve_nfe_structural_candidates,
)

SYNTHETIC_KEY = "29261046395687000455550990042418851123456780"


def box(text, x, y, page=0, width=100):
    return TextSpan(text, x, y, x + width, y + 10, page)


def test_recomposes_grouped_access_key_below_label() -> None:
    groups = [SYNTHETIC_KEY[index : index + 4] for index in range(0, 44, 4)]
    spans = [box("CHAVE DE ACESSO", 20, 40, width=130)]
    spans.extend(box(group, 20 + index * 34, 60, width=30) for index, group in enumerate(groups))

    candidates = find_nfe_access_key_candidates(spans)

    assert [(candidate.field, candidate.normalized_value) for candidate in candidates] == [
        (FiscalField.INVOICE_NUMBER, "004241885"),
        (FiscalField.SERIES, "099"),
        (FiscalField.ISSUER_CNPJ, "46395687000455"),
    ]
    assert all(candidate.source == CandidateSource.NFE_ACCESS_KEY for candidate in candidates)
    assert all(candidate.page == 0 for candidate in candidates)


def test_rejects_unlabelled_or_invalid_44_digit_sequences() -> None:
    invalid = SYNTHETIC_KEY[:-1] + "1"
    spans = [
        box(SYNTHETIC_KEY, 20, 20, width=360),
        box("CHAVE DE ACESSO", 20, 80, width=130),
        box(invalid, 20, 100, width=360),
    ]
    assert find_nfe_access_key_candidates(spans) == ()


def test_key_and_equivalent_visual_series_resolve_as_agreement() -> None:
    key_span = box(
        "CHAVE DE ACESSO " + " ".join(
            SYNTHETIC_KEY[index : index + 4] for index in range(0, 44, 4)
        ),
        20,
        40,
        width=420,
    )
    visual = FieldCandidate(
        field=FiscalField.SERIES,
        raw_value="99",
        normalized_value="99",
        source=CandidateSource.NATIVE_TEXT,
        page=0,
    )

    resolutions = resolve_nfe_structural_candidates((key_span,), (visual,))
    series = next(result for result in resolutions if result.field == FiscalField.SERIES)

    assert series.status == ResolutionStatus.RESOLVED
    assert series.selected is not None
    assert series.selected.normalized_value == "099"
    assert series.selected.source == CandidateSource.NFE_ACCESS_KEY


def test_key_and_different_visual_number_stay_conflict() -> None:
    key_span = box(
        "CHAVE DE ACESSO " + " ".join(
            SYNTHETIC_KEY[index : index + 4] for index in range(0, 44, 4)
        ),
        20,
        40,
        width=420,
    )
    visual = FieldCandidate(
        field=FiscalField.INVOICE_NUMBER,
        raw_value="000000999",
        normalized_value="000000999",
        source=CandidateSource.NATIVE_TEXT,
        page=0,
    )

    resolutions = resolve_nfe_structural_candidates((key_span,), (visual,))
    number = next(result for result in resolutions if result.field == FiscalField.INVOICE_NUMBER)

    assert number.status == ResolutionStatus.CONFLICT
    assert number.selected is None
