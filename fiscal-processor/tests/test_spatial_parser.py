from decimal import Decimal

import pytest

from benchmarks.spatial_corpus import cases, write_pdf
from fiscal_processor.adapters.pdf import PdfiumAdapter
from fiscal_processor.domain import DocumentType, ProcessingStatus, QualityFlag
from fiscal_processor.domain.text import TextSpan
from fiscal_processor.parsers import parse_spans


def parse(spans):
    return parse_spans(spans, source_sha256="a" * 64, source_filename="synthetic.pdf")


def box(text, x, y, page=0):
    return TextSpan(text, x, y, x + 100, y + 10, page)


@pytest.mark.parametrize("case", cases(), ids=lambda c: c.name)
def test_real_pdf_native_boxes_reach_production_parser(tmp_path, case):
    path = tmp_path / "synthetic.pdf"
    write_pdf(path, case)
    result = parse(PdfiumAdapter().extract_spans(path))
    assert result.parser_id == "spatial-labelled-v1"
    if case.expected["type"] is None:
        assert result.document_type == DocumentType.UNKNOWN
        assert result.amount is None
        return
    assert result.invoice_number == case.expected["number"]
    assert result.series == case.expected["series"]
    assert result.issuer_name == case.expected["issuer"]
    assert result.recipient_name == case.expected["recipient"]
    assert result.issuer_cnpj == "12345678000195"
    expected = case.expected["amount"]
    assert result.amount == (
        Decimal(expected.replace(".", "").replace(",", ".")) if expected else None
    )
    assert result.status == (ProcessingStatus.OK if expected else ProcessingStatus.REVIEW)


def test_headers_scope_repeated_names_and_cnpjs():
    result = parse(
        [
            box("NFS-e", 0, 0),
            box("EMITENTE PRESTADOR DO SERVIÇO", 0, 30),
            box("CPF / CNPJ / NIF", 20, 60),
            box("12.345.678/0001-95", 20, 80),
            box("Nome / Nome Empresarial", 20, 120),
            box("PRESTADORA SINTÉTICA", 20, 140),
            box("TOMADOR DO SERVIÇO", 0, 180),
            box("CPF / CNPJ / NIF", 20, 210),
            box("11.111.111/1111-11", 20, 230),
            box("Nome / Nome Empresarial", 20, 270),
            box("CLIENTE SINTÉTICO", 20, 290),
        ]
    )
    assert result.issuer_name == "PRESTADORA SINTÉTICA"
    assert result.recipient_name == "CLIENTE SINTÉTICO"
    assert result.issuer_cnpj == "12345678000195"


def test_never_matches_value_on_another_page_or_column():
    result = parse(
        [
            box("DANFE", 0, 0),
            box("VALOR TOTAL DA NOTA", 20, 50),
            box("9,99", 300, 70),
            box("8,88", 20, 70, page=1),
        ]
    )
    assert result.amount is None
    assert QualityFlag.MISSING_AMOUNT in result.quality_flags


def test_two_spatial_candidates_stay_ambiguous():
    result = parse(
        [
            box("DANFE", 0, 0),
            box("VALOR TOTAL DA NOTA", 20, 50),
            box("9,99", 20, 70),
            box("8,88", 22, 71),
        ]
    )
    assert result.amount is None
    assert QualityFlag.AMBIGUOUS_AMOUNT in result.quality_flags


def test_section_boundary_prevents_borrowing_value():
    result = parse(
        [
            box("NFS-e", 0, 0),
            box("EMITENTE PRESTADOR DO SERVIÇO", 0, 30),
            box("Nome / Nome Empresarial", 20, 60),
            box("TOMADOR DO SERVIÇO", 0, 72),
            box("CLIENTE", 20, 80),
        ]
    )
    assert result.issuer_name is None


def test_party_scope_never_carries_over_to_another_page():
    result = parse(
        [
            box("NFS-e", 0, 0),
            box("EMITENTE PRESTADOR DO SERVIÇO", 0, 30),
            box("Nome / Nome Empresarial", 20, 60, page=1),
            box("CLIENTE", 20, 80, page=1),
        ]
    )
    assert result.issuer_name is None


@pytest.mark.parametrize("coordinates", [(0, 10, 20, 0), (float("nan"), 0, 10, 10)])
def test_invalid_coordinates_are_rejected(coordinates):
    with pytest.raises(ValueError):
        TextSpan("text", *coordinates)


def test_amount_may_be_in_same_row_to_the_right_of_its_label():
    result = parse(
        [
            box("DANFE", 0, 0),
            box("VALOR TOTAL DA NOTA", 20, 50),
            box("1.234,56", 145, 50),
        ]
    )
    assert result.amount == Decimal("1234.56")
    assert QualityFlag.MISSING_AMOUNT not in result.quality_flags
