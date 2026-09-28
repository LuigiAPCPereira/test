"""Pure deterministic validators and normalizers for Brazilian fiscal fields."""

import re
from datetime import date, datetime
from decimal import Decimal, InvalidOperation

_DIGITS_RE = re.compile(r"\D+")


class DomainValidationError(ValueError):
    """Raised when an observed field is present but invalid."""


def normalize_cnpj(value: str) -> str:
    digits = _DIGITS_RE.sub("", value)
    if len(digits) != 14:
        raise DomainValidationError("CNPJ must contain exactly 14 digits")
    return digits


def _cnpj_check_digit(base: str, weights: tuple[int, ...]) -> str:
    total = sum(int(digit) * weight for digit, weight in zip(base, weights, strict=True))
    remainder = total % 11
    return "0" if remainder < 2 else str(11 - remainder)


def validate_cnpj(value: str) -> str:
    digits = normalize_cnpj(value)
    if len(set(digits)) == 1:
        raise DomainValidationError("CNPJ cannot contain fourteen repeated digits")

    first = _cnpj_check_digit(digits[:12], (5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2))
    second = _cnpj_check_digit(
        digits[:12] + first,
        (6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2),
    )
    expected = digits[:12] + first + second
    if digits != expected:
        raise DomainValidationError("CNPJ check digits are invalid")
    return digits


def format_cnpj(value: str) -> str:
    digits = validate_cnpj(value)
    return (
        f"{digits[0:2]}.{digits[2:5]}.{digits[5:8]}/"
        f"{digits[8:12]}-{digits[12:14]}"
    )


def parse_br_date(value: str) -> date:
    text = value.strip()
    if not text:
        raise DomainValidationError("date must not be blank")

    for pattern in ("%d/%m/%Y", "%d-%m-%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(text, pattern).date()
        except ValueError:
            continue
    raise DomainValidationError("date must use DD/MM/YYYY, DD-MM-YYYY or YYYY-MM-DD")


def parse_brl_money(value: str) -> Decimal:
    text = value.strip().replace("R$", "").replace("\u00a0", "").replace(" ", "")
    if not text:
        raise DomainValidationError("money value must not be blank")

    if "," in text:
        normalized = text.replace(".", "").replace(",", ".")
    else:
        normalized = text

    try:
        amount = Decimal(normalized)
    except InvalidOperation as exc:
        raise DomainValidationError("money value is not numeric") from exc

    if not amount.is_finite():
        raise DomainValidationError("money value must be finite")
    if amount < 0:
        raise DomainValidationError("money value must not be negative")
    return amount
