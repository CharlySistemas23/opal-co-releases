param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [string]$InstallerPath,

    [string]$Notes = "",
    [switch]$Mandatory
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($repoRoot)) {
    $repoRoot = (Get-Location).Path
}

$artifactSource = (Resolve-Path $InstallerPath).Path
if (-not (Test-Path $artifactSource)) {
    throw "No se encontró el instalador: $InstallerPath"
}

$artifactName = [System.IO.Path]::GetFileName($artifactSource)
$targetDir = Join-Path $repoRoot "releases/windows"
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

$artifactTarget = Join-Path $targetDir $artifactName
Copy-Item -Path $artifactSource -Destination $artifactTarget -Force

$artifactHash = (Get-FileHash -Algorithm SHA256 -Path $artifactTarget).Hash.ToLower()
$artifactSize = (Get-Item $artifactTarget).Length
$publishedAt = (Get-Date).ToUniversalTime().ToString("o")

$downloadUrl = "https://raw.githubusercontent.com/CharlySistemas23/opal-co-releases/main/releases/windows/$artifactName"

$latest = [ordered]@{
    version = $Version
    channel = "stable"
    notes = $Notes
    publishedAt = $publishedAt
    mandatory = [bool]$Mandatory
    artifact = [ordered]@{
        name = $artifactName
        sha256 = $artifactHash
        size = $artifactSize
        downloadUrl = $downloadUrl
    }
}

$versionMeta = [ordered]@{
    version = $Version
    updatedAt = $publishedAt
}

$latestPath = Join-Path $repoRoot "latest.json"
$versionPath = Join-Path $repoRoot "version.json"

$latest | ConvertTo-Json -Depth 10 | Set-Content -Path $latestPath -Encoding UTF8
$versionMeta | ConvertTo-Json -Depth 10 | Set-Content -Path $versionPath -Encoding UTF8

Write-Host ""
Write-Host "Canal actualizado:" -ForegroundColor Green
Write-Host "  version:    $Version"
Write-Host "  artifact:   releases/windows/$artifactName"
Write-Host "  sha256:     $artifactHash"
Write-Host ""
Write-Host "Siguiente paso:" -ForegroundColor Yellow
Write-Host "  git add ."
Write-Host "  git commit -m \"release: v$Version\""
Write-Host "  git push"
