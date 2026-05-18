# ============================================================
#  DSA Files Installer
#  Usage: irm https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install.ps1 | iex
# ============================================================

$FolderID  = "1Jys6wp9pI5aHZqMf6bIH3BOycqSoojWA"
$OutputDir = "$env:USERPROFILE\DSA-Files"

# ── Colour helpers ────────────────────────────────────────────
function Write-Step ($msg) { Write-Host "  $msg"        -ForegroundColor Cyan    }
function Write-OK   ($msg) { Write-Host "  [OK] $msg"   -ForegroundColor Green   }
function Write-Warn ($msg) { Write-Host "  [!]  $msg"   -ForegroundColor Yellow  }
function Write-Fail ($msg) { Write-Host "  [X]  $msg"   -ForegroundColor Red     }

Clear-Host
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║        DSA Files Installer  v1.0         ║" -ForegroundColor Magenta
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# ── 1. Output folder ─────────────────────────────────────────
Write-Step "Creating download folder..."
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Write-OK "Folder ready → $OutputDir"

# ── 2. Python check / install ────────────────────────────────
Write-Step "Checking for Python..."
$python = $null
foreach ($cmd in @("python","python3","py")) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { $python = $cmd; break }
}

if (-not $python) {
    Write-Warn "Python not found — installing via winget..."
    winget install -e --id Python.Python.3 --silent `
        --accept-source-agreements --accept-package-agreements

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
    $python = "python"

    if (-not (Get-Command $python -ErrorAction SilentlyContinue)) {
        Write-Fail "Python install failed. Install manually from https://python.org then rerun."
        exit 1
    }
}
Write-OK "Python → $(& $python --version 2>&1)"

# ── 3. gdown install / upgrade ───────────────────────────────
Write-Step "Checking gdown..."
$check = & $python -m pip show gdown 2>&1
if ($LASTEXITCODE -ne 0 -or $check -match "not found") {
    Write-Step "Installing gdown..."
    & $python -m pip install gdown --quiet
} else {
    & $python -m pip install gdown --upgrade --quiet
}
Write-OK "gdown ready."

# ── 4. Download all files from Google Drive ──────────────────
Write-Host ""
Write-Host "  ──────────────────────────────────────────" -ForegroundColor DarkGray
Write-Step "Downloading files from Google Drive..."
Write-Host "  ──────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

& $python -m gdown `
    --folder "https://drive.google.com/drive/folders/1Jys6wp9pI5aHZqMf6bIH3BOycqSoojWA?usp=sharing" `
    --output  "$OutputDir" `
    --remaining-ok

$exitCode = $LASTEXITCODE

# ── 5. List downloaded files ─────────────────────────────────
Write-Host ""
Write-Host "  ──────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "   Downloaded Files" -ForegroundColor Green
Write-Host "  ──────────────────────────────────────────" -ForegroundColor DarkGray

$files = Get-ChildItem -Path $OutputDir -Recurse -File | Sort-Object Name

if ($files.Count -eq 0) {
    Write-Warn "No files found. Make sure the Drive folder is set to 'Anyone with the link'."
} else {
    $i = 1
    foreach ($f in $files) {
        $size = if ($f.Length -ge 1MB) { "{0:N2} MB" -f ($f.Length/1MB) }
                else                   { "{0:N2} KB" -f ($f.Length/1KB) }
        Write-Host ("   [{0:D2}]  {1,-44} {2,10}" -f $i, $f.Name, $size) -ForegroundColor White
        $i++
    }

    Write-Host ""
    Write-Host "  ──────────────────────────────────────────" -ForegroundColor DarkGray
    Write-OK "$($files.Count) file(s) saved to:"
    Write-Host "  📁 $OutputDir" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║          Installation Complete!          ║" -ForegroundColor Magenta
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Auto-open the folder
Start-Process explorer.exe $OutputDir
