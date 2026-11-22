param([int]$Seed = 1977, [switch]$Export, [switch]$SoloStrade, [int]$Vegetazione = 0, [string]$Out = 'dati')
# -Out dati-v2: scrive in un'altra cartella, cosi' i dati vecchi restano come copia di sicurezza
$dir = $PSScriptRoot
$out = Join-Path (Split-Path $dir -Parent) $Out
New-Item -ItemType Directory -Force $out | Out-Null
Add-Type -Path "$dir\IsolaGen.cs" -ReferencedAssemblies System.Drawing
$sw = [Diagnostics.Stopwatch]::StartNew()
[IsolaGen]::BuildTerrain($Seed); "terreno: $($sw.Elapsed.TotalSeconds.ToString('F0')) s"
[IsolaGen]::Preview("$out\anteprima_terreno.png", 1024, $false)
[IsolaGen]::BuildRoads(); "strade: $($sw.Elapsed.TotalSeconds.ToString('F0')) s"
[IsolaGen]::ApplyRoads(4); "incisione: $($sw.Elapsed.TotalSeconds.ToString('F0')) s"
[IsolaGen]::Preview("$out\anteprima_strade.png", 1400, $true)
[IsolaGen]::Stats()
[IsolaGen]::Log.ToString()
if ($Export) {
    [IsolaGen]::WriteR16("$out\altezze_4097.r16")
    if (-not $SoloStrade) { "tessere terreno: " + [IsolaGen]::ExportTerrain("$out\terreno", 512.0, 2) }
    try { "strade: " + [IsolaGen]::ExportRoads("$out\strade") } catch { "ERRORE strade: " + $_.Exception.InnerException.ToString() }
    "export: $($sw.Elapsed.TotalSeconds.ToString('F0')) s"
}
if ($Vegetazione -gt 0) { "vegetazione: " + [IsolaGen]::Scatter((Join-Path $out "vegetazione.json"), $Vegetazione, 4242) }
