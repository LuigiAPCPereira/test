"""Evaluate an explicitly supplied local corpus; reports contain no fiscal values."""

import argparse
import json
import sys
import tempfile
import time
from pathlib import Path

from .engines import RapidEngine, TesseractEngine
from .run import deny_network
from .spatial import ALIASES, locate_fields, score
from .spatial_run import extract_boxes

FIELDS = {"type", *ALIASES}


def load_manifest(path: Path) -> list[tuple[Path, dict]]:
    """Resolve only PDFs contained within the manifest directory, including symlinks."""
    if path.stat().st_size > 1_000_000:
        raise ValueError("manifest too large")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or set(data) != {"version", "cases"} or data["version"] != 1:
        raise ValueError("invalid manifest schema")
    cases = data["cases"]
    if not isinstance(cases, list) or not 1 <= len(cases) <= 200:
        raise ValueError("expected 1..200 cases")
    root = path.resolve().parent
    result = []
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or set(case) != {"pdf", "expected"}:
            raise ValueError("invalid case schema")
        if not isinstance(case["pdf"], str) or Path(case["pdf"]).is_absolute():
            raise ValueError("relative PDF required")
        pdf = (root / case["pdf"]).resolve(strict=True)
        if not pdf.is_relative_to(root) or pdf.suffix.lower() != ".pdf" or not pdf.is_file():
            raise ValueError("PDF outside corpus or invalid")
        if pdf in seen:
            raise ValueError("duplicate PDF")
        seen.add(pdf)
        expected = case["expected"]
        if not isinstance(expected, dict) or set(expected) != FIELDS:
            raise ValueError("all eight expected fields required")
        if any(
            v is not None and (not isinstance(v, str) or not v.strip()) for v in expected.values()
        ):
            raise ValueError("expected values must be nonempty strings or null")
        if expected["type"] not in {None, "NFE", "NFSE"}:
            raise ValueError("invalid expected document type")
        result.append((pdf, expected))
    return result


def evaluate(cases: list[tuple[Path, dict]], engine_name: str, engine, dpi: int, output: Path):
    """Exclusive output files protect source files and previous evidence from overwrite."""
    if not 72 <= dpi <= 300 or output.suffix != ".json":
        raise ValueError("expected 72..300 DPI and .json output")
    journal = output.with_suffix(".jsonl")
    if output.exists() or journal.exists():
        raise FileExistsError("output already exists")
    results = []
    # x mode also rejects symlinks and concurrent creators. Interrupted JSON is not complete.
    with output.open("x", encoding="utf-8") as report, journal.open("x", encoding="utf-8") as log:
        with tempfile.TemporaryDirectory(prefix="fp-eval-", dir=output.parent) as temp:
            for index, (pdf, expected) in enumerate(cases, 1):
                started = time.perf_counter()
                try:
                    boxes = extract_boxes(pdf, engine_name, engine, dpi, Path(temp))
                    metrics = score(expected, locate_fields(boxes))
                    row = {"case_index": index, "status": "evaluated", **metrics}
                except Exception:
                    # Library exception messages may contain paths/text. Never serialize them.
                    row = {"case_index": index, "status": "failed", "error": "EXTRACTION_FAILED"}
                row["seconds"] = time.perf_counter() - started
                results.append(row)
                log.write(json.dumps(row) + "\n")
                log.flush()
        failed = sum(row["status"] == "failed" for row in results)
        payload = {
            "schema_version": 1,
            "engine": engine_name,
            "dpi": dpi,
            "complete": True,
            "failed_cases": failed,
            "expected_assertions": len(cases) * 8,
            "matched": sum(row.get("matched", 0) for row in results),
            "results": results,
            "limits": (
                "Narrow spatial locator; corpus independence not certified; "
                "Python network guard only"
            ),
        }
        json.dump(payload, report, indent=2)
        report.write("\n")
    return payload


def main() -> int:
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument(
        "--engine", choices=["native", "small", "medium", "tesseract"], required=True
    )
    parser.add_argument("--models", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--dpi", type=int, default=200)
    args = parser.parse_args()
    sys.addaudithook(deny_network)
    try:
        cases = load_manifest(args.manifest)
        engine = None
        if args.engine != "native":
            if args.models is None:
                raise ValueError("models required")
            engine = (
                TesseractEngine(args.models)
                if args.engine == "tesseract"
                else RapidEngine(args.engine, args.models)
            )
        result = evaluate(cases, args.engine, engine, args.dpi, args.output)
    except Exception:
        print("EVALUATION_SETUP_FAILED", file=sys.stderr)
        return 2
    print(f"evaluated={len(result['results'])} failed={result['failed_cases']}")
    return 1 if result["failed_cases"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
