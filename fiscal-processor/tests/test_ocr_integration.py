"""Opt-in real OCR smoke; never downloads models and only creates synthetic PDFs."""

import os
import socket
from decimal import Decimal
from pathlib import Path

import pytest

from benchmarks.spatial_corpus import cases, write_pdf
from fiscal_processor.adapters.ocr import RapidSmallAdapter
from fiscal_processor.adapters.pdf import PdfiumAdapter
from fiscal_processor.application.extraction import extract_evidence, parse_evidence
from fiscal_processor.domain import ExtractionMode, ProcessingStatus, QualityFlag


@pytest.mark.skipif(
    not os.environ.get("FISCAL_OCR_MODELS"), reason="local OCR models not provisioned"
)
def test_real_raster_pdf_ocr_and_parser_without_python_network(tmp_path, monkeypatch):
    from PIL import Image

    def deny(*args, **kwargs):
        raise AssertionError("network forbidden during inference")

    monkeypatch.setattr(socket.socket, "connect", deny)
    monkeypatch.setattr(socket, "getaddrinfo", deny)
    pdf = PdfiumAdapter()
    ocr = RapidSmallAdapter(Path(os.environ["FISCAL_OCR_MODELS"]))
    for index, case in enumerate(cases()[:2]):
        source = tmp_path / f"native-{index}.pdf"
        scanned = tmp_path / f"scanned-{index}.pdf"
        write_pdf(source, case)
        rendered = pdf.render_page(source, 0, dpi=200)
        with Image.frombytes(
            "RGB",
            (rendered.width, rendered.height),
            rendered.pixels,
            "raw",
            rendered.mode,
            rendered.stride,
        ) as image:
            image.save(scanned, "PDF", resolution=200)
        assert not pdf.extract_document(scanned).text.strip()
        evidence = extract_evidence(scanned, pdf, ocr)
        result = parse_evidence(evidence, source_sha256="a" * 64, source_filename="synthetic.pdf")
        assert result.extraction_mode == ExtractionMode.OCR
        assert result.status == ProcessingStatus.OK
        assert result.invoice_number == case.expected["number"]
        assert result.series == case.expected["series"]
        assert result.issuer_cnpj == "12345678000195"
        assert result.issuer_name == case.expected["issuer"]
        assert result.recipient_name == case.expected["recipient"]
        assert result.amount == Decimal(case.expected["amount"].replace(".", "").replace(",", "."))
    blank = tmp_path / "blank.pdf"
    with Image.new("RGB", (612, 792), "white") as image:
        image.save(blank, "PDF", resolution=72)
    evidence = extract_evidence(blank, pdf, ocr)
    assert not evidence.spans
    assert QualityFlag.OCR_LOW_QUALITY in evidence.flags
