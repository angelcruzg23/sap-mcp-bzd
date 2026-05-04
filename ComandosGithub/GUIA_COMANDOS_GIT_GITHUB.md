# Guía de Comandos Git & GitHub

Referencia práctica basada en los comandos reales ejecutados durante la sesión de configuración del MCP Server multi-sistema (BZD + BZN).

---

## 1. Diagnóstico — ¿En qué estado está mi repo?

### `git status`

```bash
git status
```

**Qué hace**: Muestra el estado actual del repositorio — qué archivos fueron modificados, cuáles están staged (listos para commit), cuáles son nuevos (untracked) y cuáles fueron eliminados.

**Cuándo usarlo**: Siempre antes de hacer commit o push. Es tu "dashboard" de Git.

**Ejemplo de salida**:
```
On branch master
Your branch is ahead of 'origin/master' by 1 commit.

Changes not staged for commit:
        modified:   server.py
        deleted:    ATP_JuanDa/ANALISIS_ATP_OBJETOS.md

Untracked files:
        SAP/
```

**Interpretación**:
- `modified` — archivo existente que cambió
- `deleted` — archivo que existía en Git pero fue borrado del disco
- `Untracked files` — archivos nuevos que Git aún no conoce
- `ahead of 'origin/master' by N commits` — tienes N commits locales que no se han subido

---

### `git remote -v`

```bash
git remote -v
```

**Qué hace**: Muestra las URLs remotas configuradas (fetch y push). Te dice a dónde apunta tu repo cuando haces push o pull.

**Cuándo usarlo**: Para verificar que estás conectado al repositorio correcto en GitHub.

**Ejemplo de salida**:
```
origin  https://github.com/angelcruzg23/sap-mcp-bzd.git (fetch)
origin  https://github.com/angelcruzg23/sap-mcp-bzd.git (push)
```

---

### `git log --oneline -N`

```bash
git log --oneline -3
```

**Qué hace**: Muestra los últimos N commits en formato compacto (una línea por commit).

**Cuándo usarlo**: Para ver el historial reciente y entender qué se ha commiteado.

**Ejemplo de salida**:
```
a4dcf1d (HEAD -> master) docs: lecciones aprendidas del workshop
4aee9d0 (origin/master) feat: AudioTranscriber
c59cdd5 Initial commit: SAP MCP Server
```

**Interpretación**:
- `HEAD -> master` — donde estás tú localmente
- `origin/master` — donde está GitHub
- Si HEAD está adelante de origin → tienes commits sin pushear

---

## 2. Preparar cambios — Staging (git add)

### `git add <archivos>`

```bash
git add server.py sap_client.py
```

**Qué hace**: Mueve archivos al "staging area" — los marca como listos para el próximo commit. Git no commitea automáticamente todo lo que cambió; tú decides qué incluir.

**Cuándo usarlo**: Después de modificar archivos y antes de hacer commit.

**Variantes**:

| Comando | Qué hace |
|---------|----------|
| `git add archivo.py` | Agrega un archivo específico |
| `git add server.py sap_client.py` | Agrega varios archivos |
| `git add SAP/` | Agrega toda una carpeta (recursivo) |
| `git add -u carpeta/` | Agrega solo archivos ya trackeados que fueron modificados o eliminados en esa carpeta |
| `git add .` | Agrega TODO (nuevos + modificados + eliminados) — usar con precaución |

**Importante**: `git add -u` solo afecta archivos que Git ya conoce (no agrega untracked). Es útil para registrar deletes masivos.

---

## 3. Guardar cambios — Commit

### `git commit -m "mensaje"`

```bash
git commit -m "feat: soporte multi-sistema MCP (BZD + BZN sandbox)"
```

**Qué hace**: Crea un snapshot permanente de los archivos que están en staging. El mensaje describe qué cambió y por qué.

**Cuándo usarlo**: Después de `git add`, cuando tienes un conjunto lógico de cambios listos.

**Convención de mensajes** (Conventional Commits):

| Prefijo | Uso |
|---------|-----|
| `feat:` | Nueva funcionalidad |
| `fix:` | Corrección de bug |
| `docs:` | Cambios en documentación |
| `refactor:` | Reorganización de código sin cambiar funcionalidad |
| `chore:` | Tareas de mantenimiento (dependencias, configs) |
| `test:` | Agregar o modificar tests |

**Ejemplos reales de la sesión**:
```bash
git commit -m "refactor: reorganizar proyectos ABAP y docs dentro de carpeta SAP/"
git commit -m "feat: soporte multi-sistema MCP (BZD + BZN sandbox)"
git commit -m "docs: actualizar README con soporte multi-sistema (BZD + BZN)"
```

