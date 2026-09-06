# Instalador de Logos para Claude - Windows
#
# Deja el catalogo, las notas, los sermones y los planes de lectura de Logos
# conectados a Claude Code. Se puede correr varias veces: lo hecho se salta.
#
# En Windows NO estan disponibles las herramientas que leen el texto de los
# paneles ni las capturas de pantalla (usan APIs de macOS). Todo lo demas si.
#
#   .\install.ps1
#   .\install.ps1 -Biblia RVR60 -ClaveBiblia XXXX

param(
  [string]$Biblia = "RVR60",
  [string]$ClaveBiblia = $env:BIBLIA_API_KEY
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$RepoDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Destino  = Join-Path $env:USERPROFILE "logos-para-claude"
$Servidor = Join-Path $Destino "logos-mcp-server"
$LocalNode = Join-Path $env:USERPROFILE ".local\node"

function Bold($m) { Write-Host $m -ForegroundColor White }
function Ok($m)   { Write-Host "  OK " -ForegroundColor Green -NoNewline; Write-Host $m }
function Info($m) { Write-Host "   . $m" -ForegroundColor DarkGray }
function Warn($m) { Write-Host "   ! $m" -ForegroundColor Yellow }
function Paso($m) { Write-Host ""; Bold $m }
function Morir($m) { Write-Host ""; Write-Host "  X $m" -ForegroundColor Red; Write-Host ""; exit 1 }
function Tiene($cmd) { $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue) }

