"""Associate separate labels and values without flattening adjacent columns.

Narrow baseline: value immediately below its label, aligned within eight PDF
points, up to 22 points below. Multiple candidates remain ambiguous. Headers
scope generic party labels on their own page. No answer lookup or value guessing.
"""

import re
from collections.abc import Sequence
from dataclasses import replace

from fiscal_processor.domain import ExtractionMode, FiscalExtraction
from fiscal_processor.domain.text import TextSpan

from .labelled import (
    CNPJ_LABELS,
    DATE,
    LABELS,
    MONEY,
    NAME_LABELS,
    SECTIONS,
    normalized,
    parse_invoice,
)

MARKERS = {
    "DANFE",
    "DANFSE",
    "NFS-E",
    "NFSE - PRESTADOR",
    "NOTA FISCAL DE SERVICOS ELETRONICA",
}
CANONICAL = {
    "number": "NUMERO DA NF",
    "combined": "NUMERO / SERIE",
    "series": "SERIE",
    "date": "DATA DE EMISSAO",
    "issuer": "RAZAO SOCIAL DO EMITENTE",
    "recipient": "RAZAO SOCIAL DO DESTINATARIO",
    "cnpj": "CNPJ DO EMITENTE",
    "amount": "VALOR TOTAL DA NOTA",
}

_CNPJ = re.compile(r"(?<!\d)(?:\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}|\d{14})(?!\d)")
_NUMBER_SERIES = re.compile(
    r"(?:^|\s)(?:NO|N°|NUMERO(?: DA (?:NF|NOTA))?)\s*[:\-]?\s*"
    r"([0-9][A-Z0-9.\-]*)\s+SERIE\s*[:\-]?\s*([A-Z0-9.\-]+)(?:\s|$)"
)
_PREFIX_KEYS = tuple(
    sorted(
        set(LABELS) | NAME_LABELS | CNPJ_LABELS,
        key=len,
        reverse=True,
    )
)


def _original_suffix(text: str, key: str) -> str:
    words = text.split()
    return " ".join(words[len(key.split()) :]).strip(" :-")


def _typed_inline(field: str, value: str) -> str | None:
    if field == "amount":
        match = MONEY.search(value)
        return match.group(0) if match is not None else None
    if field == "date":
        match = DATE.search(value)
        return match.group(0) if match is not None else None
    if field == "cnpj":
        match = _CNPJ.search(value)
        return match.group(0) if match is not None else None
    if field in {"number", "series"} and re.fullmatch(r"[A-Z0-9.\-]+", value):
        return value
    if field == "combined" and re.fullmatch(r"[A-Z0-9.\-]+\s*/\s*[A-Z0-9.\-]+", value):
        return value
    return None


def _label_key_and_inline(text: str) -> tuple[str, str]:
    label, separator, inline = text.partition(":")
    if separator:
        return normalized(label), inline.strip()

    whole = normalized(text)
    if whole in _PREFIX_KEYS or whole in SECTIONS or whole in MARKERS:
        return whole, ""

    for key in _PREFIX_KEYS:
        if not whole.startswith(key + " "):
            continue
        remainder = whole[len(key) :].strip()
        field = LABELS.get(key)
        if field is not None:
            value = _typed_inline(field, remainder)
            if value is not None:
                return key, value
        if key in CNPJ_LABELS:
            value = _typed_inline("cnpj", remainder)
            if value is not None:
                return key, value
        if key in NAME_LABELS:
            value = _original_suffix(text, key)
            if value:
                return key, value
    return whole, ""


def _same_row_value(field: str, value: str) -> bool:
    """Accept horizontal candidates only when their syntax matches the target field."""
    if field == "amount":
        return MONEY.fullmatch(value) is not None
    if field == "date":
        return DATE.fullmatch(value) is not None
    if field == "cnpj":
        return re.fullmatch(r"[0-9./\- ]+", value) is not None
    if field in {"number", "series", "combined"}:
        return re.fullmatch(r"[A-Za-z0-9./\- ]+", value) is not None
    return False


def parse_spans(
    spans: Sequence[TextSpan],
    *,
    source_sha256: str,
    source_filename: str,
    extraction_mode: ExtractionMode = ExtractionMode.NATIVE_TEXT,
) -> FiscalExtraction:
    labelled = [(span, *_label_key_and_inline(span.text)) for span in spans]
    lines: list[str] = []
    for span, key, _inline in labelled:
        whole = normalized(span.text)
        pair = _NUMBER_SERIES.search(whole)
        if pair is not None:
            lines.append(f"NUMERO DA NF: {pair.group(1)}")
            lines.append(f"SERIE: {pair.group(2)}")
        if key in MARKERS:
            lines.append(span.text)
        elif "DANFE" in whole or "DOCUMENTO AUXILIAR DA NOTA FISCAL ELETRONICA" in whole:
            lines.append("DANFE")
        elif (
            "DANFSE" in whole
            or "DOCUMENTO AUXILIAR DA NFS-E" in whole
            or "NOTA FISCAL DE SERVICO ELETRONICA" in whole
            or "NOTA FISCAL DE SERVICOS ELETRONICA" in whole
            or "NOTA FISCAL ELETRONICA DE SERVICO" in whole
            or "NOTA FISCAL ELETRONICA DE SERVICOS" in whole
        ):
            lines.append("NFS-e")
    reserved = set(LABELS) | NAME_LABELS | CNPJ_LABELS | set(SECTIONS) | MARKERS
    for anchor, key, inline_value in labelled:
        field = LABELS.get(key)
        if key in NAME_LABELS | CNPJ_LABELS:
            headers = [
                (span, name)
                for span, name, _ in labelled
                if name in SECTIONS
                and span.page == anchor.page
                and span.bottom <= anchor.top
                and span.left <= anchor.left + 8
            ]
            if headers:
                nearest_top = max(span.top for span, _ in headers)
                nearest = [name for span, name in headers if abs(span.top - nearest_top) <= 3]
                section = SECTIONS[nearest[0]] if len(nearest) == 1 else "other"
                if key in NAME_LABELS and section in {"issuer", "recipient"}:
                    field = section
                elif key in CNPJ_LABELS and section == "issuer":
                    field = "cnpj"
        if field is None:
            continue
        if inline_value:
            candidates = [inline_value]
        else:
            below = [
                span.text.strip()
                for span, name in labelled
                if span.page == anchor.page
                and name not in reserved
                and 0 < span.top - anchor.bottom <= 22
                and abs(span.left - anchor.left) <= 8
                # Do not reach across a section heading between label and value.
                and not any(
                    h.page == anchor.page
                    and hkey in SECTIONS
                    and anchor.bottom <= h.top <= span.top
                    for h, hkey, _ in labelled
                )
            ]
            same_row = [
                span.text.strip()
                for span, name in labelled
                if span.page == anchor.page
                and name not in reserved
                and abs(span.top - anchor.top) <= 4
                and 0 < span.left - anchor.right <= 220
                and _same_row_value(field, span.text.strip())
            ]
            candidates = list(dict.fromkeys([*below, *same_row]))
        # One emitted observation per candidate lets the parser preserve ambiguity.
        for value in candidates or [""]:
            lines.append(f"{CANONICAL[field]}: {value}")
    result = parse_invoice(
        lines,
        source_sha256=source_sha256,
        source_filename=source_filename,
        extraction_mode=extraction_mode,
    )
    return replace(result, parser_id="spatial-labelled-v1")
