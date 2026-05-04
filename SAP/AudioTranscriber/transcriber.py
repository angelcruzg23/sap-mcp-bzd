"""
Audio Transcriber — Transcribe archivos .mp3 a texto usando Whisper (OpenAI).
Uso: python transcriber.py <archivo.mp3> [--model base] [--language es]
"""

import argparse
import sys
import os
import time


def check_dependencies():
    """Verifica que las dependencias estén instaladas."""
    missing = []
    try:
        import whisper  # noqa: F401
    except ImportError:
        missing.append("openai-whisper")

    try:
        import torch  # noqa: F401
    except ImportError:
        missing.append("torch")

    if missing:
        print("Faltan dependencias. Instálalas con:")
        print(f"  pip install {' '.join(missing)}")
        sys.exit(1)


def transcribe_audio(file_path: str, model_name: str = "base", language: str = None) -> dict:
    """
    Transcribe un archivo de audio a texto.

    Args:
        file_path: Ruta al archivo de audio (.mp3, .wav, .m4a, etc.)
        model_name: Modelo Whisper a usar (tiny, base, small, medium, large)
        language: Código de idioma (es, en, fr, etc.) o None para auto-detectar

    Returns:
        dict con 'text' (transcripción completa) y 'segments' (segmentos con timestamps)
    """
    import whisper

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"No se encontró el archivo: {file_path}")

    supported_extensions = {".mp3", ".wav", ".m4a", ".flac", ".ogg", ".wma", ".aac"}
    ext = os.path.splitext(file_path)[1].lower()
    if ext not in supported_extensions:
        raise ValueError(f"Formato no soportado: {ext}. Usa: {', '.join(supported_extensions)}")

    file_size_mb = os.path.getsize(file_path) / (1024 * 1024)
    print(f"Archivo: {os.path.basename(file_path)} ({file_size_mb:.1f} MB)")
    print(f"Modelo: {model_name}")
    print(f"Idioma: {language or 'auto-detectar'}")
    print()

    print("Cargando modelo Whisper...")
    start = time.time()
    model = whisper.load_model(model_name)
    print(f"Modelo cargado en {time.time() - start:.1f}s")

    print("Transcribiendo...")
    start = time.time()

    options = {}
    if language:
        options["language"] = language

    result = model.transcribe(file_path, **options)
    elapsed = time.time() - start
    print(f"Transcripción completada en {elapsed:.1f}s")

    return result


def format_timestamp(seconds: float) -> str:
    """Convierte segundos a formato HH:MM:SS."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    if hours > 0:
        return f"{hours:02d}:{minutes:02d}:{secs:02d}"
    return f"{minutes:02d}:{secs:02d}"


def save_transcription(result: dict, output_path: str, include_timestamps: bool = True):
    """
    Guarda la transcripción en un archivo de texto.

    Args:
        result: Resultado de whisper.transcribe()
        output_path: Ruta del archivo de salida
        include_timestamps: Si True, incluye timestamps por segmento
    """
    with open(output_path, "w", encoding="utf-8") as f:
        if include_timestamps and result.get("segments"):
            for segment in result["segments"]:
                start = format_timestamp(segment["start"])
                end = format_timestamp(segment["end"])
                text = segment["text"].strip()
                f.write(f"[{start} - {end}]  {text}\n")
        else:
            f.write(result["text"].strip())
            f.write("\n")

    print(f"\nTranscripción guardada en: {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Transcribe archivos de audio a texto usando Whisper."
    )
    parser.add_argument(
        "audio_file",
        help="Ruta al archivo de audio (.mp3, .wav, .m4a, etc.)"
    )
    parser.add_argument(
        "--model", "-m",
        default="base",
        choices=["tiny", "base", "small", "medium", "large"],
        help="Modelo Whisper (tiny=rápido/menos preciso, large=lento/más preciso). Default: base"
    )
    parser.add_argument(
        "--language", "-l",
        default=None,
        help="Código de idioma (es=español, en=inglés). Default: auto-detectar"
    )
    parser.add_argument(
        "--output", "-o",
        default=None,
        help="Archivo de salida. Default: mismo nombre con extensión .txt"
    )
    parser.add_argument(
        "--no-timestamps",
        action="store_true",
        help="Omitir timestamps en la salida"
    )

    args = parser.parse_args()

    check_dependencies()

    if args.output is None:
        base = os.path.splitext(args.audio_file)[0]
        args.output = f"{base}_transcripcion.txt"

    result = transcribe_audio(args.audio_file, args.model, args.language)

    detected_lang = result.get("language", "desconocido")
    print(f"\nIdioma detectado: {detected_lang}")
    print(f"\n--- Transcripción ---\n")
    print(result["text"].strip())
    print(f"\n--- Fin ---\n")

    save_transcription(result, args.output, include_timestamps=not args.no_timestamps)


if __name__ == "__main__":
    main()