function Ruta-Extendida {
  foreach ($d in @((Join-Path $LocalNode ""), (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"), "C:\Program Files\nodejs", (Join-Path $env:USERPROFILE ".local\bin"))) {
    if ((Test-Path $d) -and ($env:PATH -notlike "*$d*")) { $env:PATH = "$d;$env:PATH" }
  }
}
function Node-Sirve {
  if (-not (Tiene node)) { return $false }
  try { $v = [int](node -p 'process.versions.node.split(".")[0]'); return ($v -ge 20) } catch { return $false }
}
function Instalar-Node {
  Ruta-Extendida
  if (Node-Sirve) { return $true }
  if (Tiene winget) {
    try { winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null } catch {}
    Ruta-Extendida
    if (Node-Sirve) { return $true }
  }
  # ZIP oficial de nodejs.org, extraido en la carpeta del usuario.
  try {
    $lista = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json" -TimeoutSec 30
    $lts = $lista | Where-Object { $_.lts } | Select-Object -First 1
    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "x64" }
    $nombre = "node-$($lts.version)-win-$arch"
    $zip = Join-Path $env:TEMP "$nombre.zip"
    Invoke-WebRequest -Uri "https://nodejs.org/dist/$($lts.version)/$nombre.zip" -OutFile $zip -UseBasicParsing
    $tmp = Join-Path $env:TEMP "node-extraido"
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    if (Test-Path $LocalNode) { Remove-Item -Recurse -Force $LocalNode }
    New-Item -ItemType Directory -Force -Path (Split-Path $LocalNode) | Out-Null
    Move-Item (Join-Path $tmp $nombre) $LocalNode
    Remove-Item $zip -ErrorAction SilentlyContinue
    [Environment]::SetEnvironmentVariable("PATH", "$LocalNode;" + [Environment]::GetEnvironmentVariable("PATH", "User"), "User")
  } catch { return $false }
  Ruta-Extendida
  return (Node-Sirve)
}
function Instalar-Claude {
  Ruta-Extendida
  if (Tiene claude) { return $true }
  try { irm https://claude.ai/install.ps1 | iex | Out-Null } catch {}
  Ruta-Extendida
  return (Tiene claude)
}

Write-Host ""
Bold "=== Logos para Claude ==="
Write-Host ""
Info "Conecta tu biblioteca de Logos con Claude Code."
Info "En Windows: catalogo, notas, recortes, sermones y planes. La lectura de paneles es solo macOS."
Write-Host ""

Paso "1. Revisando lo que hace falta"
Ruta-Extendida
if (Node-Sirve) { Ok "Node.js $(node -v)" } else { Info "falta Node.js 20+" }
if (Tiene claude) { Ok "Claude Code" } else { Info "falta Claude Code" }
$logosDir = Join-Path $env:LOCALAPPDATA "Logos"
if (Test-Path $logosDir) { Ok "datos de Logos en $logosDir" } else { Warn "no encuentro los datos de Logos en $logosDir" }

Paso "2. Instalando lo que falta"
if (-not (Node-Sirve)) {
  Info "instalando Node.js..."
  if (Instalar-Node) { Ok "Node.js $(node -v)" } else { Morir "No pude instalar Node.js. Instalalo desde https://nodejs.org (LTS) y vuelve a correr este instalador." }
}
if (-not (Tiene claude)) {
  Info "instalando Claude Code..."
  if (Instalar-Claude) { Ok "Claude Code" } else { Warn "no pude instalar Claude Code; instalalo con: irm https://claude.ai/install.ps1 | iex" }
}

Paso "3. Copiando el servidor"
New-Item -ItemType Directory -Force -Path $Destino | Out-Null
if ($RepoDir -ne $Destino) {
  if (Test-Path $Servidor) { Remove-Item -Recurse -Force $Servidor }
  Copy-Item -Recurse (Join-Path $RepoDir "logos-mcp-server") $Servidor
  foreach ($f in @("LICENSE","desinstalar.ps1")) { $src = Join-Path $RepoDir $f; if (Test-Path $src) { Copy-Item $src $Destino -Force } }
}
Ok "en $Destino"

Paso "4. Preparando el servidor"
Info "la primera vez baja dependencias y compila; toma uno o dos minutos"
Push-Location $Servidor
try {
  npm install --no-audit --no-fund --loglevel=error 2>&1 | Where-Object { $_ -notmatch "allow-scripts" } | Select-Object -Last 3
  node -e 'require("better-sqlite3")' 2>$null
  if ($LASTEXITCODE -ne 0) { Info "preparando el motor SQLite..."; npm rebuild better-sqlite3 --loglevel=error 2>&1 | Out-Null }
  node -e 'require("better-sqlite3")' 2>$null
  if ($LASTEXITCODE -ne 0) { Morir "El motor SQLite no quedo listo. Revisa que tengas internet y vuelve a correr el instalador." }
  npm run build --loglevel=error 2>&1 | Select-Object -Last 2
  if (-not (Test-Path (Join-Path $Servidor "dist\index.js"))) { Morir "La compilacion no produjo dist\index.js." }
  Ok "compilado"
} finally { Pop-Location }

Paso "5. Conectando con Claude Code"
$nodeBin = (Get-Command node).Source
$entry = Join-Path $Servidor "dist\index.js"
$mcpOk = $false
if (Tiene claude) {
  try { claude mcp remove logos --scope user 2>&1 | Out-Null } catch {}
  $args = @("mcp","add","logos","--scope","user","--env","LOGOS_DEFAULT_BIBLE=$Biblia")
  if ($ClaveBiblia) { $args += @("--env","BIBLIA_API_KEY=$ClaveBiblia") }
  $args += @("--", $nodeBin, $entry)
  try { & claude @args 2>&1 | Out-Null; $mcpOk = $true; Ok "servidor 'logos' registrado en Claude Code (Biblia por defecto: $Biblia)" }
  catch { Warn "no pude registrarlo. Hazlo con: claude mcp add logos --scope user --env LOGOS_DEFAULT_BIBLE=$Biblia -- `"$nodeBin`" `"$entry`"" }
} else { Warn "Claude Code no esta instalado; cuando lo instales, vuelve a correr este instalador" }
if (-not $ClaveBiblia) {
  Info "sin clave de Biblia API: las herramientas de texto biblico por internet quedan apagadas; lo de Logos funciona igual"
  Info "para activarlas: entra con tu cuenta de Faithlife (la de Logos) en https://api.biblia.com/v1/Users/SignIn, crea una clave"
  Info "(direccion web: localhost) y vuelve a correr este instalador con:  .\install.ps1 -ClaveBiblia TU_CLAVE"
}

$cfg = Join-Path $env:APPDATA "Claude\claude_desktop_config.json"
if (Test-Path (Split-Path $cfg)) {
  Paso "6. Claude Desktop"
  if (-not (Test-Path $cfg)) { "{}" | Set-Content -Encoding UTF8 $cfg }
  $env:NODE_BIN = $nodeBin; $env:ENTRY = $entry; $env:BIBLIA = $Biblia; $env:CLAVE = $ClaveBiblia
  node -e 'const fs=require("fs");const p=process.argv[1];let c={};try{c=JSON.parse(fs.readFileSync(p,"utf8")||"{}")}catch{};c.mcpServers=c.mcpServers||{};const env={LOGOS_DEFAULT_BIBLE:process.env.BIBLIA};if(process.env.CLAVE)env.BIBLIA_API_KEY=process.env.CLAVE;c.mcpServers.logos={command:process.env.NODE_BIN,args:[process.env.ENTRY],env};fs.writeFileSync(p,JSON.stringify(c,null,2)+"\n");' $cfg
  if ($LASTEXITCODE -eq 0) { Ok "agregado a claude_desktop_config.json" } else { Warn "no pude editar la configuracion de Claude Desktop" }
}

Paso "7. Comprobando"
Push-Location $Servidor; node dist\cli.js 2>$null | Select-String "OK|MISSING|Status" | ForEach-Object { "    $_" }; Pop-Location

Write-Host ""
Bold "=== Listo ==="
if ($mcpOk) { Ok "Reinicia Claude Code y pidele, por ejemplo: busca comentarios en espanol sobre Romanos 8 en mi Logos" }
Write-Host ""
