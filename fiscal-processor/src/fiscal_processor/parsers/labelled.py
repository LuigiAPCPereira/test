"""Conservative parser for labelled lines in reading order.

Supported: explicit DANFE labels and sectioned NFS-e labels. Layout adapters must
preserve separate label/value lines and section order; flattened tables are not
inferred. Repeated identical number/series observations are accepted because
standard DANFE layouts repeat them; other duplicate fields remain ambiguous.
"""

import re
import unicodedata
from collections import defaultdict
from collections.abc import Sequence

from fiscal_processor.domain import (
    DocumentType,
    DomainValidationError,
    ExtractionMode,
    FiscalExtraction,
    ProcessingStatus,
    QualityFlag,
    parse_br_date,
    parse_brl_money,
    validate_cnpj,
)

LABELS = {
    "NUMERO DA NF": "number",
    "NUMERO DA NOTA": "number",
    "NUMERO DA NFS-E": "number",
    "NUMERO DA NFSE": "number",
    "NUMERO / SERIE": "combined",
    "NUMERO/SERIE": "combined",
    "SERIE": "series",
    "SERIE DA DPS": "series",
    "DATA DE EMISSAO": "date",
    "DATA DA EMISSAO": "date",
    "NO": "number",
    "N°": "number",
    "DATA E HORA DE EMISSAO": "date",
    "DATA E HORA DA EMISSAO DA NFS-E": "date",
    "DATA E HORA DA EMISSAO DA NFSE": "date",
    "CNPJ DO EMITENTE": "cnpj",
    "CNPJ DO PRESTADOR": "cnpj",
    "RAZAO SOCIAL DO EMITENTE": "issuer",
    "RAZAO SOCIAL DO PRESTADOR": "issuer",
    "RAZAO SOCIAL DO DESTINATARIO": "recipient",
    "RAZAO SOCIAL DO TOMADOR": "recipient",
    "VALOR TOTAL DA NOTA": "amount",
    "VALOR DA OPERACAO / SERVICO": "amount",
    "VALOR DA OPERACAO/SERVICO": "amount",
    "VALOR TOTAL DA NFSE (R$)": "amount",
    "VALOR TOTAL DOS SERVICOS": "amount",
}
SECTIONS = {
    "EMITENTE PRESTADOR DO SERVICO": "issuer",
    "PRESTADOR DE SERVICOS": "issuer",
    "PRESTADOR / FORNECEDOR": "issuer",
    "PRESTADOR/FORNECEDOR": "issuer",
    "TOMADOR DO SERVICO": "recipient",
    "TOMADOR DE SERVICOS": "recipient",
    "TOMADOR / ADQUIRENTE": "recipient",
    "TOMADOR/ADQUIRENTE": "recipient",
    "DESTINATARIO / REMETENTE": "recipient",
    "DESTINATARIO DA OPERACAO": "recipient",
    "IDENTIFICACAO DO EMITENTE": "issuer",
    "DADOS DA NFSE": "other",
    "SERVICO PRESTADO": "other",
    "DESCRICAO DO SERVICO PRESTADO": "other",
    "TRIBUTACAO MUNICIPAL": "other",
    "CALCULO DO ISSQN": "other",
    "RETENCOES": "other",
    "VALOR TOTAL": "other",
    "INFORMACOES COMPLEMENTARES": "other",
}
NAME_LABELS = {"NOME / NOME EMPRESARIAL", "RAZAO SOCIAL", "NOME / RAZAO SOCIAL"}
CNPJ_LABELS = {"CPF / CNPJ / NIF", "CNPJ / CPF / NIF", "CNPJ", "CNPJ / CPF"}
MISSING = {
    "number": QualityFlag.MISSING_INVOICE_NUMBER,
    "series": QualityFlag.MISSING_SERIES,
    "date": QualityFlag.MISSING_ISSUE_DATE,
    "issuer": QualityFlag.MISSING_ISSUER,
    "cnpj": QualityFlag.MISSING_ISSUER_CNPJ,
    "recipient": QualityFlag.MISSING_RECIPIENT,
    "amount": QualityFlag.MISSING_AMOUNT,
}
MONEY = re.compile(r"(?:R\$\s*)?(?:[0-9]+|[0-9]{1,3}(?:\.[0-9]{3})+),[0-9]{2}")
DATE = re.compile(r"([0-9]{2}/[0-9]{2}/[0-9]{4})(?:\s+[0-9]{2}:[0-9]{2}(?::[0-9]{2})?)?")


def normalized(text: str) -> str:
    return " ".join(
        "".join(c for c in unicodedata.normalize("NFKD", text) if not unicodedata.combining(c))
        .upper()
        .split()
    )


