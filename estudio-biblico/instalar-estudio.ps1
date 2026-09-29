# Estudio en Logos para Claude - Windows
#
# Instala el skill "estudio-logos" (buscar, leer y estudiar en Logos a la manera
# de cada persona), un vault de Obsidian para los estudios y, si falta, Obsidian. Lo llama
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
$SkillDir = Join-Path $env:USERPROFILE ".claude\skills\estudio-logos"
$Config   = Join-Path $SkillDir "configuracion.md"
$ViejoDir = Join-Path $env:USERPROFILE ".claude\skills\estudio-biblico"
$ViejoAgente = Join-Path $env:USERPROFILE ".claude\agents\lector-fuentes-logos.md"
$Utf8 = New-Object System.Text.UTF8Encoding($false)

Write-Host ""
Write-Host "Estudio en Logos" -ForegroundColor White

# Conservar nombre y trato: primero del configuracion.md actual, si no del
# ajustes.json del metodo anterior (estudio-biblico).
function Leer-Config($campo) {
  if (-not (Test-Path $Config)) { return "" }
  $m = [regex]::Match([IO.File]::ReadAllText($Config, $Utf8), "(?m)^- \*\*$campo\*\*: *([^<\r\n]*)")
  if ($m.Success) { return $m.Groups[1].Value.Trim() } else { return "" }
}
if (-not $Nombre) { $Nombre = Leer-Config "nombre" }
if (-not $Tratamiento) { $Tratamiento = Leer-Config "tratamiento" }
$AjustesViejos = Join-Path $ViejoDir "ajustes.json"
if (Test-Path $AjustesViejos) {
  try {
    $prev = [IO.File]::ReadAllText($AjustesViejos, $Utf8) | ConvertFrom-Json
    if (-not $Nombre) { $Nombre = [string]$prev.nombre }
    if (-not $Tratamiento) { $Tratamiento = [string]$prev.tratamiento }
  } catch {}
}
if (-not $Nombre -and $env:ESTUDIO_PREGUNTAR -ne "0") {
  $Nombre = Read-Host "  Como se llama la persona que va a estudiar? (Enter para dejarlo en blanco)"
}
if (-not $Tratamiento) { $Tratamiento = "usted" }

# Skill: se reemplazan sus archivos; configuracion.md es de la persona y no se toca.
New-Item -ItemType Directory -Force -Path $SkillDir | Out-Null
Get-ChildItem -Path $SkillDir -File | Where-Object { $_.Name -ne "configuracion.md" } | Remove-Item -Force
Copy-Item -Path (Join-Path $Aqui "skill\estudio-logos\*") -Destination $SkillDir -Recurse -Force
Ok "skill estudio-logos en $SkillDir"

# El metodo anterior lo instalaba este mismo paquete; se quita para que no
# compita con el nuevo. Los estudios del vault no se tocan.
if ((Test-Path $ViejoDir) -or (Test-Path $ViejoAgente)) {
  Remove-Item -Recurse -Force $ViejoDir, $ViejoAgente -ErrorAction SilentlyContinue
  Ok "quitado el metodo anterior (estudio-biblico); sus estudios siguen en el vault"
}

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

# Configuracion: solo si no existe
if (Test-Path $Config) {
  Ok "configuracion existente conservada"
} else {
  $txt = [IO.File]::ReadAllText((Join-Path $SkillDir "configuracion.ejemplo.md"), $Utf8)
  foreach ($par in @(@("nombre", $Nombre), @("tratamiento", $Tratamiento), @("guardar_en", $Vault))) {
    $valor = $par[1]
    $txt = [regex]::new("(?m)^(- \*\*$($par[0])\*\*:)[^<\r\n]*").Replace($txt, { param($m) $m.Groups[1].Value + " " + $valor + "    " }, 1)
  }
  [IO.File]::WriteAllText($Config, $txt, $Utf8)
  Ok "configuracion creada"
}

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
Info "Para estudiar: abre la app de Claude, pestana Code, elige la carpeta $VaultNombre y di: vamos a estudiar la Biblia. La primera vez, Claude le pregunta como estudia y lo deja anotado."
Info "Para que Claude lea los comentarios, entra una vez a app.logos.com en el navegador de la app de Claude con tu cuenta de Logos"
Info "y activa ahi Settings > Accessibility > Enable limited view mode."
