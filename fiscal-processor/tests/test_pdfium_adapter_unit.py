from pathlib import Path
from types import SimpleNamespace

import pytest

from fiscal_processor.adapters.pdf import PdfAdapterError, PdfiumAdapter


class FakeTextObject:
    def __init__(self, text: str, bounds: tuple[float, float, float, float]) -> None:
        self._text = text
        self._bounds = bounds

    def extract(self) -> str:
        return self._text

    def get_bounds(self) -> tuple[float, float, float, float]:
        return self._bounds


class FakeTextPage:
    def __init__(self, text: str) -> None:
        self._text = text
        self.closed = False

    def get_text_bounded(self) -> str:
        return self._text

    def close(self) -> None:
        self.closed = True


class FakeBitmap:
    def __init__(self) -> None:
        self.width = 20
        self.height = 10
        self.stride = 80
        self.mode = "RGBA"
        self.buffer = bytes(self.stride * self.height)
        self.closed = False

    def close(self) -> None:
        self.closed = True


class FakePage:
    def __init__(self) -> None:
        self.closed = False
        self.textpage = FakeTextPage("linha 1\r\nlinha 2")
        self.bitmap = FakeBitmap()

    def get_size(self) -> tuple[float, float]:
        return (612.0, 792.0)

    def get_textpage(self) -> FakeTextPage:
        return self.textpage

    def get_objects(self, **_: object) -> list[FakeTextObject]:
        return [FakeTextObject("CNPJ 12.345.678/0001-90", (10, 20, 30, 40))]

    def render(self, **_: object) -> FakeBitmap:
        return self.bitmap

    def close(self) -> None:
        self.closed = True


class FakeDocument:
    def __init__(self) -> None:
        self.page = FakePage()
        self.closed = False

    def __len__(self) -> int:
        return 1

    def __getitem__(self, index: int) -> FakePage:
        if index != 0:
            raise IndexError(index)
        return self.page

    def close(self) -> None:
        self.closed = True


class FakePdfium:
    def __init__(self, document: FakeDocument | None = None, *, fail_open: bool = False) -> None:
        self.document = document or FakeDocument()
        self.fail_open = fail_open

    def PdfDocument(self, _: Path) -> FakeDocument:
        if self.fail_open:
            raise RuntimeError("corrupt")
        return self.document


def _adapter(pdfium: FakePdfium | None = None) -> PdfiumAdapter:
    return PdfiumAdapter(
        pdfium_module=pdfium or FakePdfium(),
        pdfium_raw_module=SimpleNamespace(FPDF_PAGEOBJ_TEXT=1),
    )


def test_extract_document_normalizes_text_and_copies_bounds(tmp_path: Path) -> None:
    adapter = _adapter()

    result = adapter.extract_document(tmp_path / "fixture.pdf")

    assert result.text == "linha 1\nlinha 2"
    assert result.pages[0].blocks[0].text == "CNPJ 12.345.678/0001-90"
    assert result.pages[0].blocks[0].left == 10


def test_render_page_copies_bitmap_before_closing(tmp_path: Path) -> None:
    document = FakeDocument()
    adapter = _adapter(FakePdfium(document))

    result = adapter.render_page(tmp_path / "fixture.pdf", 0, dpi=300)

    assert result.width == 20
    assert result.height == 10
    assert len(result.pixels) == 800
    assert document.page.bitmap.closed is True
    assert document.page.closed is True
    assert document.closed is True


def test_invalid_dpi_is_rejected_without_opening_document(tmp_path: Path) -> None:
    adapter = _adapter()

    with pytest.raises(ValueError, match="dpi"):
        adapter.render_page(tmp_path / "fixture.pdf", 0, dpi=0)


def test_open_failure_is_wrapped(tmp_path: Path) -> None:
    adapter = _adapter(FakePdfium(fail_open=True))

    with pytest.raises(PdfAdapterError, match="unable to open PDF"):
        adapter.extract_document(tmp_path / "broken.pdf")
