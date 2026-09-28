"""Run spatial corpus sequentially with no answers passed to the locator."""

import argparse
import csv
import io
import json
import subprocess
import sys
import tempfile
import time
from pathlib import Path

from fiscal_processor.adapters.pdf import PdfiumAdapter

from .engines import RapidEngine, TesseractEngine
from .run import deny_network
from .spatial import TextBox, combine_words, locate_fields, score
from .spatial_corpus import cases, write_pdf


def rapid_boxes(engine, image: Path, scale: float, page: int) -> list[TextBox]:
    output = engine.engine(str(image))
    if output.boxes is None or output.txts is None:
        return []
    return [
        TextBox(
            text,
            min(p[0] for p in quad) / scale,
            min(p[1] for p in quad) / scale,
            max(p[0] for p in quad) / scale,
            max(p[1] for p in quad) / scale,
            page,
        )
        for quad, text in zip(output.boxes, output.txts, strict=True)
    ]


def tesseract_boxes(engine, image: Path, scale: float, page: int) -> list[TextBox]:
    tsv = subprocess.run(
        [
            "tesseract",
            str(image),
            "stdout",
            "--tessdata-dir",
            str(engine.model_dir),
            "-l",
            engine.language,
            "--oem",
            "1",
            "--psm",
            "11",
            "-c",
            "tessedit_create_tsv=1",
        ],
        capture_output=True,
        text=True,
        check=True,
        timeout=60,
    ).stdout
    boxes = []
    for row in csv.DictReader(io.StringIO(tsv), delimiter="\t", quoting=csv.QUOTE_NONE):
        if row["level"] != "5" or not row["text"].strip():
            continue
        left, top, width, height = (
            int(row[key]) / scale for key in ["left", "top", "width", "height"]
        )
        boxes.append(TextBox(row["text"], left, top, left + width, top + height, page))
    return combine_words(boxes)


def extract_boxes(pdf: Path, engine_name: str, engine, dpi: int, root: Path) -> list[TextBox]:
    document = PdfiumAdapter().extract_document(pdf)
    boxes: list[TextBox] = []
    if engine_name == "native":
        for page in document.pages:
            boxes.extend(
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
    else:
        from PIL import Image

        for index in range(len(document.pages)):
            rendered = PdfiumAdapter().render_page(pdf, index, dpi=dpi)
            raster = Image.frombytes(
                "RGB",
                (rendered.width, rendered.height),
                rendered.pixels,
                "raw",
                rendered.mode,
                rendered.stride,
            )
            image_path = root / "input.png"
            raster.save(image_path)
            if engine_name == "tesseract":
                boxes.extend(tesseract_boxes(engine, image_path, dpi / 72, index))
            else:
                boxes.extend(rapid_boxes(engine, image_path, dpi / 72, index))
    return boxes


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument(
        "--engine", choices=["native", "small", "medium", "tesseract"], required=True
    )
    parser.add_argument("--models", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--dpi", type=int, default=200)
    args = parser.parse_args()
    if args.engine != "native" and args.models is None:
        parser.error("--models required for OCR")
    if not 72 <= args.dpi <= 300:
        parser.error("dpi must be 72..300")
    sys.addaudithook(deny_network)
    engine = None
    if args.engine in {"small", "medium"}:
        engine = RapidEngine(args.engine, args.models)
    elif args.engine == "tesseract":
        engine = TesseractEngine(args.models)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    journal = args.output.with_suffix(".jsonl")
    journal.write_text("")
    results = []
    with tempfile.TemporaryDirectory(prefix="fp-spatial-") as temporary:
        root = Path(temporary)
        for case in cases():
            pdf = root / "input.pdf"
            write_pdf(pdf, case)
            boxes = []
            started = time.perf_counter()
            boxes = extract_boxes(pdf, args.engine, engine, args.dpi, root)
            observed = locate_fields(boxes)
            elapsed = time.perf_counter() - started
            # Answers enter only here, after extraction is complete.
            result = {
                "case": case.name,
                "split": case.split,
                "pages": len(case.pages),
                "seconds_including_render": elapsed,
                **score(case.expected, observed),
            }
            results.append(result)
            with journal.open("a") as stream:
                stream.write(json.dumps(result) + "\n")
            print(f"{args.engine} {case.name}: {result['matched']}/{result['total']}", flush=True)
    report = {
        "corpus": "synthetic-spatial-v1",
        "engine": args.engine,
        "dpi": args.dpi,
        "complete": True,
        "results": results,
        "network_guard": "Python audit hook only",
        "limits": "Synthetic author-controlled layouts; not municipal/general fiscal accuracy",
    }
    args.output.write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
