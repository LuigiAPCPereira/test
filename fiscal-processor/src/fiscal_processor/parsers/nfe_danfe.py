"""NF-e/DANFE evidence reconciliation without mutating FiscalExtraction."""

from collections.abc import Sequence

from fiscal_processor.domain import CandidateSource, FieldResolution
from fiscal_processor.domain.text import TextSpan

from .nfe_access_key import resolve_nfe_structural_candidates
from .spatial import find_nfe_visual_candidates


def resolve_nfe_danfe_candidates(
    spans: Sequence[TextSpan],
    *,
    source: CandidateSource = CandidateSource.NATIVE_TEXT,
) -> tuple[FieldResolution, ...]:
    """Reconcile visual/native DANFE evidence with a validated access key."""
    visual = find_nfe_visual_candidates(spans, source=source)
    return resolve_nfe_structural_candidates(spans, visual)
