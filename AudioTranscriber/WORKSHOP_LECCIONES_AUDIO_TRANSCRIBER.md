# Workshop: Construyendo una App de Transcripción de Audio con Kiro

## 🎯 Caso de uso

Crear una aplicación de escritorio que transcriba archivos de audio (.mp3) a texto, corriendo 100% local sin APIs de pago ni internet.

**Resultado:** App funcional con GUI en ~30 minutos de conversación con Kiro.

---

## 📊 Timeline real de la sesión

| Paso | Qué hicimos | Tiempo aprox |
|------|-------------|--------------|
| 1 | Kiro genera script CLI + README + requirements.txt | 2 min |
| 2 | Instalación de dependencias (whisper, torch, ffmpeg) | 5 min |
| 3 | Primera prueba con audio real (modelo base) | 3 min transcripción |
| 4 | Segunda prueba con modelo small (mejor calidad) | 2 min transcripción |
| 5 | Kiro genera app de escritorio con GUI (Tkinter) | 3 min |
| 6 | Iteraciones de UI: colores, timer, feedback visual | 10 min |
| 7 | Optimización de rendimiento (cache de modelo) | 5 min |
| 8 | Push a GitHub para usar en otro equipo | 2 min |

**Total: ~30 minutos desde "quiero transcribir audio" hasta app funcional en GitHub.**

---

## 🧠 Lecciones aprendidas

### 1. Kiro como acelerador: de idea a prototipo funcional en minutos

No escribimos una sola línea de código manualmente. Le dijimos a Kiro qué queríamos y él:
- Eligió la librería correcta (Whisper de OpenAI)
- Generó el script CLI completo con manejo de errores
- Instaló las dependencias
- Ejecutó las pruebas
- Generó la app de escritorio

**Lección:** Kiro no solo genera código — ejecuta, prueba y corrige. El desarrollador se enfoca en **qué quiere** y en **validar el resultado**.

### 2. Iterar es más poderoso que especificar todo de entrada

No empezamos pidiendo "una app con GUI, timer, cache de modelo y soporte multiidioma". Empezamos con:
1. "Transcribe este audio" → script CLI
2. "Hazlo app de escritorio" → GUI con Tkinter
3. "No veo que esté haciendo algo" → timer en vivo
4. "Los colores no se ven" → fix de estilos
5. "Cómo puede ser más rápido" → cache de modelo

**Lección:** Construir incrementalmente con feedback visual es más efectivo que intentar especificar todo de una vez. Cada iteración fue una mejora concreta validada en el momento.

### 3. El feedback visual importa más de lo que crees

La app transcribía correctamente desde la primera versión, pero el usuario no lo sabía porque:
- La barra de progreso no daba información útil
- El área de texto estaba vacía durante 3 minutos
- No había indicación de cuánto faltaba

Agregar un simple timer con spinner (`⠋ Transcribiendo... 1:24`) cambió completamente la percepción.

**Lección:** Una app que funciona pero no comunica su estado se siente rota. El UX no es un lujo — es parte de que funcione.

### 4. Kiro detecta y resuelve dependencias del sistema

Whisper necesita `ffmpeg` para decodificar audio. Kiro:
1. Detectó que no estaba instalado
2. Lo instaló con `winget`
3. Refrescó el PATH
4. Verificó que funcionara

**Lección:** Kiro maneja el entorno completo, no solo el código. Esto es especialmente útil cuando trabajas con librerías que tienen dependencias de sistema (ffmpeg, CUDA, etc.).

### 5. Probar con datos reales desde el inicio

No usamos archivos de prueba sintéticos. Desde el primer minuto usamos audios reales del usuario. Esto reveló:
- El primer audio era en inglés, no en español como asumimos → forzar `--language es` daba basura
- El modelo `base` no era suficiente para audio bilingüe → `small` dio resultados limpios
- El audio de 8 minutos tardaba 3 minutos en CPU → expectativa correcta desde el inicio

**Lección:** Probar con datos reales temprano evita sorpresas tardías. "Funciona con el ejemplo" no significa "funciona con mi caso".

### 6. Entender los trade-offs: modelo vs velocidad vs calidad

| Modelo | Tiempo (8 min audio) | Calidad |
|--------|---------------------|---------|
| tiny | ~40s | Baja — errores frecuentes |
| base | ~90s | Aceptable — falla con bilingüe |
| small | ~180s | Buena — balance ideal ★ |
| medium | ~400s | Muy buena — lento en CPU |
| large | ~800s | Excelente — impracticable sin GPU |

**Lección:** No siempre necesitas el modelo más grande. `small` dio transcripciones limpias y coherentes. La decisión correcta depende del hardware disponible y la tolerancia al tiempo de espera.

### 7. El código local tiene ventajas reales

- **Privacidad:** El audio nunca sale de tu máquina
- **Costo:** $0 por transcripción, sin límites
- **Disponibilidad:** Funciona sin internet
- **Control:** Puedes elegir modelo, idioma, formato de salida

**Lección:** No todo necesita ser cloud. Para herramientas personales de productividad, local-first es una estrategia válida y a menudo superior.

### 8. Kiro facilita la portabilidad entre equipos

Al final de la sesión, el código estaba listo para GitHub con un solo comando. En el otro equipo (Mac):
```bash
git pull
pip install -r requirements.txt
brew install ffmpeg
python app.py
```

**Lección:** Kiro genera código estándar y portable. No hay dependencia de Kiro para ejecutar lo que genera — es Python puro que corre en cualquier máquina.

---

## 🛠 Stack tecnológico utilizado

| Componente | Tecnología | Por qué |
|------------|-----------|---------|
| Transcripción | OpenAI Whisper | Open source, local, multiidioma |
| GUI | Tkinter | Incluido con Python, sin dependencias extra |
| Audio decoding | ffmpeg | Estándar de la industria |
| ML runtime | PyTorch | Backend de Whisper |
| IDE | Kiro | Generación, ejecución y debugging asistido por IA |

---

## 💡 Ideas para extender (próximos workshops)

1. **faster-whisper** — 2-4x más rápido en CPU, mismo resultado
2. **Exportar a SRT** — subtítulos para video
3. **Drag & drop** — arrastrar archivos a la ventana
4. **Resumen automático** — pasar la transcripción por un LLM para generar resumen
5. **Batch processing** — transcribir una carpeta entera de audios
6. **API mode** — exponer como servicio REST para integrar con otras apps

---

## 🎤 Frase de cierre para el workshop

> "En 30 minutos, sin escribir una línea de código manualmente, construimos una app de escritorio que transcribe audio a texto usando IA local. Kiro no reemplaza al desarrollador — lo convierte en un arquitecto que valida y dirige, mientras la IA ejecuta."
