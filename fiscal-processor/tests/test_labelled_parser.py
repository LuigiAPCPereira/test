from datetime import date
from decimal import Decimal

import pytest

from fiscal_processor.domain import DocumentType, ProcessingStatus, QualityFlag
from fiscal_processor.parsers import parse_invoice

BASE = [
    "NOTA FISCAL DE SERVIÇOS ELETRÔNICA",
    "DADOS DA NFSE",
    "Número / Série",
    "000987 / A1",
    "Data e hora de emissão",
    "28/09/2026 11:34:29",
    "EMITENTE PRESTADOR DO SERVIÇO",
    "CPF / CNPJ / NIF",
    "12.345.678/0001-95",
    "Nome / Nome Empresarial",
    "OFICINA SINTÉTICA LTDA",
    "TOMADOR DO SERVIÇO",
    "CPF / CNPJ / NIF",
    "11.111.111/1111-11",
    "Nome / Nome Empresarial",
    "TRANSPORTES FICTÍCIOS SA",
    "CÁLCULO DO ISSQN",
    "Valor total da NFSe (R$)",
    "1.234,56",
    "Base de cálculo do ISSQN (R$)",
    "1.000,00",
    "VALOR TOTAL",
    "Valor líquido da NFSe (R$)",
    "999,00",
    "INFORMAÇÕES COMPLEMENTARES",
    "OS 999999 - validade 31/12/2026",
]


def parse(lines):
    return parse_invoice(lines, source_sha256="a" * 64, source_filename="synthetic.pdf")


def test_sectioned_nfse_separates_parties_total_and_manual_annotations():
    result = parse(BASE)
    assert result.status == ProcessingStatus.OK
    assert result.document_type == DocumentType.NFSE
    assert result.invoice_number == "000987"
    assert result.series == "A1"
    assert result.issue_date == date(2026, 9, 28)
    assert result.issuer_cnpj == "12345678000195"
    assert result.issuer_name == "OFICINA SINTÉTICA LTDA"
    assert result.recipient_name == "TRANSPORTES FICTÍCIOS SA"
    assert result.amount == Decimal("1234.56")
    assert not hasattr(result, "os_number")


def test_explicit_danfe_labels():
    result = parse(
        [
            "DANFE",
            "Número da NF: 000123",
            "Série: 001",
            "Data de emissão: 28/09/2026",
            "CNPJ do emitente: 12.345.678/0001-95",
            "Razão social do emitente: FÁBRICA SINTÉTICA",
            "Razão social do destinatário: CLIENTE SINTÉTICO",
            "Valor total da nota: 112.000,00",
        ]
    )
    assert result.status == ProcessingStatus.OK
    assert result.document_type == DocumentType.NFE
    assert result.amount == Decimal("112000.00")


@pytest.mark.parametrize(
    ("old", "new", "flag", "attribute"),
    [
        ("1.234,56", "1.234", QualityFlag.INVALID_AMOUNT, "amount"),
        ("1.234,56", "1,234.56", QualityFlag.INVALID_AMOUNT, "amount"),
        ("28/09/2026 11:34:29", "31/02/2026", QualityFlag.INVALID_ISSUE_DATE, "issue_date"),
        ("12.345.678/0001-95", "12.345.678/0001-00", QualityFlag.INVALID_CNPJ, "issuer_cnpj"),
        ("000987 / A1", "foo bar / A1", QualityFlag.INVALID_IDENTIFIER, "invoice_number"),
    ],
)
def test_invalid_values_are_empty_and_reviewed(old, new, flag, attribute):
    result = parse([new if line == old else line for line in BASE])
    assert getattr(result, attribute) is None
    assert flag in result.quality_flags
    assert result.status == ProcessingStatus.REVIEW


def test_duplicate_total_even_equal_is_ambiguous():
    result = parse([*BASE, "Valor total da NFSe (R$): 1.234,56"])
    assert result.amount is None
    assert QualityFlag.AMBIGUOUS_AMOUNT in result.quality_flags


def test_missing_total_does_not_use_tax_base_or_net_value():
    result = parse([line for line in BASE if line not in {"Valor total da NFSe (R$)", "1.234,56"}])
    assert result.amount is None
    assert QualityFlag.MISSING_AMOUNT in result.quality_flags


def test_missing_issuer_cnpj_never_uses_recipient_cnpj():
    result = parse([line for line in BASE if line != "12.345.678/0001-95"])
    assert result.issuer_cnpj is None
    assert QualityFlag.MISSING_ISSUER_CNPJ in result.quality_flags


@pytest.mark.parametrize("lines", [["COMPROVANTE DE PAGAMENTO"], ["DANFE", "NFS-E"], []])
def test_unknown_or_conflicting_document_markers(lines):
    result = parse(lines)
    assert result.document_type == DocumentType.UNKNOWN
    assert result.status == ProcessingStatus.REVIEW
    assert result.amount is None


def test_real_pdfium_text_to_parser(tmp_path):
    from benchmarks.spatial_corpus import SpatialCase, write_pdf
    from fiscal_processor.adapters.pdf import PdfiumAdapter

    # New fully synthetic PDF; parser does not consume benchmark answers.
    case = SpatialCase(
        "parser-integration",
        "development",
        (tuple((40, 30 + i * 22, 10, line) for i, line in enumerate(BASE)),),
        {},
    )
    path = tmp_path / "synthetic.pdf"
    write_pdf(path, case)
    result = parse(PdfiumAdapter().extract_document(path).text.splitlines())
    assert result.status == ProcessingStatus.OK
    assert result.issuer_cnpj == "12345678000195"
    assert result.amount == Decimal("1234.56")
