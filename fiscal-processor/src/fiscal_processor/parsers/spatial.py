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

MARKERS = {"DANFE", "NFS-E", "NFSE - PRESTADOR", "NOTA FISCAL DE SERVICOS ELETRONICA"}
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
    labelled = [(span, normalized(span.text.partition(":")[0])) for span in spans]
    lines: list[str] = []
    for span, key in labelled:
        whole = normalized(span.text)
        if key in MARKERS:
            lines.append(span.text)
        elif "DANFE" in whole or "DOCUMENTO AUXILIAR DA NOTA FISCAL ELETRONICA" in whole:
            lines.append("DANFE")
        elif (
            "NOTA FISCAL DE SERVICO ELETRONICA" in whole
            or "NOTA FISCAL DE SERVICOS ELETRONICA" in whole
            or "NOTA FISCAL ELETRONICA DE SERVICO" in whole
            or "NOTA FISCAL ELETRONICA DE SERVICOS" in whole
        ):
            lines.append("NFS-e")
    reserved = set(LABELS) | NAME_LABELS | CNPJ_LABELS | set(SECTIONS) | MARKERS
    for anchor, key in labelled:
        field = LABELS.get(key)
        if key in NAME_LABELS | CNPJ_LABELS:
            headers = [
                (span, name)
                for span, name in labelled
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
        inline = anchor.text.partition(":")[2].strip()
        if inline:
            candidates = [inline]
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
                    for h, hkey in labelled
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
