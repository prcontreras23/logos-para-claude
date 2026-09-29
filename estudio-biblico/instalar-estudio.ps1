# Metodo de estudio biblico para Claude - Windows
#
# Instala el skill "estudio-biblico", el agente "lector-fuentes-logos", un vault
# de Obsidian para los estudios y, si falta, la app de Obsidian. Lo llama
# install.ps1 al final, y tambien se puede correr solo:
#
#   .\instalar-estudio.ps1 [-Nombre "Juan Perez"] [-Tratamiento usted|tu] [-Vault RUTA]
#
# Se puede correr varias veces: nunca borra ni pisa lo que el estudiante ya
# escribio en el vault. (Sin acentos en este archivo a proposito: PowerShell 5
# lee los .ps1 sin BOM como ANSI.)

param(
  [string]$Nombre = "",
  [string]$Tratamiento = "",
  [string]$Vault = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Ok($m)   { Write-Host "  OK " -ForegroundColor Green -NoNewline; Write-Host $m }
function Info($m) { Write-Host "   . $m" -ForegroundColor DarkGray }
function Warn($m) { Write-Host "   ! $m" -ForegroundColor Yellow }

$Aqui = Split-Path -Parent $MyInvocation.MyCommand.Path
$iAcento = [char]0x00ED
if (-not $Vault) { $Vault = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Estudios b$($iAcento)blicos" }
$VaultNombre = Split-Path -Leaf $Vault
$SkillDir = Join-Path $env:USERPROFILE ".claude\skills\estudio-biblico"
$Agentes  = Join-Path $env:USERPROFILE ".claude\agents"
$Ajustes  = Join-Path $SkillDir "ajustes.json"
$Utf8 = New-Object System.Text.UTF8Encoding($false)

Write-Host ""
Write-Host "Metodo de estudio biblico" -ForegroundColor White

# Conservar los ajustes de una instalacion anterior.
if (Test-Path $Ajustes) {
  try {
    $prev = [IO.File]::ReadAllText($Ajustes, $Utf8) | ConvertFrom-Json
    if (-not $Nombre) { $Nombre = [string]$prev.nombre }
    if (-not $Tratamiento) { $Tratamiento = [string]$prev.tratamiento }
  } catch {}
}
if (-not $Nombre -and $env:ESTUDIO_PREGUNTAR -ne "0") {
  $Nombre = Read-Host "  Como se llama la persona que va a estudiar? (Enter para dejarlo en blanco)"
}
if (-not $Tratamiento) { $Tratamiento = "usted" }

# Skill y agente
New-Item -ItemType Directory -Force -Path $SkillDir, $Agentes | Out-Null
Copy-Item -Path (Join-Path $Aqui "skill\estudio-biblico\*") -Destination $SkillDir -Recurse -Force
Copy-Item -Path (Join-Path $Aqui "agentes\lector-fuentes-logos.md") -Destination $Agentes -Force
Ok "skill en $SkillDir"
Ok "agente lector-fuentes-logos en $Agentes"

# Vault: se copia solo lo que no existe
$Plantilla = Join-Path $Aqui "vault"
New-Item -ItemType Directory -Force -Path $Vault | Out-Null
Get-ChildItem -Path $Plantilla -Recurse -Force | ForEach-Object {
  $rel = $_.FullName.Substring($Plantilla.Length).TrimStart('\', '/')
  $dest = Join-Path $Vault $rel
  if ($_.PSIsContainer) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
  elseif (-not (Test-Path $dest)) { Copy-Item $_.FullName $dest }
}
Ok "vault $VaultNombre en $Vault"

# Ajustes
$obj = [ordered]@{ nombre = $Nombre; tratamiento = $Tratamiento; vault_ruta = $Vault; vault_nombre = $VaultNombre; notebooklm = @{} }
[IO.File]::WriteAllText($Ajustes, ($obj | ConvertTo-Json -Depth 3), $Utf8)
Ok "ajustes guardados"

# Obsidian
$obsExe = Join-Path $env:LOCALAPPDATA "Programs\Obsidian\Obsidian.exe"
$tieneObs = (Test-Path $obsExe) -or (Test-Path "C:\Program Files\Obsidian\Obsidian.exe")
if ($tieneObs) {
  Ok "Obsidian ya esta instalado"
} else {
  Info "instalando Obsidian..."
  $listo = $false
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    try { winget install --id Obsidian.Obsidian -e --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null } catch {}
    $listo = (Test-Path $obsExe) -or (Test-Path "C:\Program Files\Obsidian\Obsidian.exe")
  }
  if (-not $listo) {
    try {
      $rels = Invoke-RestMethod -Uri "https://api.github.com/repos/obsidianmd/obsidian-releases/releases?per_page=15" -TimeoutSec 30
      $url = ($rels | ForEach-Object { $_.assets } | Where-Object { $_.name -match '^Obsidian-[0-9.]+\.exe$' } | Select-Object -First 1).browser_download_url
      $exe = Join-Path $env:TEMP "Obsidian-setup.exe"
      Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing
      Start-Process -FilePath $exe -ArgumentList "/S" -Wait
      $listo = Test-Path $obsExe
    } catch {}
  }
  if ($listo) { Ok "Obsidian instalado" } else { Warn "instala Obsidian desde https://obsidian.md y abre la carpeta $Vault como vault" }
}

# Registrar el vault (solo con Obsidian cerrado: si esta abierto, reescribe el archivo al salir)
$cfgObs = Join-Path $env:APPDATA "obsidian\obsidian.json"
if (Get-Process -Name Obsidian -ErrorAction SilentlyContinue) {
  Info "Obsidian esta abierto: usa 'Abrir carpeta como vault' y elige $Vault"
} else {
  try {
    New-Item -ItemType Directory -Force -Path (Split-Path $cfgObs) | Out-Null
    $cfg = if (Test-Path $cfgObs) { [IO.File]::ReadAllText($cfgObs, $Utf8) | ConvertFrom-Json } else { [pscustomobject]@{} }
    if (-not $cfg.PSObject.Properties["vaults"]) { $cfg | Add-Member -NotePropertyName vaults -NotePropertyValue ([pscustomobject]@{}) }
    $ya = $cfg.vaults.PSObject.Properties | Where-Object { $_.Value.path -eq $Vault }
    if (-not $ya) {
      $id = -join ((1..16) | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) })
      $ts = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
      $cfg.vaults | Add-Member -NotePropertyName $id -NotePropertyValue ([pscustomobject]@{ path = $Vault; ts = $ts; open = $true })
    }
    [IO.File]::WriteAllText($cfgObs, ($cfg | ConvertTo-Json -Depth 6 -Compress), $Utf8)
    Ok "vault registrado en Obsidian"
  } catch { Info "abre Obsidian y usa 'Abrir carpeta como vault' con $Vault" }
}

Write-Host ""
Info "Para estudiar: abre la app de Claude, pestana Code, elige la carpeta $VaultNombre y di: vamos a estudiar la Biblia."
Info "Para que Claude lea los comentarios, entra una vez a app.logos.com en el navegador de la app de Claude con tu cuenta de Logos"
Info "y activa ahi Settings > Accessibility > Enable limited view mode."
