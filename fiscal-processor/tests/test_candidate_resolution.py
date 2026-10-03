from fiscal_processor.domain import (
    CandidateSource,
    FieldCandidate,
    FiscalField,
    ResolutionStatus,
    resolve_field_candidates,
)


def candidate(field, value, source):
    return FieldCandidate(
        field=field,
        raw_value=value,
        normalized_value=value,
        source=source,
    )


def test_missing_field_is_explicit() -> None:
    result = resolve_field_candidates(FiscalField.INVOICE_NUMBER, ())
    assert result.status == ResolutionStatus.MISSING
    assert result.selected is None


def test_equivalent_visual_and_key_series_resolve_without_losing_key_padding() -> None:
    result = resolve_field_candidates(
        FiscalField.SERIES,
        (
            candidate(FiscalField.SERIES, "99", CandidateSource.NATIVE_TEXT),
            candidate(FiscalField.SERIES, "099", CandidateSource.NFE_ACCESS_KEY),
        ),
    )
    assert result.status == ResolutionStatus.RESOLVED
    assert result.selected is not None
    assert result.selected.normalized_value == "099"
    assert result.selected.source == CandidateSource.NFE_ACCESS_KEY


def test_different_values_from_same_source_are_ambiguous() -> None:
    result = resolve_field_candidates(
        FiscalField.INVOICE_NUMBER,
        (
            candidate(FiscalField.INVOICE_NUMBER, "100", CandidateSource.NATIVE_TEXT),
            candidate(FiscalField.INVOICE_NUMBER, "200", CandidateSource.NATIVE_TEXT),
        ),
    )
    assert result.status == ResolutionStatus.AMBIGUOUS
    assert result.selected is None


def test_different_values_across_sources_are_conflict() -> None:
    result = resolve_field_candidates(
        FiscalField.INVOICE_NUMBER,
        (
            candidate(FiscalField.INVOICE_NUMBER, "100", CandidateSource.NATIVE_TEXT),
            candidate(FiscalField.INVOICE_NUMBER, "200", CandidateSource.NFE_ACCESS_KEY),
        ),
    )
    assert result.status == ResolutionStatus.CONFLICT
    assert result.selected is None
