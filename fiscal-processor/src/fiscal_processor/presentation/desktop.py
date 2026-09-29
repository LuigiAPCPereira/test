"""Tk desktop: UI updates only on the main thread; safe batch cancellation."""

import argparse
import os
import subprocess
import sys
import tkinter as tk
from pathlib import Path
from queue import Empty, Queue
from threading import Event, Thread
from tkinter import filedialog, messagebox, ttk

from fiscal_processor.presentation.state import row_values, summarize
from fiscal_processor.presentation.worker import WorkerEvent, run_batch


class Desktop:
    def __init__(self, root: tk.Tk, models: Path | None = None) -> None:
        self.root = root
        self.models = models
        self.events: Queue[WorkerEvent] = Queue()
        self.cancel = Event()
        self.busy = False
        self.folder: Path | None = None
        self.output: Path | None = None
        self.reprocess = tk.BooleanVar(value=False)
        self.folder_text = tk.StringVar(value="Nenhuma pasta selecionada")
        self.status = tk.StringVar(value="Escolha a pasta que contém suas notas fiscais em PDF.")
        self.current = tk.StringVar(value="Os resultados aparecerão aqui após o processamento.")
        root.title("Fiscal Processor")
        root.geometry("1000x680")
        root.minsize(760, 540)
        root.protocol("WM_DELETE_WINDOW", self.close)
        style = ttk.Style(root)
        style.configure("TButton", padding=(12, 8))
        style.configure("Title.TLabel", font=("Segoe UI", 22, "bold"))
        style.configure("Treeview", rowheight=30)
        shell = ttk.Frame(root, padding=24)
        shell.pack(fill="both", expand=True)
        shell.columnconfigure(0, weight=1)
        shell.rowconfigure(7, weight=1)
        ttk.Label(shell, text="Notas fiscais", style="Title.TLabel").grid(
            row=0, column=0, sticky="w"
        )
        ttk.Label(shell, text="Organize os dados dos PDFs em uma planilha local.").grid(
            row=1, column=0, sticky="w", pady=(4, 24)
        )
        selection = ttk.Frame(shell)
        selection.grid(row=2, column=0, sticky="ew")
        selection.columnconfigure(0, weight=1)
        ttk.Label(selection, text="Pasta de entrada").grid(row=0, column=0, sticky="w")
        self.folder_entry = ttk.Entry(selection, textvariable=self.folder_text, state="readonly")
        self.folder_entry.grid(row=1, column=0, sticky="ew", padx=(0, 12), pady=6)
        self.choose = ttk.Button(selection, text="Escolher pasta…", command=self.select_folder)
        self.choose.grid(row=1, column=1)
        actions = ttk.Frame(shell)
        actions.grid(row=3, column=0, sticky="ew", pady=(16, 12))
        self.process = ttk.Button(
            actions, text="Processar notas fiscais", command=self.start, state="disabled"
        )
        self.process.pack(side="left")
        self.stop = ttk.Button(
            actions, text="Cancelar", command=self.request_cancel, state="disabled"
        )
        self.stop.pack(side="left", padx=8)
        self.reprocess_check = ttk.Checkbutton(
            actions, text="Reprocessar já registradas", variable=self.reprocess
        )
        self.reprocess_check.pack(side="left", padx=8)
        self.message = ttk.Label(shell, textvariable=self.status, wraplength=900)
        self.message.grid(row=4, column=0, sticky="ew", pady=(4, 8))
        self.bar = ttk.Progressbar(shell, mode="determinate")
        self.bar.grid(row=5, column=0, sticky="ew")
        self.current_label = ttk.Label(shell, textvariable=self.current, wraplength=900)
        self.current_label.grid(row=6, column=0, sticky="ew", pady=(8, 16))
        table_frame = ttk.Frame(shell)
        table_frame.grid(row=7, column=0, sticky="nsew")
        table_frame.rowconfigure(0, weight=1)
        table_frame.columnconfigure(0, weight=1)
        columns = ("file", "type", "number", "amount", "status")
        self.table = ttk.Treeview(
            table_frame, columns=columns, show="headings", selectmode="browse"
        )
        for name, title, width in zip(
            columns,
            ("Arquivo", "Tipo", "Nº da nota", "Valor", "Situação"),
            (300, 75, 110, 120, 150),
            strict=True,
        ):
            self.table.heading(name, text=title)
            self.table.column(
                name, width=width, minwidth=70, anchor="e" if name == "amount" else "w"
            )
        self.table.grid(row=0, column=0, sticky="nsew")
        vertical = ttk.Scrollbar(table_frame, orient="vertical", command=self.table.yview)
        vertical.grid(row=0, column=1, sticky="ns")
        horizontal = ttk.Scrollbar(table_frame, orient="horizontal", command=self.table.xview)
        horizontal.grid(row=1, column=0, sticky="ew")
        self.table.configure(yscrollcommand=vertical.set, xscrollcommand=horizontal.set)
        self.table.bind("<<TreeviewSelect>>", self.show_detail)
        self.details: dict[str, str] = {}
        footer = ttk.Frame(shell)
        footer.grid(row=8, column=0, sticky="ew", pady=(18, 0))
        self.open_button = ttk.Button(
            footer, text="Abrir planilha", command=self.open_workbook, state="disabled"
        )
        self.open_button.pack(side="left")
        ttk.Label(footer, text="OS, validade e observações são preservadas.").pack(
            side="left", padx=16
        )
        root.bind("<Configure>", self.resize)
        self.choose.focus_set()
        root.after(80, self.poll)

    def resize(self, event: tk.Event) -> None:
        if event.widget == self.root:
            width = max(400, self.root.winfo_width() - 64)
            self.message.configure(wraplength=width)
            self.current_label.configure(wraplength=width)

    def select_folder(self) -> None:
        selected = filedialog.askdirectory(parent=self.root, title="Pasta de notas fiscais")
        if not selected:
            return
        self.folder = Path(selected)
        self.output = None
        self.folder_text.set(str(self.folder))
        self.process.configure(state="normal")
        self.open_button.configure(state="disabled")
        self.status.set(
            "Pasta selecionada. A planilha será salva como Controle_Notas_Fiscais.xlsx nesta pasta."
        )
        self.current.set("Pronto para processar. Subpastas não serão incluídas.")
        self.clear_results()

    def clear_results(self) -> None:
        for item in self.table.get_children():
            self.table.delete(item)
        self.details.clear()
        self.bar.configure(value=0)

    def start(self) -> None:
        if self.busy or self.folder is None:
            return
        self.busy = True
        self.cancel.clear()
        self.clear_results()
        self.output = self.folder / "Controle_Notas_Fiscais.xlsx"
        for widget in (self.choose, self.process, self.reprocess_check, self.open_button):
            widget.configure(state="disabled")
        self.stop.configure(state="normal")
        self.status.set("Processando notas fiscais…")
        self.current.set("Procurando PDFs na pasta selecionada…")
        Thread(
            target=run_batch,
            args=(
                self.folder,
                self.output,
                self.models,
                self.reprocess.get(),
                self.cancel,
                self.events,
            ),
            daemon=False,
        ).start()

    def request_cancel(self) -> None:
        if self.busy:
            self.cancel.set()
            self.stop.configure(state="disabled")
            self.status.set(
                "Cancelamento solicitado. Aguardando a conclusão e gravação do documento atual…"
            )

    def poll(self) -> None:
        for _ in range(100):
            try:
                event = self.events.get_nowait()
            except Empty:
                break
            self.handle(event)
        self.root.after(80, self.poll)

    def handle(self, event: WorkerEvent) -> None:
        if event.kind == "ready":
            self.bar.configure(maximum=max(event.total, 1), value=0)
        elif event.kind == "started":
            self.current.set(f"Processando: {event.filename}")
        elif event.kind == "document" and event.document is not None:
            item = event.document
            key = self.table.insert("", "end", values=row_values(event.filename, item))
            self.details[key] = (
                "Confira os campos vazios e os motivos de revisão na planilha."
                if item.outcome == "REVIEW"
                else "Documento não salvo. Confira o PDF e a instalação local."
                if item.outcome == "FAILED"
                else "Conteúdo já registrado; os dados anteriores não foram reavaliados."
                if item.outcome == "SKIPPED"
                else "Dados extraídos e salvos na planilha."
            )
            if item.error_code and item.error_code.startswith("WORKBOOK_"):
                self.details[key] = (
                    "Não foi possível acessar ou salvar a planilha. Feche o Excel, "
                    "verifique a permissão da pasta e tente novamente."
                )
            self.bar.configure(value=item.index)
            self.current.set(f"{item.index} de {event.total} documentos concluídos")
        elif event.kind in ("done", "error"):
            self.busy = False
            self.stop.configure(state="disabled")
            for widget in (self.choose, self.process, self.reprocess_check):
                widget.configure(state="normal")
            summary = summarize(event.batch) if event.batch is not None else None
            self.status.set(
                summary.message
                if summary is not None
                else "Não foi possível processar a pasta. Verifique o acesso e a instalação local."
            )
            self.current.set(
                "Selecione um item para ver orientações."
                if self.table.get_children()
                else "Não há itens concluídos para detalhar."
            )
            if self.output is not None and self.output.is_file():
                self.open_button.configure(state="normal")
            self.process.focus_set()

    def show_detail(self, event: tk.Event) -> None:
        selected = self.table.selection()
        if selected:
            self.current.set(self.details.get(selected[0], ""))

    def open_workbook(self) -> None:
        if self.busy or self.output is None or not self.output.is_file():
            return
        try:
            path = str(self.output.resolve())
            if sys.platform == "win32":
                os.startfile(path)
            else:
                subprocess.Popen(
                    ["open" if sys.platform == "darwin" else "xdg-open", path],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
        except OSError:
            messagebox.showerror(
                "Não foi possível abrir",
                "Abra Controle_Notas_Fiscais.xlsx na pasta selecionada.",
                parent=self.root,
            )

    def close(self) -> None:
        if self.busy:
            self.request_cancel()
            return
        self.root.destroy()


def main() -> None:
    parser = argparse.ArgumentParser(description="Fiscal Processor desktop")
    parser.add_argument("--models", type=Path)
    args = parser.parse_args()
    models = args.models
    if models is None and getattr(sys, "frozen", False):
        models = Path(sys.executable).parent / "models"
    root = tk.Tk()
    Desktop(root, models)
    root.mainloop()


if __name__ == "__main__":
    main()
