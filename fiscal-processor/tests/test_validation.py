from datetime import date
from decimal import Decimal

import pytest

from fiscal_processor.domain import (
    DomainValidationError,
    format_cnpj,
    parse_br_date,
    parse_brl_money,
    validate_cnpj,
)


def test_validates_and_formats_known_valid_cnpj() -> None:
    raw = "46.395.687/0004-55"
    assert validate_cnpj(raw) == "46395687000455"
    assert format_cnpj(raw) == raw


@pytest.mark.parametrize(
    "raw",
    [
        "11.111.111/1111-11",
        "46.395.687/0004-54",
        "123",
    ],
)
def test_rejects_invalid_cnpj(raw: str) -> None:
    with pytest.raises(DomainValidationError):
        validate_cnpj(raw)


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("30/07/2026", date(2026, 7, 30)),
        ("30-07-2026", date(2026, 7, 30)),
        ("2026-07-30", date(2026, 7, 30)),
    ],
)
def test_parses_supported_dates(raw: str, expected: date) -> None:
    assert parse_br_date(raw) == expected


def test_rejects_impossible_date() -> None:
    with pytest.raises(DomainValidationError):
        parse_br_date("31/02/2026")


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("112.000,00", Decimal("112000.00")),
        ("R$ 1.234,56", Decimal("1234.56")),
        ("0,00", Decimal("0.00")),
    ],
)
def test_parses_brazilian_money(raw: str, expected: Decimal) -> None:
    assert parse_brl_money(raw) == expected


def test_rejects_negative_money() -> None:
    with pytest.raises(DomainValidationError):
        parse_brl_money("-1,00")
