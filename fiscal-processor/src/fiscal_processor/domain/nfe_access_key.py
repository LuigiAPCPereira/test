"""Deterministic parsing and validation of Brazilian NF-e access keys."""

from dataclasses import dataclass

from .validation import DomainValidationError


def _check_digit(base43: str) -> str:
    weights = (2, 3, 4, 5, 6, 7, 8, 9)
    total = sum(int(digit) * weights[index % 8] for index, digit in enumerate(reversed(base43)))
    remainder = total % 11
    digit = 11 - remainder
    return "0" if digit >= 10 else str(digit)


def normalize_nfe_access_key(value: str) -> str:
    """Remove only whitespace from a printed/grouped access key."""
    compact = "".join(value.split())
    if not compact.isdigit():
        raise DomainValidationError("NF-e access key must contain only digits and whitespace")
    if len(compact) != 44:
        raise DomainValidationError("NF-e access key must contain exactly 44 digits")
    return compact


@dataclass(frozen=True, slots=True)
class NfeAccessKey:
    raw: str
    digits: str
    uf_code: str
    aamm: str
    issuer_cnpj: str
    model: str
    series: str
    invoice_number: str
    emission_type: str
    numeric_code: str
    check_digit: str

    @classmethod
    def parse(cls, value: str) -> "NfeAccessKey":
        digits = normalize_nfe_access_key(value)
        expected = _check_digit(digits[:43])
        if digits[43] != expected:
            raise DomainValidationError("NF-e access key check digit is invalid")
        return cls(
            raw=value,
            digits=digits,
            uf_code=digits[0:2],
            aamm=digits[2:6],
            issuer_cnpj=digits[6:20],
            model=digits[20:22],
            series=digits[22:25],
            invoice_number=digits[25:34],
            emission_type=digits[34:35],
            numeric_code=digits[35:43],
            check_digit=digits[43],
        )
