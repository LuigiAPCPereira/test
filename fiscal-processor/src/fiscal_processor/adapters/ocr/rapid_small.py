"""Pinned small OCR. Models must already exist; never provision at runtime."""

import hashlib
import importlib.metadata
from pathlib import Path
from typing import Any

from fiscal_processor.domain.text import OcrPage, RenderedPage, TextSpan

MODELS = {
    "Det": (
        "PP-OCRv6_det_small.onnx",
        "090f04abcd9d9a7498bc4ebf677e4cb9bdce1fe4197ddb7e529f1ef44e1ff94f",
    ),
    "Rec": (
        "PP-OCRv6_rec_small.onnx",
        "6f327246b50388f3c176ae304bd95767ea6dc0c9ae92153ef8cbe210b3c14884",
    ),
    "Cls": (
        "ch_ppocr_mobile_v2.0_cls_mobile.onnx",
        "e47acedf663230f8863ff1ab0e64dd2d82b838fceb5957146dab185a89d6215c",
    ),
}


class OcrAdapterError(RuntimeError):
    """Sanitized failure; callers must not report successful extraction."""


class RapidSmallAdapter:
    def __init__(self, model_dir: Path) -> None:
        self._model_dir = model_dir
        self._engine: Any = None

    def _load(self) -> Any:
        try:
            paths = {}
            for task, (name, expected) in MODELS.items():
                path = self._model_dir / name
                with path.open("rb") as stream:
                    if hashlib.file_digest(stream, "sha256").hexdigest() != expected:
                        raise OcrAdapterError("OCR_MODEL_INVALID")
                paths[task] = path.resolve()
            for package, version in [("rapidocr", "3.9.2"), ("onnxruntime", "1.24.2")]:
                if importlib.metadata.version(package) != version:
                    raise OcrAdapterError("OCR_VERSION_MISMATCH")
            from rapidocr import ModelType, RapidOCR

            params: dict[str, Any] = {
                f"{task}.model_path": str(path) for task, path in paths.items()
            }
            params.update(
                {
                    "Global.log_level": "critical",
                    "Global.use_cls": False,
                    "EngineConfig.onnxruntime.intra_op_num_threads": 1,
                    "EngineConfig.onnxruntime.inter_op_num_threads": 1,
                    "Det.model_type": ModelType.SMALL,
                    "Rec.model_type": ModelType.SMALL,
                    "Det.lang_type": "pt",
                    "Rec.lang_type": "pt",
                }
            )
            return RapidOCR(params=params)
        except OcrAdapterError:
            raise
        except Exception:
            raise OcrAdapterError("OCR_INITIALIZATION_FAILED") from None

    def recognize(self, page: RenderedPage, page_index: int) -> OcrPage:
        try:
            if self._engine is None:
                self._engine = self._load()
            import numpy as np
            from PIL import Image

            with Image.frombytes(
                "RGB", (page.width, page.height), page.pixels, "raw", page.mode, page.stride
            ) as image:
                # RapidOCR numpy input uses OpenCV BGR; no image written to disk.
                output = self._engine(np.asarray(image)[:, :, ::-1].copy())
            if output.boxes is None or output.txts is None:
                return OcrPage((), low_quality=True)
            scale = page.dpi / 72
            spans = tuple(
                TextSpan(
                    text,
                    float(min(p[0] for p in box)) / scale,
                    float(min(p[1] for p in box)) / scale,
                    float(max(p[0] for p in box)) / scale,
                    float(max(p[1] for p in box)) / scale,
                    page_index,
                )
                for box, text in zip(output.boxes, output.txts, strict=True)
            )
            return OcrPage(spans, low_quality=not spans)
        except OcrAdapterError:
            raise
        except Exception:
            raise OcrAdapterError("OCR_RECOGNITION_FAILED") from None
