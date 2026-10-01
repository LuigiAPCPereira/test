"""NF-e access-key evidence extracted conservatively from native DANFE spans."""

from collections.abc import Iterable, Sequence

from fiscal_processor.domain import (
    DomainValidationError,
    FieldCandidate,
    FieldResolution,
    FiscalField,
    NfeAccessKey,
    ResolutionStatus,
    resolve_field_candidates,
)
from fiscal_processor.domain.text import TextSpan

from .labelled import normalized

_STRUCTURAL_FIELDS = (
    FiscalField.INVOICE_NUMBER,
    FiscalField.SERIES,
    FiscalField.ISSUER_CNPJ,
)


def _numeric_fragment(text: str) -> str | None:
    stripped = text.strip()
    if not stripped or any(not (char.isdigit() or char.isspace()) for char in stripped):
        return None
    return stripped if any(char.isdigit() for char in stripped) else None


def _rows(spans: Sequence[TextSpan], *, tolerance: float = 3.0) -> tuple[tuple[TextSpan, ...], ...]:
    rows: list[list[TextSpan]] = []
    for span in sorted(spans, key=lambda item: (item.top, item.left)):
        if rows and abs(span.top - rows[-1][0].top) <= tolerance:
            rows[-1].append(span)
        else:
            rows.append([span])
    return tuple(tuple(row) for row in rows)


def _parse_key_text(raw: str) -> NfeAccessKey | None:
    try:
        return NfeAccessKey.parse(raw)
    except DomainValidationError:
        return None


def find_nfe_access_key_candidates(spans: Sequence[TextSpan]) -> tuple[FieldCandidate, ...]:
    """Find a validated 44-digit key only in the labelled access-key region."""
    found: list[FieldCandidate] = []
    seen: set[tuple[int, str]] = set()

    labels = [span for span in spans if "CHAVE DE ACESSO" in normalized(span.text)]
    for label in labels:
        inline = normalized(label.text).partition("CHAVE DE ACESSO")[2].strip()
        key = _parse_key_text(inline) if inline else None

        if key is None:
            nearby = [
                span
                for span in spans
                if span.page == label.page
                and (
                    (
                        label.bottom - 2 <= span.top <= label.bottom + 45
                        and span is not label
                    )
                    or (
                        abs(span.top - label.top) <= 3
                        and span.left >= label.right - 2
                    )
                )
                and _numeric_fragment(span.text) is not None
            ]
            for row in _rows(nearby):
                raw = " ".join(
                    fragment
                    for span in row
                    if (fragment := _numeric_fragment(span.text)) is not None
                )
                key = _parse_key_text(raw)
                if key is not None:
                    break

        if key is None or (label.page, key.digits) in seen:
            continue
        seen.add((label.page, key.digits))
        found.extend(key.field_candidates(page=label.page))

    return tuple(found)


def resolve_nfe_structural_candidates(
    spans: Sequence[TextSpan],
    observed_candidates: Iterable[FieldCandidate] = (),
) -> tuple[FieldResolution, ...]:
    """Combine validated key evidence with observed candidates without overwriting conflicts."""
    all_candidates = (*tuple(observed_candidates), *find_nfe_access_key_candidates(spans))
    return tuple(resolve_field_candidates(field, all_candidates) for field in _STRUCTURAL_FIELDS)


__all__ = [
    "ResolutionStatus",
    "find_nfe_access_key_candidates",
    "resolve_nfe_structural_candidates",
]
