"""Reproducible fiscal-like PDFs, no real company or invoice data."""

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Case:
    name: str
    fields: dict[str, str]
    labels: dict[str, str]
    font_size: int = 12


CASES = (
    Case(
        "danfe",
        {
            "type": "DANFE",
            "number": "004241885",
            "series": "099",
            "date": "27/09/2026",
            "cnpj": "12.345.678/0001-95",
            "issuer": "EMITENTE SINTETICO LTDA",
            "recipient": "CLIENTE FICTICIO SA",
            "amount": "112.000,00",
        },
        {
            "type": "DOCUMENTO",
            "number": "NUMERO NF",
            "series": "SERIE",
            "date": "DATA EMISSAO",
            "cnpj": "CNPJ PRESTADOR",
            "issuer": "EMITENTE",
            "recipient": "DESTINATARIO",
            "amount": "VALOR TOTAL",
        },
    ),
    Case(
        "nfse-a",
        {
            "type": "NFS-e",
            "number": "00001234",
            "series": "A1",
            "date": "01/08/2026",
            "cnpj": "98.765.432/0001-98",
            "issuer": "SERVICOS FICTICIOS LTDA",
            "recipient": "TOMADOR SINTETICO SA",
            "amount": "9.876,54",
        },
        {
            "type": "DOCUMENTO",
            "number": "NUMERO NOTA",
            "series": "SERIE",
            "date": "EMITIDA EM",
            "cnpj": "CNPJ PRESTADOR",
            "issuer": "PRESTADOR",
            "recipient": "TOMADOR",
            "amount": "TOTAL SERVICOS",
        },
    ),
    Case(
        "nfse-small-text",
        {
            "type": "NFS-e",
            "number": "00009876",
            "series": "B2",
            "date": "02/09/2026",
            "cnpj": "12.345.678/0001-95",
            "issuer": "OFICINA SINTETICA LTDA",
            "recipient": "CLIENTE FICTICIO SA",
            "amount": "112.000,80",
        },
        {
            "type": "DOCUMENTO",
            "number": "NOTA NUMERO",
            "series": "SERIE",
            "date": "DATA EMISSAO",
            "cnpj": "CNPJ PRESTADOR",
            "issuer": "PRESTADOR",
            "recipient": "TOMADOR",
            "amount": "VALOR LIQUIDO",
        },
        8,
    ),
)


def pdf_bytes(lines: list[str], font_size: int = 12) -> bytes:
    commands = []
    for i, line in enumerate(lines):
        escaped = line.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
        commands.append(f"BT /F1 {font_size} Tf 36 {750 - i * 28} Td ({escaped}) Tj ET")
    stream = "\n".join(commands).encode("latin-1")
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
        b"/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Length " + str(len(stream)).encode() + b" >>\nstream\n" + stream + b"\nendstream",
    ]
    data = bytearray(b"%PDF-1.4\n")
    offsets = [0]
    for i, obj in enumerate(objects, 1):
        offsets.append(len(data))
        data.extend(f"{i} 0 obj\n".encode() + obj + b"\nendobj\n")
    xref = len(data)
    data.extend(b"xref\n0 6\n0000000000 65535 f \n")
    for offset in offsets[1:]:
        data.extend(f"{offset:010d} 00000 n \n".encode())
    data.extend(f"trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n".encode())
    return bytes(data)


def generate(directory: Path) -> list[tuple[Case, Path]]:
    directory.mkdir(parents=True, exist_ok=True)
    result = []
    for case in CASES:
        lines = ["DOCUMENTO SINTETICO - SEM VALIDADE FISCAL"]
        lines.extend(f"{case.labels[key]}: {value}" for key, value in case.fields.items())
        lines += [
            "BASE TRIBUTARIA: 1.234,56",
            "CNPJ TOMADOR: 11.111.111/0001-91",
            "DATA PROTOCOLO: 28/09/2026",
        ]
        path = directory / f"{case.name}.pdf"
        path.write_bytes(pdf_bytes(lines, case.font_size))
        result.append((case, path))
    return result
