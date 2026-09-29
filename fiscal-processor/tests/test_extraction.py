from pathlib import Path

import pytest

from fiscal_processor.adapters.ocr import OcrAdapterError, RapidSmallAdapter
from fiscal_processor.adapters.ocr.rapid_small import MODELS
from fiscal_processor.application.extraction import (
    extract_evidence,
    native_text_is_useful,
    parse_evidence,
)
from fiscal_processor.domain import ExtractionMode, ProcessingStatus, QualityFlag
from fiscal_processor.domain.text import (
    OcrPage,
    PdfDocumentContent,
    PdfPageContent,
    PdfTextBlock,
    RenderedPage,
    TextSpan,
)


class Pdf:
    def __init__(self, texts):
        self.pages = tuple(
            PdfPageContent(i, 612, 792, t, (PdfTextBlock(t, 10, 20, 100, 40),))
            for i, t in enumerate(texts)
        )
        self.rendered = []

    def extract_document(self, path):
        return PdfDocumentContent(self.pages)

    def render_page(self, path, page_index, *, dpi=300):
        self.rendered.append(page_index)
        return RenderedPage(page_index, 1, 1, 3, "RGB", b"\xff\xff\xff", dpi)


class Ocr:
    def __init__(self, low=False):
        self.calls = []
        self.low = low

    def recognize(self, page, page_index):
        self.calls.append(page_index)
        return OcrPage((TextSpan("NFS-e", 0, 0, 50, 10, page_index),), self.low)


def test_native_page_does_not_load_ocr_or_render(tmp_path):
    pdf = Pdf(["A" * 50])
    result = extract_evidence(Path("synthetic.pdf"), pdf, RapidSmallAdapter(tmp_path / "absent"))
    assert not pdf.rendered
    assert result.mode == ExtractionMode.NATIVE_TEXT
    assert result.spans[0].top == 752


def test_mixed_document_renders_only_pages_without_useful_text():
    pdf = Pdf(["A" * 50, "", "x"])
    ocr = Ocr()
    result = extract_evidence(Path("synthetic.pdf"), pdf, ocr)
    assert pdf.rendered == ocr.calls == [1, 2]
    assert result.mode == ExtractionMode.MIXED
    assert [s.page for s in result.spans] == [0, 1, 2]


def test_ocr_warning_survives_parsing():
    evidence = extract_evidence(Path("synthetic.pdf"), Pdf([""]), Ocr(low=True))
    result = parse_evidence(evidence, source_sha256="a" * 64, source_filename="synthetic.pdf")
    assert result.extraction_mode == ExtractionMode.OCR
    assert result.status == ProcessingStatus.REVIEW
    assert QualityFlag.OCR_LOW_QUALITY in result.quality_flags


@pytest.mark.parametrize("text", ["", "123", "\ufffd" * 80, "A" * 40 + "\ufffd" * 20])
def test_bad_text_is_not_useful(text):
    assert not native_text_is_useful(text)


@pytest.mark.parametrize("corrupt", [False, True])
def test_missing_or_corrupt_model_fails_before_engine_import(tmp_path, corrupt, monkeypatch):
    import builtins

    original = builtins.__import__

    def guard(name, *args, **kwargs):
        if name == "rapidocr":
            pytest.fail("must validate models before importing engine")
        return original(name, *args, **kwargs)

    monkeypatch.setattr(builtins, "__import__", guard)
    if corrupt:
        (tmp_path / MODELS["Det"][0]).write_bytes(b"invalid")
    with pytest.raises(
        OcrAdapterError, match="^OCR_MODEL_INVALID$" if corrupt else "^OCR_INITIALIZATION_FAILED$"
    ):
        RapidSmallAdapter(tmp_path).recognize(RenderedPage(0, 1, 1, 3, "RGB", b"\xff" * 3, 200), 0)


def test_ocr_error_does_not_return_partial_success():
    class Broken(Ocr):
        def recognize(self, page, page_index):
            raise OcrAdapterError("OCR_RECOGNITION_FAILED")

    with pytest.raises(OcrAdapterError):
        extract_evidence(Path("synthetic.pdf"), Pdf(["A" * 50, ""]), Broken())


def test_invalid_dpi_and_empty_document_are_rejected():
    with pytest.raises(ValueError, match="DPI"):
        extract_evidence(Path("synthetic.pdf"), Pdf([""]), Ocr(), dpi=True)
    with pytest.raises(ValueError, match="EMPTY_DOCUMENT"):
        extract_evidence(Path("synthetic.pdf"), Pdf([]), Ocr())
