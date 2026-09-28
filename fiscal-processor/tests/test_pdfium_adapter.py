from pathlib import Path

import pytest

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
        b"<< /Length " + str(len(stream)).encode("ascii") + b" >>\nstream\n" + stream + b"endstream",
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
