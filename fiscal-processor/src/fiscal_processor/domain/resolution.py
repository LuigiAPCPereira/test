"""Deterministic resolution of structured fiscal field candidates."""

from collections.abc import Iterable
from dataclasses import dataclass
from enum import StrEnum

from .fields import CandidateSource, FieldCandidate, FiscalField


class ResolutionStatus(StrEnum):
    MISSING = "MISSING"
    RESOLVED = "RESOLVED"
    AMBIGUOUS = "AMBIGUOUS"
    CONFLICT = "CONFLICT"


@dataclass(frozen=True, slots=True)
class FieldResolution:
    field: FiscalField
    status: ResolutionStatus
    candidates: tuple[FieldCandidate, ...] = ()
    selected: FieldCandidate | None = None

    def __post_init__(self) -> None:
        if any(candidate.field != self.field for candidate in self.candidates):
            raise ValueError("all candidates must match the resolution field")
        if self.status == ResolutionStatus.RESOLVED and self.selected is None:
            raise ValueError("resolved fields require a selected candidate")
        if self.status != ResolutionStatus.RESOLVED and self.selected is not None:
            raise ValueError("unresolved fields must not select a candidate")
        if self.selected is not None and self.selected not in self.candidates:
            raise ValueError("selected candidate must belong to candidates")


_SOURCE_PRIORITY = {
    CandidateSource.NFE_ACCESS_KEY: 0,
    CandidateSource.NATIVE_TEXT: 1,
    CandidateSource.OCR: 2,
}


def _equivalence_value(candidate: FieldCandidate) -> str:
    value = candidate.normalized_value
    if candidate.field in {FiscalField.INVOICE_NUMBER, FiscalField.SERIES} and value.isdigit():
        return value.lstrip("0") or "0"
    return value


def resolve_field_candidates(
    field: FiscalField,
    candidates: Iterable[FieldCandidate],
) -> FieldResolution:
    """Resolve agreement deterministically while preserving ambiguity/conflict."""
    relevant = tuple(candidate for candidate in candidates if candidate.field == field)
    if not relevant:
        return FieldResolution(field=field, status=ResolutionStatus.MISSING)

    groups: dict[str, list[FieldCandidate]] = {}
    for candidate in relevant:
        groups.setdefault(_equivalence_value(candidate), []).append(candidate)

    if len(groups) == 1:
        selected = min(
            relevant,
            key=lambda candidate: (
                _SOURCE_PRIORITY[candidate.source],
                candidate.page if candidate.page is not None else -1,
            ),
        )
        return FieldResolution(
            field=field,
            status=ResolutionStatus.RESOLVED,
            candidates=relevant,
            selected=selected,
        )

    sources = {candidate.source for candidate in relevant}
    status = ResolutionStatus.AMBIGUOUS if len(sources) == 1 else ResolutionStatus.CONFLICT
    return FieldResolution(field=field, status=status, candidates=relevant)
