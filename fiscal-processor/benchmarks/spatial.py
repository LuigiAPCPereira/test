"""Position-based benchmark extraction; independent of fixture answers/coordinates.

This intentionally narrow locator is evaluation tooling, not the fiscal parser.
Coordinates use PDF points with a top-left origin, regardless of OCR DPI.
"""

import unicodedata
from dataclasses import dataclass


@dataclass(frozen=True)
class TextBox:
    text: str
    left: float
    top: float
    right: float
    bottom: float
    page: int = 0


ALIASES = {
    "number": {"NUMERO DA NF", "NUMERO DA NOTA", "NOTA NUMERO"},
    "series": {"SERIE"},
    "date": {"DATA DE EMISSAO", "EMITIDA EM"},
    "cnpj": {"CNPJ DO EMITENTE", "CNPJ DO PRESTADOR"},
    "issuer": {"RAZAO SOCIAL DO EMITENTE", "RAZAO SOCIAL DO PRESTADOR"},
    "recipient": {"RAZAO SOCIAL DO DESTINATARIO", "RAZAO SOCIAL DO TOMADOR"},
    "amount": {"VALOR TOTAL DA NOTA", "VALOR TOTAL DOS SERVICOS"},
}


def normalized_label(text: str) -> str:
    decomposed = unicodedata.normalize("NFKD", text)
    return " ".join(
        "".join(c for c in decomposed if not unicodedata.combining(c)).upper().rstrip(":").split()
    )


def combine_words(words: list[TextBox]) -> list[TextBox]:
    """Join same-baseline words, but never bridge wide column gutters."""
    lines: list[list[TextBox]] = []
    for word in sorted(words, key=lambda b: (b.page, b.top, b.left)):
        target = next(
            (
                line
                for line in lines
                if line[0].page == word.page and abs(line[0].bottom - word.bottom) <= 3
            ),
            None,
        )
        if target is None:
            lines.append([word])
        else:
            target.append(word)
    result = []
    for line in lines:
        group: list[TextBox] = []
        for word in sorted(line, key=lambda b: b.left):
            if group and word.left - group[-1].right > 16:
                result.append(_merged(group))
                group = []
            group.append(word)
        if group:
            result.append(_merged(group))
    return result


def _merged(boxes: list[TextBox]) -> TextBox:
    return TextBox(
        " ".join(b.text for b in boxes),
        min(b.left for b in boxes),
        min(b.top for b in boxes),
        max(b.right for b in boxes),
        max(b.bottom for b in boxes),
        boxes[0].page,
    )


def locate_fields(boxes: list[TextBox]) -> dict[str, str | None]:
    fields: dict[str, str | None] = dict.fromkeys(["type", *ALIASES])
    normalized = [(b, normalized_label(b.text)) for b in boxes]
    kinds = set()
    for _, label in normalized:
        if label == "DANFE":
            kinds.add("NFE")
        if label in {"NFS-E", "NOTA FISCAL DE SERVICOS ELETRONICA"}:
            kinds.add("NFSE")
    fields["type"] = next(iter(kinds)) if len(kinds) == 1 else None
    if fields["type"] is None:
        return fields
    all_labels = set().union(*ALIASES.values())
    for key, aliases in ALIASES.items():
        anchors = [b for b, label in normalized if label in aliases]
        if len(anchors) != 1:
            continue
        anchor = anchors[0]
        # Look immediately below this label in its own column. No answer lookup.
        candidates = [
            b
            for b, label in normalized
            if b.page == anchor.page
            and label not in all_labels
            and 0 < b.top - anchor.bottom <= 22
            and abs(b.left - anchor.left) <= 8
        ]
        if len(candidates) == 1:
            fields[key] = candidates[0].text.strip()
    return fields


def score(expected: dict[str, str | None], actual: dict[str, str | None]) -> dict:
    exact = {key: actual.get(key) == value for key, value in expected.items()}
    return {
        "matched": sum(exact.values()),
        "total": len(expected),
        "exact": exact,
        "wrong_nonempty": [k for k in expected if actual.get(k) is not None and not exact[k]],
        "missing": [k for k, v in expected.items() if v is not None and actual.get(k) is None],
        "review_oracle": not all(exact.values()),
    }
