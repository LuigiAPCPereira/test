"""Text evidence shared by PDF/OCR adapters and parsers, in PDF points."""

import math
from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class TextSpan:
    text: str
    left: float
    top: float
    right: float
    bottom: float
    page: int = 0

    def __post_init__(self) -> None:
        if type(self.page) is not int or self.page < 0:
            raise ValueError("page must be a nonnegative integer")
        if not all(math.isfinite(v) for v in (self.left, self.top, self.right, self.bottom)):
            raise ValueError("coordinates must be finite")
        if self.right < self.left or self.bottom < self.top:
            raise ValueError("coordinates must use a top-left origin")
