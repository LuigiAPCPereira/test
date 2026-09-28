"""Failure cleanup regression tests supplement real PDF integration tests."""

from pathlib import Path
from types import SimpleNamespace

import pytest
from test_pdfium_adapter_unit import FakeDocument, FakePdfium, _adapter

from fiscal_processor.adapters.pdf import PdfAdapterError, PdfiumAdapter


def test_render_limit_closes_page_and_document(tmp_path: Path) -> None:
    doc = FakeDocument()
    adapter = PdfiumAdapter(
        FakePdfium(doc), SimpleNamespace(FPDF_PAGEOBJ_TEXT=1), max_render_pixels=1
    )
    with pytest.raises(PdfAdapterError, match="pixel limit"):
        adapter.render_page(tmp_path / "fake.pdf", 0)
    assert doc.closed
    assert doc.page.closed
    assert not doc.page.bitmap.closed  # Bitmap was never acquired.


def test_text_failure_closes_all_acquired_handles(tmp_path: Path, monkeypatch) -> None:
    doc = FakeDocument()

    def fail():
        raise RuntimeError("text failure")

    monkeypatch.setattr(doc.page.textpage, "get_text_bounded", fail)
    with pytest.raises(PdfAdapterError):
        _adapter(FakePdfium(doc)).extract_document(tmp_path / "fake.pdf")
    assert doc.closed
    assert doc.page.closed
    assert doc.page.textpage.closed
