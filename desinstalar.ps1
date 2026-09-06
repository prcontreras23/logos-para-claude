# Quita Logos para Claude de esta PC: el registro en Claude Code, la entrada en
# Claude Desktop y la carpeta del servidor. No toca Logos ni sus datos.

$Destino = Join-Path $env:USERPROFILE "logos-para-claude"
$cfg = Join-Path $env:APPDATA "Claude\claude_desktop_config.json"

function Ok($m)   { Write-Host "  OK " -ForegroundColor Green -NoNewline; Write-Host $m }
function Info($m) { Write-Host "   . $m" -ForegroundColor DarkGray }

Write-Host ""; Write-Host "Desinstalando Logos para Claude" -ForegroundColor White; Write-Host ""
if (Get-Command claude -ErrorAction SilentlyContinue) {
  try { claude mcp remove logos --scope user 2>&1 | Out-Null; Ok "quitado de Claude Code" } catch { Info "no estaba registrado en Claude Code" }
}
if ((Test-Path $cfg) -and (Get-Command node -ErrorAction SilentlyContinue)) {
  node -e 'const fs=require("fs");const p=process.argv[1];try{const c=JSON.parse(fs.readFileSync(p,"utf8"));if(c.mcpServers&&c.mcpServers.logos){delete c.mcpServers.logos;fs.writeFileSync(p,JSON.stringify(c,null,2)+"\n");process.exit(0)}}catch{};process.exit(1)' $cfg 2>$null
  if ($LASTEXITCODE -eq 0) { Ok "quitado de Claude Desktop" } else { Info "no estaba en Claude Desktop" }
}
foreach ($d in @($Destino, (Join-Path $env:USERPROFILE "logos-para-claude-fuente"))) {
  if (Test-Path $d) { Remove-Item -Recurse -Force $d; Ok "borrado $d" }
}
Write-Host ""
