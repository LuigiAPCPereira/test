from fiscal_processor.domain import (
    CandidateSource,
    FiscalField,
    ResolutionStatus,
)
from fiscal_processor.domain.text import TextSpan
from fiscal_processor.parsers import (
    find_nfe_visual_candidates,
    resolve_nfe_danfe_candidates,
)

SYNTHETIC_KEY = "29261046395687000455550990042418851123456780"


def box(text, x, y, page=0, width=100):
    return TextSpan(text, x, y, x + width, y + 10, page)


def danfe_spans(*, visual_number="004241885", visual_series="99", issuer_cnpj="46.395.687/0004-55"):
    return (
        box("DANFE - DOCUMENTO AUXILIAR DA NOTA FISCAL ELETRÔNICA", 20, 20, width=340),
        box(f"Nº {visual_number} SÉRIE {visual_series}", 380, 20, width=220),
        box("IDENTIFICAÇÃO DO EMITENTE", 20, 70, width=200),
        box("CNPJ", 20, 95, width=60),
        box(issuer_cnpj, 20, 115, width=150),
        box("CHAVE DE ACESSO", 20, 160, width=130),
        box(
            " ".join(SYNTHETIC_KEY[index : index + 4] for index in range(0, 44, 4)),
            20,
            180,
            width=420,
        ),
    )


def test_visual_danfe_emits_number_series_and_issuer_cnpj_candidates() -> None:
    candidates = find_nfe_visual_candidates(danfe_spans())

    observed = {(candidate.field, candidate.normalized_value) for candidate in candidates}
    assert (FiscalField.INVOICE_NUMBER, "004241885") in observed
    assert (FiscalField.SERIES, "99") in observed
    assert (FiscalField.ISSUER_CNPJ, "46395687000455") in observed
    assert all(candidate.source == CandidateSource.NATIVE_TEXT for candidate in candidates)
    assert all(candidate.page == 0 for candidate in candidates)


def test_recipient_cnpj_is_not_emitted_as_issuer_candidate() -> None:
    spans = (
        box("DANFE", 20, 20),
        box("DESTINATÁRIO / REMETENTE", 20, 70, width=180),
        box("CNPJ", 20, 95, width=60),
        box("11.111.111/1111-11", 20, 115, width=150),
    )
    assert find_nfe_visual_candidates(spans) == ()


def test_access_key_and_visual_danfe_resolve_structural_fields() -> None:
    resolutions = resolve_nfe_danfe_candidates(danfe_spans())
    by_field = {resolution.field: resolution for resolution in resolutions}

    for field in (
        FiscalField.INVOICE_NUMBER,
        FiscalField.SERIES,
        FiscalField.ISSUER_CNPJ,
    ):
        assert by_field[field].status == ResolutionStatus.RESOLVED
        assert by_field[field].selected is not None
        assert by_field[field].selected.source == CandidateSource.NFE_ACCESS_KEY

    assert by_field[FiscalField.SERIES].selected.normalized_value == "099"


def test_visual_number_disagreement_with_valid_key_remains_conflict() -> None:
    resolutions = resolve_nfe_danfe_candidates(danfe_spans(visual_number="000000999"))
    number = next(
        resolution
        for resolution in resolutions
        if resolution.field == FiscalField.INVOICE_NUMBER
    )

    assert number.status == ResolutionStatus.CONFLICT
    assert number.selected is None
