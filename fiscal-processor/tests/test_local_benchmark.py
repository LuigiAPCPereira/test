import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

from benchmarks.local_run import evaluate, load_manifest
from benchmarks.spatial_corpus import cases, write_pdf


def corpus(tmp_path):
    case = cases()[0]
    write_pdf(tmp_path / "private-invoice.pdf", case)
    manifest = tmp_path / "manifest.json"
    data = {"version": 1, "cases": [{"pdf": "private-invoice.pdf", "expected": case.expected}]}
    manifest.write_text(json.dumps(data))
    return manifest, data


def test_real_pdf_evaluation_omits_fiscal_values_and_paths(tmp_path):
    manifest, data = corpus(tmp_path)
    report = tmp_path / "report.json"
    result = evaluate(load_manifest(manifest), "native", None, 200, report)
    assert result["matched"] == result["expected_assertions"] == 8
    assert result["failed_cases"] == 0
    serialized = report.read_text() + report.with_suffix(".jsonl").read_text()
    for secret in ["private-invoice", str(tmp_path), *data["cases"][0]["expected"].values()]:
        assert json.dumps(secret) not in serialized
    assert not list(tmp_path.glob("fp-eval-*"))


def test_wrong_answer_is_counted_without_echoing_it(tmp_path):
    manifest, data = corpus(tmp_path)
    data["cases"][0]["expected"]["amount"] = "999.123,45"
    manifest.write_text(json.dumps(data))
    result = evaluate(load_manifest(manifest), "native", None, 200, tmp_path / "report.json")
    assert result["matched"] == 7
    assert result["results"][0]["wrong_nonempty"] == ["amount"]
    assert "999.123,45" not in json.dumps(result)


def test_corrupt_pdf_does_not_stop_next_document_or_shrink_denominator(tmp_path):
    manifest, data = corpus(tmp_path)
    (tmp_path / "private-broken.pdf").write_bytes(b"not a pdf")
    data["cases"].insert(0, {"pdf": "private-broken.pdf", "expected": data["cases"][0]["expected"]})
    manifest.write_text(json.dumps(data))
    result = evaluate(load_manifest(manifest), "native", None, 200, tmp_path / "report.json")
    assert result["failed_cases"] == 1
    assert result["matched"] == 8
    assert result["expected_assertions"] == 16
    assert result["results"][0]["error"] == "EXTRACTION_FAILED"
    assert "private-broken" not in json.dumps(result)


@pytest.mark.parametrize(
    "change", ["traversal", "symlink", "missing_field", "duplicate", "bad_value"]
)
def test_invalid_manifest_fails_before_processing(tmp_path, change):
    root = tmp_path / "corpus"
    root.mkdir()
    manifest, data = corpus(root)
    if change in {"traversal", "symlink"}:
        outside = tmp_path / "outside.pdf"
        outside.write_bytes(b"outside")
        if change == "traversal":
            data["cases"][0]["pdf"] = "../outside.pdf"
        else:
            (root / "link.pdf").symlink_to(outside)
            data["cases"][0]["pdf"] = "link.pdf"
    elif change == "missing_field":
        del data["cases"][0]["expected"]["amount"]
    elif change == "duplicate":
        data["cases"].append(data["cases"][0])
    else:
        data["cases"][0]["expected"]["amount"] = 123
    manifest.write_text(json.dumps(data))
    with pytest.raises(ValueError):
        load_manifest(manifest)


@pytest.mark.parametrize("suffix", [".json", ".jsonl"])
def test_existing_evidence_is_never_overwritten(tmp_path, suffix):
    manifest, _ = corpus(tmp_path)
    existing = tmp_path / ("report" + suffix)
    existing.write_text("preserve")
    with pytest.raises(FileExistsError):
        evaluate(load_manifest(manifest), "native", None, 200, tmp_path / "report.json")
    assert existing.read_text() == "preserve"


def test_cli_setup_failure_is_sanitized(tmp_path):
    path = tmp_path / "secret-company-manifest.json"
    path.write_text("{broken secret")
    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "benchmarks.local_run",
            "--manifest",
            str(path),
            "--engine",
            "native",
            "--output",
            str(tmp_path / "report.json"),
        ],
        capture_output=True,
        text=True,
        env={**os.environ, "PYTHONPATH": "src:."},
        cwd=Path(__file__).resolve().parents[1],
        check=False,
    )
    assert result.returncode == 2
    assert result.stderr.strip() == "EVALUATION_SETUP_FAILED"
    assert not result.stdout
