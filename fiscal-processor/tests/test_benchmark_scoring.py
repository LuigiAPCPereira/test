from benchmarks.corpus import CASES, generate
from benchmarks.scoring import extract_fields, score_fields
from fiscal_processor.adapters.pdf import PdfiumAdapter


def test_cent_difference_is_complete_field_failure():
    result = score_fields({"amount": "112.000,00"}, {"amount": "112.000,80"})
    assert result["matched"] == 0
    assert result["wrong_nonempty"] == ["amount"]
    assert result["review"] is True


def test_duplicate_label_never_selects_matching_answer():
    case = CASES[0]
    fields = extract_fields("VALOR TOTAL: 112.000,00\nVALOR TOTAL: 999,00", case)
    assert fields["amount"] is None


def test_native_corpus_has_exact_fields_and_ignores_decoys(tmp_path):
    for case, path in generate(tmp_path):
        text = PdfiumAdapter().extract_document(path).text
        score = score_fields(case.fields, extract_fields(text, case))
        assert score["matched"] == score["total"]


def test_empty_document_does_not_invent_fields():
    case = CASES[0]
    fields = extract_fields("", case)
    assert all(value is None for value in fields.values())


def test_missing_or_corrupt_models_fail_before_engine_import(tmp_path):
    import pytest

    from benchmarks.engines import verify_model

    path = tmp_path / "PP-OCRv6_det_small.onnx"
    with pytest.raises(FileNotFoundError):
        verify_model(path)
    path.write_bytes(b"corrupt")
    with pytest.raises(ValueError, match="hash mismatch"):
        verify_model(path)
