from benchmarks.spatial import TextBox, combine_words, locate_fields, score
from benchmarks.spatial_corpus import cases, write_pdf
from fiscal_processor.adapters.pdf import PdfiumAdapter


def test_real_native_pdf_positions_recover_all_synthetic_fields(tmp_path):
    for case in cases():
        path = tmp_path / "case.pdf"
        write_pdf(path, case)
        blocks = []
        for page in PdfiumAdapter().extract_document(path).pages:
            blocks.extend(
                TextBox(
                    b.text,
                    b.left,
                    page.height_points - b.top,
                    b.right,
                    page.height_points - b.bottom,
                    page.page_index,
                )
                for b in page.blocks
            )
        assert locate_fields(blocks) == case.expected, case.name


def test_locator_uses_observed_value_not_fixture_answers():
    observed = locate_fields(
        [
            TextBox("DANFE", 0, 0, 70, 15),
            TextBox("VALOR TOTAL DA NOTA", 20, 50, 160, 60),
            TextBox("1,99", 20, 70, 60, 82),
        ]
    )
    assert observed["amount"] == "1,99"
    assert score({"amount": "112.000,00"}, observed)["matched"] == 0


def test_overlapping_candidates_are_ambiguous_not_selected_by_value():
    boxes = [
        TextBox("DANFE", 0, 0, 70, 15),
        TextBox("VALOR TOTAL DA NOTA", 20, 50, 160, 60),
        TextBox("1,99", 20, 70, 60, 82),
        TextBox("112.000,00", 22, 70, 100, 82),
    ]
    assert locate_fields(boxes)["amount"] is None


def test_word_join_preserves_column_gutters_and_page_boundaries():
    boxes = [
        TextBox("SÃO", 10, 10, 30, 20),
        TextBox("JOSÉ", 34, 10, 60, 20),
        TextBox("009", 300, 10, 320, 20),
        TextBox("NEXT", 10, 10, 40, 20, 1),
    ]
    assert [b.text for b in combine_words(boxes)] == ["SÃO JOSÉ", "009", "NEXT"]


def test_mixed_document_markers_do_not_classify():
    assert (
        locate_fields([TextBox("DANFE", 0, 0, 50, 10), TextBox("NFS-e", 0, 20, 50, 30)])["type"]
        is None
    )


def test_absence_is_correct_only_when_expected():
    assert score({"amount": None}, {"amount": None})["missing"] == []
    assert score({"amount": None}, {"amount": "0,00"})["wrong_nonempty"] == ["amount"]
