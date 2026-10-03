"""Desktop read models independent of Tk and worker threads."""

from collections import Counter
from dataclasses import dataclass

from fiscal_processor.application.batch import BatchResult, DocumentResult

LABELS = {"OK": "Processada", "REVIEW": "Revisar", "FAILED": "Falhou", "SKIPPED": "Já registrada"}


@dataclass(frozen=True, slots=True)
class Summary:
    state: str
    message: str


def summarize(result: BatchResult) -> Summary:
    if result.error_code:
        return Summary(
            "error",
            "Lote interrompido. Feche a planilha e verifique o acesso ao arquivo. "
            "Registros já salvos foram preservados.",
        )
    if result.cancelled:
        return Summary(
            "cancelled", "Cancelado entre documentos. Registros já salvos foram preservados."
        )
    if result.total == 0:
        return Summary("empty", "Nenhum PDF nesta pasta. Escolha outra pasta para começar.")
    counts = Counter(item.outcome for item in result.documents)
    if counts["FAILED"] == result.total:
        return Summary(
            "error", "Nenhum documento foi salvo. Confira os PDFs e a configuração local."
        )
    message = (
        f"{counts['OK']} processadas · {counts['REVIEW']} para revisar · "
        f"{counts['FAILED']} falharam · {counts['SKIPPED']} já registradas"
    )
    if counts["FAILED"] or counts["REVIEW"]:
        return Summary("partial", message + ". Consulte os itens abaixo.")
    if counts["SKIPPED"]:
        return Summary("complete", message + ". Itens já registrados não foram reavaliados.")
    return Summary("success", message)


def row_values(filename: str, result: DocumentResult) -> tuple[str, ...]:
    item = result.extraction
    return (
        filename,
        item.document_type.value if item else "—",
        item.invoice_number or "—" if item else "—",
        f"R$ {item.amount:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
        if item and item.amount is not None
        else "—",
        LABELS[result.outcome],
    )
