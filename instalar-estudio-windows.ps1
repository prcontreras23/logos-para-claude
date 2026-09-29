# Solo el skill de estudio, para quien ya tiene Logos para Claude en Windows:
#
#   irm https://raw.githubusercontent.com/prcontreras23/logos-para-claude/main/instalar-estudio-windows.ps1 | iex
#
# Instala el skill "estudio-logos", el vault de Obsidian y, si falta, Obsidian.
# Si estaba el metodo anterior (estudio-biblico), lo quita. No toca el servidor
# de Logos.

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Repo    = "prcontreras23/logos-para-claude"
$Fuente  = Join-Path $env:USERPROFILE "logos-para-claude-fuente"
$Destino = Join-Path $env:USERPROFILE "logos-para-claude"

function Morir($m) { Write-Host ""; Write-Host "  X $m" -ForegroundColor Red; Write-Host ""; exit 1 }

Write-Host ""
Write-Host "Bajando el skill de estudio..." -ForegroundColor White
$zip = Join-Path $env:TEMP "logos-para-claude.zip"
try { Invoke-WebRequest -Uri "https://github.com/$Repo/archive/refs/heads/main.zip" -OutFile $zip -UseBasicParsing }
catch { Morir "No se pudo bajar. Revisa que tengas internet e intentalo otra vez." }

if (Test-Path $Fuente) { Remove-Item -Recurse -Force $Fuente -ErrorAction SilentlyContinue }
$temp = Join-Path $env:TEMP "lpc-extraido"
if (Test-Path $temp) { Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue }
Expand-Archive -Path $zip -DestinationPath $temp -Force
$interna = Get-ChildItem $temp -Directory | Select-Object -First 1
New-Item -ItemType Directory -Force -Path $Fuente, $Destino | Out-Null
Copy-Item -Path (Join-Path $interna.FullName "*") -Destination $Fuente -Recurse -Force
Remove-Item -Recurse -Force $temp, $zip -ErrorAction SilentlyContinue

$estudioDest = Join-Path $Destino "estudio-biblico"
if (Test-Path $estudioDest) { Remove-Item -Recurse -Force $estudioDest }
Copy-Item -Recurse (Join-Path $Fuente "estudio-biblico") $estudioDest

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $estudioDest "instalar-estudio.ps1")
Write-Host ""
Write-Host "  OK " -ForegroundColor Green -NoNewline; Write-Host "Listo. Cierra la app de Claude y vuelve a abrirla para que cargue el skill."
