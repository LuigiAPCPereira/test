"""Excel workbook persistence adapter."""

from .openpyxl_store import (
    ExcelStoreError,
    OpenpyxlInvoiceStore,
    UpsertOutcome,
    UpsertResult,
    WorkbookContractError,
    WorkbookLockedError,
)

__all__ = [
    "ExcelStoreError",
    "OpenpyxlInvoiceStore",
    "UpsertOutcome",
    "UpsertResult",
    "WorkbookContractError",
    "WorkbookLockedError",
]
