"""Exact field scoring for controlled labels, not a production fiscal parser."""

import re

from .corpus import Case


def extract_fields(text: str, case: Case) -> dict[str, str | None]:
    result: dict[str, str | None] = {}
    for key, label in case.labels.items():
        matches = re.findall(
            r"^\s*" + re.escape(label) + r"\s*:\s*([^\n\r]+)", text, re.IGNORECASE | re.MULTILINE
        )
        # Multiple candidates are ambiguous, even if one matches the answer.
        result[key] = matches[0].strip() if len(matches) == 1 else None
    return result


def score_fields(expected: dict[str, str], actual: dict[str, str | None]) -> dict[str, object]:
    exact = {key: actual.get(key) == value for key, value in expected.items()}
    wrong = [key for key in expected if actual.get(key) is not None and not exact[key]]
    missing = [key for key in expected if actual.get(key) is None]
    return {
        "exact": exact,
        "matched": sum(exact.values()),
        "total": len(expected),
        "wrong_nonempty": wrong,
        "missing": missing,
        "review": not all(exact.values()),
    }