def parse_invoice(
    lines: Sequence[str],
    *,
    source_sha256: str,
    source_filename: str,
    extraction_mode: ExtractionMode = ExtractionMode.NATIVE_TEXT,
) -> FiscalExtraction:
    """Parse observed lines without guessing missing values or operator-owned fields."""
    text = [line.strip() for line in lines if line.strip()]
    markers = {normalized(line) for line in text}
    kinds = set()
    if any(
        marker == "DANFE"
        or marker.startswith("DANFE ")
        or "DOCUMENTO AUXILIAR DA NOTA FISCAL ELETRONICA" in marker
        for marker in markers
    ):
        kinds.add(DocumentType.NFE)
    if any(
        marker in {"NFS-E", "DANFSE", "NFSE - PRESTADOR"}
        or "DOCUMENTO AUXILIAR DA NFS-E" in marker
        or "NOTA FISCAL DE SERVICO ELETRONICA" in marker
        or "NOTA FISCAL DE SERVICOS ELETRONICA" in marker
        or "NOTA FISCAL ELETRONICA DE SERVICO" in marker
        or "NOTA FISCAL ELETRONICA DE SERVICOS" in marker
        for marker in markers
    ):
        kinds.add(DocumentType.NFSE)
    if len(kinds) != 1:
        return FiscalExtraction(
            source_sha256=source_sha256,
            source_filename=source_filename,
            document_type=DocumentType.UNKNOWN,
            extraction_mode=extraction_mode,
            status=ProcessingStatus.REVIEW,
            quality_flags=(QualityFlag.UNSUPPORTED_LAYOUT,),
            parser_id="labelled-v1",
        )
    kind = next(iter(kinds))
    observations: dict[str, list[str]] = defaultdict(list)
    section = "other"
    all_labels = set(LABELS) | NAME_LABELS | CNPJ_LABELS | set(SECTIONS)
    for index, line in enumerate(text):
        label, sep, inline = line.partition(":")
        key = normalized(label)
        if key in SECTIONS:
            section = SECTIONS[key]
            continue
        field = LABELS.get(key)
        if key in NAME_LABELS and section in {"issuer", "recipient"}:
            field = section
        elif key in CNPJ_LABELS and section == "issuer":
            field = "cnpj"
        if field is None:
            continue
        value = inline.strip() if sep else ""
        if not value and index + 1 < len(text):
            candidate = text[index + 1]
            if normalized(candidate.partition(":")[0]) not in all_labels:
                value = candidate
        observations[field].append(value)
    for value in observations.pop("combined", []):
        parts = value.split("/")
        observations["number"].append(parts[0].strip() if len(parts) == 2 else "")
        observations["series"].append(parts[1].strip() if len(parts) == 2 else "")
    values: dict[str, str | None] = {}
    flags: list[QualityFlag] = []
    for key, missing in MISSING.items():
        candidates = [candidate for candidate in observations.get(key, []) if candidate]
        unique = tuple(dict.fromkeys(candidates))
        if key in {"number", "series"} and len(unique) == 1:
            values[key] = unique[0]
        else:
            values[key] = candidates[0] if len(candidates) == 1 else None
        if len(candidates) > 1 and not (key in {"number", "series"} and len(unique) == 1):
            flags.append(
                QualityFlag.AMBIGUOUS_AMOUNT if key == "amount" else QualityFlag.AMBIGUOUS_FIELD
            )
        if values[key] is None:
            flags.append(missing)
    cnpj = None
    if raw_value := values["cnpj"]:
        try:
            if not re.fullmatch(r"[0-9./\- ]+", raw_value):
                raise DomainValidationError("invalid characters")
            cnpj = validate_cnpj(raw_value)
        except DomainValidationError:
            flags.append(QualityFlag.INVALID_CNPJ)
    issue_date = None
    if raw_value := values["date"]:
        try:
            match = DATE.fullmatch(raw_value)
            if match is None:
                raise DomainValidationError("invalid date")
            issue_date = parse_br_date(match[1])
        except DomainValidationError:
            flags.append(QualityFlag.INVALID_ISSUE_DATE)
    amount = None
    if raw_value := values["amount"]:
        if MONEY.fullmatch(raw_value):
            amount = parse_brl_money(raw_value)
        else:
            flags.append(QualityFlag.INVALID_AMOUNT)
    for key in ("number", "series"):
        if (raw_value := values[key]) and not re.fullmatch(r"[A-Za-z0-9.-]+", raw_value):
            values[key] = None
            flags.append(QualityFlag.INVALID_IDENTIFIER)
    return FiscalExtraction(
        source_sha256=source_sha256,
        source_filename=source_filename,
        document_type=kind,
        extraction_mode=extraction_mode,
        status=ProcessingStatus.REVIEW if flags else ProcessingStatus.OK,
        invoice_number=values["number"],
        series=values["series"],
        issue_date=issue_date,
        issuer_name=values["issuer"],
        issuer_cnpj=cnpj,
        recipient_name=values["recipient"],
        amount=amount,
        quality_flags=tuple(dict.fromkeys(flags)),
        parser_id="labelled-v1",
    )
