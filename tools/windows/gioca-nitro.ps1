# Nitro Underground on a Windows PC, without building an APK.
# Downloads Godot 4.7.2 (once) and the latest test version of the game from the "prova-pc" branch
# on GitHub (only when it changed), imports it and starts it. Everything goes in
# %LOCALAPPDATA%\NitroUnderground. Mouse clicks work as touches; keyboard: arrows/WASD, Space, Shift.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # Invoke-WebRequest is very slow with the progress bar on
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repo = "stefanopaglierani/nitro-underground"
$Branch = "prova-pc"
$GodotVersion = "4.7.2-stable"
$Base = Join-Path $env:LOCALAPPDATA "NitroUnderground"
$GodotDir = Join-Path $Base "godot"
$GameDir = Join-Path $Base "gioco"
$ShaFile = Join-Path $Base "versione.txt"
$GodotExe = Join-Path $GodotDir "Godot_v$($GodotVersion)_win64.exe"
$GodotConsole = Join-Path $GodotDir "Godot_v$($GodotVersion)_win64_console.exe"

function Step($text) { Write-Host ""; Write-Host ">> $text" -ForegroundColor Cyan }

New-Item -ItemType Directory -Force -Path $Base | Out-Null

# 1. Godot, once (about 85 MB).
if (-not (Test-Path $GodotExe)) {
    Step "Scarico Godot $GodotVersion (circa 85 MB, solo la prima volta)..."
    $zip = Join-Path $Base "godot.zip"
    Invoke-WebRequest "https://github.com/godotengine/godot/releases/download/$GodotVersion/Godot_v$($GodotVersion)_win64.exe.zip" -OutFile $zip
    Expand-Archive $zip -DestinationPath $GodotDir -Force
    Remove-Item $zip
}

# 2. The game, only when the branch has a new commit.
$latest = $null
try {
    $latest = (Invoke-RestMethod "https://api.github.com/repos/$Repo/commits/$Branch" -Headers @{ "User-Agent" = "NitroUnderground" }).sha
} catch {
    Write-Host "Non riesco a controllare se c'e' una versione nuova: uso quella che ho gia'." -ForegroundColor Yellow
}
$current = if (Test-Path $ShaFile) { (Get-Content $ShaFile -Raw).Trim() } else { "" }
if ($latest -and $latest -ne $current) {
    Step "Scarico la versione nuova del gioco (qualche centinaio di MB, ci vuole qualche minuto)..."
    $zip = Join-Path $Base "gioco.zip"
    Invoke-WebRequest "https://codeload.github.com/$Repo/zip/refs/heads/$Branch" -OutFile $zip
    Step "Estraggo i file..."
    $tmp = Join-Path $Base "tmp"
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Expand-Archive $zip -DestinationPath $tmp -Force
    Remove-Item $zip
    $src = Get-ChildItem $tmp -Directory | Select-Object -First 1
    # Keep the .godot import cache, so unchanged models are not imported again.
    if (Test-Path $GameDir) {
        Get-ChildItem $GameDir -Force | Where-Object { $_.Name -ne ".godot" } | Remove-Item -Recurse -Force
    } else {
        New-Item -ItemType Directory -Force -Path $GameDir | Out-Null
    }
    Get-ChildItem $src.FullName -Force | Move-Item -Destination $GameDir
    Remove-Item $tmp -Recurse -Force
    Step "Preparo modelli e texture (la prima volta 5-10 minuti, poi molto meno)..."
    & $GodotConsole --headless --path $GameDir --import
    Set-Content $ShaFile $latest
} elseif (-not (Test-Path $GameDir)) {
    throw "Il gioco non e' ancora stato scaricato e GitHub non risponde. Riprova tra poco."
}

# 3. Play.
Step "Avvio Nitro Underground..."
Start-Process $GodotExe -ArgumentList @("--path", "`"$GameDir`"") -WorkingDirectory $GameDir
