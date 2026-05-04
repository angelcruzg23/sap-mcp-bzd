# Audio Transcriber

Transcribe archivos de audio (.mp3, .wav, .m4a, etc.) a texto usando [OpenAI Whisper](https://github.com/openai/whisper).

## Instalación

```bash
pip install -r requirements.txt
```

> Whisper también necesita **ffmpeg** instalado en el sistema:
> - **Windows**: `winget install ffmpeg` o descargar de https://ffmpeg.org/download.html
> - **Mac**: `brew install ffmpeg`
> - **Linux**: `sudo apt install ffmpeg`

## Uso

```bash
# Básico — auto-detecta idioma
python transcriber.py mi_audio.mp3

# Especificar idioma español y modelo más preciso
python transcriber.py mi_audio.mp3 --language es --model small

# Sin timestamps, salida a archivo específico
python transcriber.py mi_audio.mp3 --no-timestamps --output resultado.txt
```

## Modelos disponibles

| Modelo   | Tamaño  | RAM requerida | Velocidad | Precisión |
|----------|---------|---------------|-----------|-----------|
| tiny     | 39 MB   | ~1 GB         | Muy rápido | Baja     |
| base     | 74 MB   | ~1 GB         | Rápido    | Aceptable |
| small    | 244 MB  | ~2 GB         | Medio     | Buena     |
| medium   | 769 MB  | ~5 GB         | Lento     | Muy buena |
| large    | 1550 MB | ~10 GB        | Muy lento | Excelente |

Para español, `small` suele dar buen balance entre velocidad y precisión.

## Ejemplo de salida

Con timestamps (default):
```
[00:00 - 00:05]  Hola, bienvenidos a la reunión de hoy.
[00:05 - 00:12]  Vamos a revisar los pendientes del sprint anterior.
```

Sin timestamps (`--no-timestamps`):
```
Hola, bienvenidos a la reunión de hoy. Vamos a revisar los pendientes del sprint anterior.
```

## Formatos soportados

.mp3, .wav, .m4a, .flac, .ogg, .wma, .aac