**Buena práctica**: Un commit = un cambio lógico. No mezclar reorganización de carpetas con cambios de código en el mismo commit.

---

## 4. Subir cambios — Push

### `git push`

```bash
git push
```

**Qué hace**: Sube tus commits locales al repositorio remoto (GitHub).

**Cuándo usarlo**: Cuando quieres que tus cambios estén disponibles en GitHub.

### `git push -u origin <rama>`

```bash
git push -u origin master
```

**Qué hace**: Igual que `git push`, pero además configura el tracking entre tu rama local y la remota. Después de esto, solo necesitas `git push` (sin argumentos).

**Cuándo usarlo**: La primera vez que pusheas una rama nueva, o cuando quieres re-establecer el tracking.

**El flag `-u`** (o `--set-upstream`): Le dice a Git "de ahora en adelante, cuando haga push/pull en esta rama, usa `origin/master` como referencia".

---

## 5. Flujo completo — Ejemplo real

Este es el flujo exacto que seguimos para subir los cambios del MCP multi-sistema:

```bash
# 1. Ver qué cambió
git status

# 2. Ver a dónde apunta el remote y el historial
git remote -v
git log --oneline -3

# 3. Staging: agregar la reorganización de carpetas
git add SAP/                          # Carpeta nueva con todos los archivos
git add -u ATP_JuanDa/ MD/ ...       # Registrar los deletes de las rutas viejas

# 4. Primer commit: reorganización
git commit -m "refactor: reorganizar proyectos ABAP y docs dentro de carpeta SAP/"

# 5. Staging: agregar cambios del servidor MCP
git add server.py sap_client.py

# 6. Segundo commit: nueva funcionalidad
git commit -m "feat: soporte multi-sistema MCP (BZD + BZN sandbox)"

# 7. Verificar que no queda nada pendiente
git status

# 8. Subir todo a GitHub
git push -u origin master
```

---

## 6. Comandos adicionales útiles (no usados en esta sesión pero importantes)

### `git pull`

```bash
git pull
```

**Qué hace**: Descarga cambios del remoto y los integra con tu rama local.

**Cuándo usarlo**: Antes de empezar a trabajar, para asegurarte de tener la última versión.

### `git diff`

```bash
git diff                    # Cambios no staged
git diff --staged           # Cambios ya en staging (listos para commit)
git diff HEAD~1             # Diferencia con el commit anterior
```

**Qué hace**: Muestra las diferencias línea por línea entre versiones.

**Cuándo usarlo**: Para revisar exactamente qué cambió antes de hacer commit.

### `git checkout -b <rama>`

```bash
git checkout -b feature/nueva-funcionalidad
```

**Qué hace**: Crea una rama nueva y se mueve a ella.

**Cuándo usarlo**: Cuando vas a trabajar en algo nuevo y no quieres afectar master directamente.

### `git stash`

```bash
git stash           # Guarda cambios temporalmente
git stash pop       # Recupera los cambios guardados
```

**Qué hace**: Guarda tus cambios sin hacer commit, dejando el directorio limpio.

**Cuándo usarlo**: Cuando necesitas cambiar de rama pero tienes cambios sin commitear.

### `git reset HEAD <archivo>`

```bash
git reset HEAD server.py
```

**Qué hace**: Saca un archivo del staging area (deshace el `git add`).

**Cuándo usarlo**: Cuando agregaste un archivo por error al staging.

---

## 7. Glosario rápido

| Término | Significado |
|---------|-------------|
| **Working directory** | Tu carpeta de trabajo — los archivos como están en disco |
| **Staging area** | Zona intermedia donde preparas lo que va al próximo commit |
| **Commit** | Snapshot permanente de tus cambios con un mensaje descriptivo |
| **Branch (rama)** | Línea independiente de desarrollo |
| **Remote (origin)** | El repositorio en GitHub (o donde esté alojado) |
| **Push** | Subir commits locales al remote |
| **Pull** | Descargar commits del remote a local |
| **HEAD** | Puntero al commit actual donde estás parado |
| **Tracking** | Relación entre una rama local y su contraparte remota |
| **Untracked** | Archivo nuevo que Git aún no conoce |
| **Staged** | Archivo marcado para incluir en el próximo commit |

---

## 8. Diagrama del flujo Git

```
  Editar archivos
        │
        ▼
   git status          ← ¿Qué cambió?
        │
        ▼
   git add <files>     ← Preparar cambios (staging)
        │
        ▼
   git commit -m "..."  ← Guardar snapshot local
        │
        ▼
   git push             ← Subir a GitHub
```

---

*Documento generado a partir de la sesión de configuración MCP multi-sistema (BZD + BZN) — Mayo 2026*
