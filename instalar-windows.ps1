# Arranque de una linea para Windows:
#
#   irm https://raw.githubusercontent.com/prcontreras23/logos-para-claude/main/instalar-windows.ps1 | iex
#
# Baja el proyecto y arranca el instalador, sin descargar el ZIP a mano.

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Repo   = "prcontreras23/logos-para-claude"
$Fuente = Join-Path $env:USERPROFILE "logos-para-claude-fuente"

function Bold($m) { Write-Host $m -ForegroundColor White }
function Gris($m) { Write-Host $m -ForegroundColor DarkGray }
function Morir($m) { Write-Host ""; Write-Host "  X $m" -ForegroundColor Red; Write-Host ""; exit 1 }

Write-Host ""
Bold "Bajando Logos para Claude..."
Write-Host ""

$zip = Join-Path $env:TEMP "logos-para-claude.zip"
try { Invoke-WebRequest -Uri "https://github.com/$Repo/archive/refs/heads/main.zip" -OutFile $zip -UseBasicParsing }
catch { Morir "No se pudo bajar. Revisa que tengas internet e intentalo otra vez." }

if (Test-Path $Fuente) { Remove-Item -Recurse -Force $Fuente -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $Fuente | Out-Null
try {
  $temp = Join-Path $env:TEMP "lpc-extraido"
  if (Test-Path $temp) { Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue }
  Expand-Archive -Path $zip -DestinationPath $temp -Force
  $interna = Get-ChildItem $temp -Directory | Select-Object -First 1
  Copy-Item -Path (Join-Path $interna.FullName "*") -Destination $Fuente -Recurse -Force
  Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
  Remove-Item $zip -ErrorAction SilentlyContinue
} catch { Morir "No se pudo descomprimir el archivo bajado." }

Write-Host "  OK " -ForegroundColor Green -NoNewline; Write-Host "listo"
Gris "  archivos en $Fuente"

$instalador = Join-Path $Fuente "install.ps1"
if (-not (Test-Path $instalador)) { Morir "El proyecto se bajo incompleto. Intentalo de nuevo." }

# -ExecutionPolicy Bypass vale solo para esta ejecucion; no cambia la maquina.
powershell -NoProfile -ExecutionPolicy Bypass -File $instalador
