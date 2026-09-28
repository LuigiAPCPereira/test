"""Run one OCR candidate per process; synthetic documents only."""

import argparse
import io
import json
import platform
import socket
import sys
import tempfile
import time
from pathlib import Path

from fiscal_processor.adapters.pdf import PdfiumAdapter

from .corpus import generate
from .engines import RapidEngine, TesseractEngine
from .scoring import extract_fields, score_fields


def deny_network(event, args):
    if event in {
        "socket.connect",
        "socket.connect_ex",
        "socket.getaddrinfo",
        "socket.gethostbyname",
    }:
        raise RuntimeError(f"benchmark denied network: {event}")


def variants(image):
    import numpy as np
    from PIL import Image, ImageEnhance

    yield "clean", image
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=35)
    buffer.seek(0)
    with Image.open(buffer) as jpeg:
        yield "jpeg35", jpeg.convert("RGB")
    yield "low-contrast", ImageEnhance.Contrast(image).enhance(0.25)
    array = np.asarray(image).astype("int16")
    noise = np.random.default_rng(20260927).normal(0, 5, array.shape)
    yield "noise5", Image.fromarray(np.clip(array + noise, 0, 255).astype("uint8"))
    yield "rotate1", image.rotate(1, fillcolor="white")


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("--engine", choices=["small", "medium", "tesseract"], required=True)
    parser.add_argument("--models", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--dpi", type=int, nargs="+", default=[150, 200, 250, 300])
    args = parser.parse_args()
    sys.addaudithook(deny_network)
    # Demonstrate that the guard is active before model initialization.
    try:
        socket.getaddrinfo("offline.invalid", 80)
    except RuntimeError:
        pass
    else:
        raise AssertionError("network guard inactive")
    from PIL import Image

    start = time.perf_counter()
    engine = (
        TesseractEngine(args.models)
        if args.engine == "tesseract"
        else RapidEngine(args.engine, args.models)
    )
    startup = time.perf_counter() - start
    results = []
    args.output.parent.mkdir(parents=True, exist_ok=True)
    journal = args.output.with_suffix(".jsonl")
    journal.write_text("")
    with tempfile.TemporaryDirectory(prefix="fiscal-synthetic-bench-") as temp:
        root = Path(temp)
        for case, pdf in generate(root):
            for dpi in args.dpi:
                rendered = PdfiumAdapter().render_page(pdf, 0, dpi=dpi)
                image = Image.frombytes(
                    "RGB",
                    (rendered.width, rendered.height),
                    rendered.pixels,
                    "raw",
                    rendered.mode,
                    rendered.stride,
                )
                for variation, raster in variants(image):
                    path = root / "input.png"
                    raster.save(path)
                    start = time.perf_counter()
                    text = engine.recognize(path)
                    elapsed = time.perf_counter() - start
                    score = score_fields(case.fields, extract_fields(text, case))
                    results.append(
                        {
                            "case": case.name,
                            "dpi": dpi,
                            "variation": variation,
                            "seconds": elapsed,
                            **score,
                        }
                    )
                    with journal.open("a") as checkpoint:
                        checkpoint.write(json.dumps(results[-1]) + "\n")
                print(f"{args.engine} {case.name} {dpi}: done", file=sys.stderr, flush=True)
        blank = root / "blank.png"
        Image.new("RGB", (612, 792), "white").save(blank)
        blank_text = engine.recognize(blank)
    report = {
        "schema": 1,
        "complete": True,
        "corpus": "synthetic-labels-v1",
        "engine": args.engine,
        "python": platform.python_version(),
        "platform": platform.platform(),
        "startup_seconds": startup,
        "model_bytes": engine.model_bytes,
        "blank_false_positive": bool(blank_text.strip()),
        "network_guard": "Python audit hooks; not OS/native/subprocess egress proof",
        "limitations": (
            "Controlled label layouts; not production parser accuracy or representative corpus"
        ),
        "bundle_bytes": None,
        "results": results,
    }
    if args.engine == "tesseract":
        report.update(version=engine.version, model_sha256=engine.model_sha256)
    try:
        import resource

        report["peak_rss_kib"] = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
        report["child_peak_rss_kib"] = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss
    except ImportError:
        report["peak_rss_kib"] = None
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
