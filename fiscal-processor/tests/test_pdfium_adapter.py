from pathlib import Path

import pytest

pytest.importorskip("pypdfium2")

from fiscal_processor.adapters.pdf import PdfAdapterError, PdfiumAdapter


def _synthetic_pdf(text: str = "NFE TESTE 004241885") -> bytes:
    """Build a tiny valid PDF using only standard PDF primitives."""

    escaped = text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
    stream = f"BT /F1 12 Tf 72 720 Td ({escaped}) Tj ET\n".encode("latin-1")
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        (
            b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
            b"/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>"
        ),
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Length "
        + str(len(stream)).encode("ascii")
        + b" >>\nstream\n"
        + stream
        + b"endstream",
    ]

    data = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets = [0]
    for index, obj in enumerate(objects, start=1):
        offsets.append(len(data))
        data.extend(f"{index} 0 obj\n".encode("ascii"))
        data.extend(obj)
        data.extend(b"\nendobj\n")

    xref_offset = len(data)
    data.extend(f"xref\n0 {len(objects) + 1}\n".encode("ascii"))
    data.extend(b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        data.extend(f"{offset:010d} 00000 n \n".encode("ascii"))
    data.extend(
        (
            f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\n"
            f"startxref\n{xref_offset}\n%%EOF\n"
        ).encode("ascii")
    )
    return bytes(data)


def _write_pdf(tmp_path: Path, content: bytes) -> Path:
    path = tmp_path / "synthetic.pdf"
    path.write_bytes(content)
    return path


def test_extracts_native_text_and_positioned_blocks(tmp_path: Path) -> None:
    adapter = PdfiumAdapter()
    path = _write_pdf(tmp_path, _synthetic_pdf())

    document = adapter.extract_document(path)

    assert len(document.pages) == 1
    page = document.pages[0]
    assert "NFE TESTE 004241885" in page.text
    assert page.width_points == pytest.approx(612)
    assert page.height_points == pytest.approx(792)
    assert any("NFE TESTE 004241885" in block.text for block in page.blocks)
    assert all(block.right >= block.left for block in page.blocks)
    assert all(block.top >= block.bottom for block in page.blocks)


def test_renders_page_to_owned_pixel_buffer(tmp_path: Path) -> None:
    adapter = PdfiumAdapter()
    path = _write_pdf(tmp_path, _synthetic_pdf())

    rendered = adapter.render_page(path, 0, dpi=144)

    assert rendered.width == 1224
    assert rendered.height == 1584
    assert rendered.dpi == 144
    assert rendered.mode in {"RGB", "RGBX", "RGBA", "BGR", "BGRX", "BGRA"}
    assert len(rendered.pixels) == rendered.stride * rendered.height


def test_rejects_page_outside_document(tmp_path: Path) -> None:
    adapter = PdfiumAdapter()
    path = _write_pdf(tmp_path, _synthetic_pdf())

    with pytest.raises(IndexError):
        adapter.render_page(path, 1)


def test_wraps_corrupt_pdf_open_error(tmp_path: Path) -> None:
    adapter = PdfiumAdapter()
    path = _write_pdf(tmp_path, b"not a pdf")

    with pytest.raises(PdfAdapterError, match="unable to open PDF"):
        adapter.extract_document(path)


@pytest.mark.parametrize("dpi", [72, 150, 200, 250, 300])
def test_real_render_dimensions_and_pixels_survive_close(tmp_path: Path, dpi: int) -> None:
    import math

    path = _write_pdf(tmp_path, _synthetic_pdf())
    adapter = PdfiumAdapter()
    rendered = adapter.render_page(path, 0, dpi=dpi)
    assert rendered.width == math.ceil(612 * (dpi / 72))
    assert rendered.height == math.ceil(792 * (dpi / 72))
    assert len(rendered.pixels) == rendered.stride * rendered.height
    assert min(rendered.pixels) < 255  # Actual glyphs, not just a white buffer.
    original = rendered.pixels
    adapter.render_page(path, 0, dpi=72)
    path.unlink()
    assert rendered.pixels == original


def test_blank_page_has_no_text_or_blocks(tmp_path: Path) -> None:
    path = _write_pdf(tmp_path, _synthetic_pdf(""))
    page = PdfiumAdapter().extract_document(path).pages[0]
    assert page.text == ""
    assert page.blocks == ()


def test_render_limit_rejects_before_allocation(tmp_path: Path) -> None:
    path = _write_pdf(tmp_path, _synthetic_pdf())
    with pytest.raises(PdfAdapterError, match="pixel limit"):
        PdfiumAdapter(max_render_pixels=100).render_page(path, 0)


def test_page_limit_with_real_multipage_pdf(tmp_path: Path) -> None:
    import pypdfium2

    path = tmp_path / "pages.pdf"
    with pypdfium2.PdfDocument.new() as document:
        for _ in range(2):
            document.new_page(72, 72).close()
        document.save(path)
    adapter = PdfiumAdapter(max_pages=1)
    with pytest.raises(PdfAdapterError, match="page limit"):
        adapter.extract_document(path)
    with pytest.raises(PdfAdapterError, match="page limit"):
        adapter.render_page(path, 0)


@pytest.mark.parametrize("dpi", [-1, 0, 601, float("inf"), float("nan"), 72.5, True])
def test_invalid_dpi_never_opens_input(tmp_path: Path, dpi: int) -> None:
    with pytest.raises(ValueError, match="dpi"):
        PdfiumAdapter().render_page(tmp_path / "missing.pdf", 0, dpi=dpi)
