"""Synthetic fiscal-like tables and independent, accented evaluation fixtures."""

from dataclasses import dataclass
from pathlib import Path

from .spatial import ALIASES


@dataclass(frozen=True)
class SpatialCase:
    name: str
    split: str
    # x, top-of-baseline, font size, text. Never supplied to the field locator.
    pages: tuple[tuple[tuple[int, int, int, str], ...], ...]
    expected: dict[str, str | None]


def _page(
    kind: str, values: dict[str, str], *, alternate: bool = False, missing_amount: bool = False
) -> tuple:
    labels = {
        "number": "NÚMERO DA NOTA" if alternate else "NÚMERO DA NF",
        "series": "SÉRIE",
        "date": "DATA DE EMISSÃO",
        "cnpj": "CNPJ DO PRESTADOR" if alternate else "CNPJ DO EMITENTE",
        "issuer": "RAZÃO SOCIAL DO PRESTADOR" if alternate else "RAZÃO SOCIAL DO EMITENTE",
        "recipient": "RAZÃO SOCIAL DO TOMADOR" if alternate else "RAZÃO SOCIAL DO DESTINATÁRIO",
        "amount": "VALOR TOTAL DOS SERVIÇOS" if alternate else "VALOR TOTAL DA NOTA",
    }
    # Alternate layout changes positions and reading order, not the locator.
    positions = {
        "number": (40, 120),
        "series": (330, 120),
        "date": (40, 190),
        "cnpj": (330, 190),
        "issuer": (40, 260),
        "recipient": (40, 330),
        "amount": (330, 400),
    }
    if alternate:
        positions.update(
            number=(330, 120),
            series=(40, 120),
            date=(330, 190),
            cnpj=(40, 190),
            issuer=(40, 330),
            recipient=(40, 260),
            amount=(40, 400),
        )
    text = [
        (40, 35, 9, "DOCUMENTO SINTÉTICO - SEM VALIDADE FISCAL"),
        (40, 70, 18, "DANFE" if kind == "NFE" else "NFS-e"),
    ]
    for key, (x, y) in positions.items():
        text.append((x, y, 8, labels[key]))
        if not (missing_amount and key == "amount"):
            text.append((x, y + 21, 11, values[key]))
    other_x = 330 if alternate else 40
    text.extend(
        [
            (other_x, 400, 8, "BASE DE CÁLCULO"),
            (other_x, 421, 11, "112.000,80"),
            (40, 490, 8, "CNPJ DO TOMADOR"),
            (40, 511, 11, "98.765.432/0001-98"),
            (330, 490, 8, "DATA DO PROTOCOLO"),
            (330, 511, 11, "30/09/2026"),
        ]
    )
    return tuple(text)


def cases() -> tuple[SpatialCase, ...]:
    values = {
        "number": "00123456",
        "series": "009",
        "date": "28/09/2026",
        "cnpj": "12.345.678/0001-95",
        "issuer": "OFICINA SÃO JOSÉ LTDA",
        "recipient": "COMÉRCIO FICTÍCIO SA",
        "amount": "112.000,00",
    }
    alternate = {
        **values,
        "number": "00000981",
        "series": "A2",
        "date": "03/08/2026",
        "issuer": "MANUTENÇÃO SINTÉTICA LTDA",
        "recipient": "SERVIÇOS ÁGUIA SA",
        "amount": "7.654,32",
    }
    page = _page("NFE", values)
    nfse = _page("NFSE", alternate, alternate=True)
    missing = _page("NFSE", alternate, alternate=True, missing_amount=True)
    duplicate = page + ((40, 560, 8, "VALOR TOTAL DA NOTA"), (40, 581, 11, "999,00"))
    empty = dict.fromkeys(["type", *ALIASES])
    return (
        SpatialCase("danfe-columns", "development", (page,), {"type": "NFE", **values}),
        SpatialCase("nfse-swapped", "evaluation", (nfse,), {"type": "NFSE", **alternate}),
        SpatialCase(
            "nfse-missing-total",
            "evaluation",
            (missing,),
            {"type": "NFSE", **alternate, "amount": None},
        ),
        SpatialCase(
            "danfe-duplicate-total",
            "evaluation",
            (duplicate,),
            {"type": "NFE", **values, "amount": None},
        ),
        SpatialCase(
            "danfe-two-pages",
            "evaluation",
            (
                page,
                (
                    (40, 70, 12, "CONTINUAÇÃO SINTÉTICA"),
                    (40, 120, 11, "PROTOCOLO: 29/09/2026"),
                ),
            ),
            {"type": "NFE", **values},
        ),
        SpatialCase(
            "payment-not-invoice",
            "evaluation",
            (
                (
                    (40, 70, 18, "COMPROVANTE DE PAGAMENTO"),
                    (40, 120, 8, "VALOR TOTAL DA NOTA"),
                    (40, 141, 11, "112.000,00"),
                ),
            ),
            empty,
        ),
    )


def write_pdf(path: Path, case: SpatialCase) -> None:
    # WinAnsi encoding preserves Portuguese accents in the standard Helvetica font.
    objects: list[bytes] = [
        b"",
        b"",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>",
    ]
    page_ids = []
    for lines in case.pages:
        page_id = len(objects) + 1
        page_ids.append(page_id)
        commands = ["0.6 w"]
        for x, y, size, text in lines:
            escaped = text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
            commands.append(f"BT /F1 {size} Tf {x} {792 - y} Td ({escaped}) Tj ET")
            if size == 8:
                commands.append(f"{x - 3} {792 - y - 28} 265 40 re S")
        stream = "\n".join(commands).encode("cp1252")
        objects.extend(
            [
                (
                    f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
                    f"/Resources << /Font << /F1 3 0 R >> >> /Contents {page_id + 1} 0 R >>"
                ).encode(),
                b"<< /Length "
                + str(len(stream)).encode()
                + b" >>\nstream\n"
                + stream
                + b"\nendstream",
            ]
        )
    objects[0] = b"<< /Type /Catalog /Pages 2 0 R >>"
    objects[1] = (
        f"<< /Type /Pages /Kids [{' '.join(f'{i} 0 R' for i in page_ids)}] "
        f"/Count {len(page_ids)} >>"
    ).encode()
    data = bytearray(b"%PDF-1.4\n")
    offsets = [0]
    for i, obj in enumerate(objects, 1):
        offsets.append(len(data))
        data.extend(f"{i} 0 obj\n".encode() + obj + b"\nendobj\n")
    xref = len(data)
    data.extend(f"xref\n0 {len(objects) + 1}\n".encode() + b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        data.extend(f"{offset:010d} 00000 n \n".encode())
    data.extend(
        (
            f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n"
        ).encode()
    )
    path.write_bytes(data)
