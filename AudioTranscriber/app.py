"""
Audio Transcriber — App de escritorio para transcribir audio a texto.
Ejecutar: python app.py
"""

import os
import threading
import time
import tkinter as tk
from tkinter import ttk, filedialog, scrolledtext


class AudioTranscriberApp:

    SUPPORTED_FORMATS = (
        ("Archivos de audio", "*.mp3 *.wav *.m4a *.flac *.ogg *.wma *.aac"),
        ("MP3", "*.mp3"),
        ("WAV", "*.wav"),
        ("Todos", "*.*"),
    )

    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Audio Transcriber")
        self.root.geometry("850x700")
        self.root.minsize(700, 550)
        self.root.configure(bg="#1e1e2e")

        self._model = None
        self._model_name = None
        self._is_busy = False
        self._timer_start = 0.0
        self._timer_phase = ""
        self._timer_job = None

        self._setup_styles()
        self._build_ui()

    # ── Styles ──────────────────────────────────────────────

    def _setup_styles(self):
        bg = "#1e1e2e"
        fg = "#cdd6f4"
        accent = "#89b4fa"
        surface = "#313244"
        green = "#a6e3a1"
        self._c = {"bg": bg, "fg": fg, "accent": accent, "surface": surface, "green": green}

        s = ttk.Style()
        s.theme_use("clam")
        s.configure("TFrame", background=bg)
        s.configure("TLabel", background=bg, foreground=fg, font=("Segoe UI", 10))
        s.configure("Title.TLabel", background=bg, foreground=fg, font=("Segoe UI", 16, "bold"))
        s.configure("Status.TLabel", background=bg, foreground=green, font=("Segoe UI", 9))
        s.configure("TButton", background=accent, foreground="#1e1e2e",
                     font=("Segoe UI", 10, "bold"), padding=8)
        s.map("TButton", background=[("active", "#74c7ec"), ("disabled", "#585b70")])
        s.configure("TCombobox", fieldbackground=surface, foreground=fg,
                     background=surface, font=("Segoe UI", 10))
        s.map("TCombobox",
              fieldbackground=[("readonly", surface)],
              foreground=[("readonly", fg)],
              selectbackground=[("readonly", surface)],
              selectforeground=[("readonly", fg)])
        s.configure("TCheckbutton", background=bg, foreground=fg, font=("Segoe UI", 10))
        s.configure("Horizontal.TProgressbar", background=accent, troughcolor=surface)

        self.root.option_add("*TCombobox*Listbox.background", surface)
        self.root.option_add("*TCombobox*Listbox.foreground", fg)
        self.root.option_add("*TCombobox*Listbox.selectBackground", accent)
        self.root.option_add("*TCombobox*Listbox.selectForeground", "#1e1e2e")

    # ── UI ──────────────────────────────────────────────────

    def _build_ui(self):
        main = ttk.Frame(self.root, padding=20)
        main.pack(fill=tk.BOTH, expand=True)

        ttk.Label(main, text="🎙 Audio Transcriber", style="Title.TLabel").pack(anchor=tk.W)
        ttk.Label(main, text="Transcribe audio a texto usando Whisper (local, sin internet)"
                  ).pack(anchor=tk.W, pady=(0, 15))

        # File picker
        ff = ttk.Frame(main)
        ff.pack(fill=tk.X, pady=(0, 10))
        self._file_var = tk.StringVar()
        tk.Entry(ff, textvariable=self._file_var, font=("Segoe UI", 10),
                 bg=self._c["surface"], fg=self._c["fg"],
                 insertbackground=self._c["fg"], relief=tk.FLAT, bd=5
                 ).pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 8))
        ttk.Button(ff, text="📂 Buscar audio", command=self._browse).pack(side=tk.RIGHT)

        # Options
        of = ttk.Frame(main)
        of.pack(fill=tk.X, pady=(0, 10))
        ttk.Label(of, text="Modelo:").pack(side=tk.LEFT, padx=(0, 5))
        self._model_var = tk.StringVar(value="small")
        ttk.Combobox(of, textvariable=self._model_var, state="readonly", width=12,
                     values=["tiny", "base", "small", "medium", "large"]
                     ).pack(side=tk.LEFT, padx=(0, 15))
        ttk.Label(of, text="Idioma:").pack(side=tk.LEFT, padx=(0, 5))
        self._lang_var = tk.StringVar(value="auto")
        ttk.Combobox(of, textvariable=self._lang_var, state="readonly", width=8,
                     values=["auto", "en", "es", "fr", "pt", "de", "it", "ja", "zh"]
                     ).pack(side=tk.LEFT, padx=(0, 15))
        self._ts_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(of, text="Timestamps", variable=self._ts_var).pack(side=tk.LEFT)

        # Buttons
        bf = ttk.Frame(main)
        bf.pack(fill=tk.X, pady=(0, 10))
        self._btn_go = ttk.Button(bf, text="▶  Transcribir", command=self._on_transcribe)
        self._btn_go.pack(side=tk.LEFT)
        self._btn_save = ttk.Button(bf, text="💾 Guardar .txt", command=self._on_save, state=tk.DISABLED)
        self._btn_save.pack(side=tk.LEFT, padx=(10, 0))
        self._btn_copy = ttk.Button(bf, text="📋 Copiar", command=self._on_copy, state=tk.DISABLED)
        self._btn_copy.pack(side=tk.LEFT, padx=(10, 0))

        # Progress
        self._progress = ttk.Progressbar(main, mode="indeterminate")
        self._progress.pack(fill=tk.X, pady=(0, 5))

        # Status
        self._status_var = tk.StringVar(value="Listo. Selecciona un archivo de audio.")
        ttk.Label(main, textvariable=self._status_var, style="Status.TLabel").pack(anchor=tk.W, pady=(0, 5))

        # Result area
        self._text = scrolledtext.ScrolledText(
            main, wrap=tk.WORD, font=("Consolas", 10),
            bg=self._c["surface"], fg=self._c["fg"],
            insertbackground=self._c["fg"], relief=tk.FLAT, bd=8,
            selectbackground=self._c["accent"], selectforeground="#1e1e2e")
        self._text.pack(fill=tk.BOTH, expand=True)
        self._text.insert(tk.END, "La transcripción aparecerá aquí...\n\n"
                          "Selecciona un archivo .mp3, .wav, .m4a y presiona Transcribir.")
        self._text.configure(state=tk.DISABLED)

    # ── Actions ─────────────────────────────────────────────

    def _browse(self):
        p = filedialog.askopenfilename(
            title="Seleccionar archivo de audio",
            filetypes=self.SUPPORTED_FORMATS,
            initialdir=os.path.expanduser("~/Downloads"))
        if p:
            self._file_var.set(p)

    def _on_transcribe(self):
        path = self._file_var.get().strip()
        if not path:
            self._status_var.set("⚠ Selecciona un archivo primero.")
            return
        if not os.path.exists(path):
            self._status_var.set(f"⚠ No existe: {path}")
            return
        if self._is_busy:
            return

        self._is_busy = True
        self._btn_go.configure(state=tk.DISABLED)
        self._btn_save.configure(state=tk.DISABLED)
        self._btn_copy.configure(state=tk.DISABLED)
        self._progress.start(15)

        # Limpiar área de texto
        self._text.configure(state=tk.NORMAL)
        self._text.delete("1.0", tk.END)

        threading.Thread(target=self._worker, args=(path,), daemon=True).start()

    def _on_save(self):
        text = self._text.get("1.0", tk.END).strip()
        if not text:
            return
        audio = self._file_var.get().strip()
        base = os.path.splitext(os.path.basename(audio))[0] if audio else "transcripcion"
        p = filedialog.asksaveasfilename(
            title="Guardar transcripción", defaultextension=".txt",
            initialfile=f"{base}_transcripcion.txt",
            initialdir=os.path.dirname(audio) if audio else os.path.expanduser("~/Downloads"),
            filetypes=[("Texto", "*.txt"), ("Todos", "*.*")])
        if p:
            with open(p, "w", encoding="utf-8") as f:
                f.write(text + "\n")
            self._status_var.set(f"💾 Guardado: {p}")

    def _on_copy(self):
        text = self._text.get("1.0", tk.END).strip()
        if text:
            self.root.clipboard_clear()
            self.root.clipboard_append(text)
            self._status_var.set("📋 Copiado al portapapeles.")

    # ── Timer ───────────────────────────────────────────────

    def _start_timer(self, phase):
        self._stop_timer()
        self._timer_start = time.time()
        self._timer_phase = phase
        self._tick()

    def _tick(self):
        if not self._is_busy:
            return
        elapsed = int(time.time() - self._timer_start)
        m, s = divmod(elapsed, 60)
        spinner = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        icon = spinner[elapsed % len(spinner)]
        self._status_var.set(f"{icon} {self._timer_phase}... {m}:{s:02d}")
        self._timer_job = self.root.after(500, self._tick)

    def _stop_timer(self):
        if self._timer_job:
            self.root.after_cancel(self._timer_job)
            self._timer_job = None

    # ── Worker (background thread) ──────────────────────────

    def _worker(self, file_path):
        try:
            import whisper

            model_name = self._model_var.get()
            lang = self._lang_var.get()
            lang = None if lang == "auto" else lang
            show_ts = self._ts_var.get()

            size_mb = os.path.getsize(file_path) / (1024 * 1024)

            # ── Cargar modelo (con cache) ──
            if self._model and self._model_name == model_name:
                load_time = 0.0
                self.root.after(0, lambda: self._start_timer("Transcribiendo"))
            else:
                self.root.after(0, lambda: self._start_timer(f"Descargando modelo '{model_name}'"))
                t0 = time.time()
                self._model = whisper.load_model(model_name)
                self._model_name = model_name
                load_time = time.time() - t0
                self.root.after(0, lambda: self._start_timer("Transcribiendo"))

            # ── Transcribir ──
            opts = {}
            if lang:
                opts["language"] = lang

            t0 = time.time()
            result = self._model.transcribe(file_path, **opts)
            tx_time = time.time() - t0

            # ── Mostrar resultado segmento por segmento ──
            detected = result.get("language", "?")
            segments = result.get("segments", [])

            # Limpiar y escribir
            self.root.after(0, lambda: self._text.delete("1.0", tk.END))
            time.sleep(0.05)  # dar tiempo al after de ejecutar

            for seg in segments:
                t_start = self._fmt(seg["start"])
                t_end = self._fmt(seg["end"])
                txt = seg["text"].strip()
                if show_ts:
                    line = f"[{t_start} → {t_end}]  {txt}\n"
                else:
                    line = f"{txt} "
                self.root.after(0, lambda l=line: self._append(l))
                time.sleep(0.03)

            # ── Status final ──
            total = load_time + tx_time
            msg = (f"✅ Listo en {total:.0f}s "
                   f"(modelo: {load_time:.0f}s + transcripción: {tx_time:.0f}s) "
                   f"— Idioma: {detected} — {size_mb:.1f} MB")
            self.root.after(0, lambda: self._status_var.set(msg))

        except ImportError:
            self.root.after(0, lambda: self._status_var.set(
                "❌ Instala whisper: pip install openai-whisper torch"))
        except Exception as e:
            self.root.after(0, lambda: self._status_var.set(f"❌ Error: {e}"))
        finally:
            self.root.after(0, self._done)

    def _done(self):
        self._is_busy = False
        self._stop_timer()
        self._progress.stop()
        self._text.configure(state=tk.DISABLED)
        self._btn_go.configure(state=tk.NORMAL)
        self._btn_save.configure(state=tk.NORMAL)
        self._btn_copy.configure(state=tk.NORMAL)

    # ── Helpers ─────────────────────────────────────────────

    def _fmt(self, seconds):
        h = int(seconds // 3600)
        m = int((seconds % 3600) // 60)
        s = int(seconds % 60)
        return f"{h:02d}:{m:02d}:{s:02d}" if h else f"{m:02d}:{s:02d}"

    def _append(self, text):
        self._text.insert(tk.END, text)
        self._text.see(tk.END)

    def run(self):
        self.root.mainloop()


if __name__ == "__main__":
    AudioTranscriberApp().run()
