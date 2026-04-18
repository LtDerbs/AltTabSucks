#!/usr/bin/env pwsh
# Packages BrowserExtension/ into an .xpi for Firefox.
#
# UNSIGNED (default) — works in Firefox Developer Edition / ESR only:
#   about:config -> xpinstall.signatures.required = false
#   then: Firefox menu -> Add-ons -> gear -> Install Add-on From File
#
#   pwsh dev-scripts/package-firefox-extension.ps1
#
# SIGNED — works in any regular Firefox release:
#   Requires: npm install -g web-ext
#   Get API credentials at https://addons.mozilla.org/developers/addon/api/key/
#
#   pwsh dev-scripts/package-firefox-extension.ps1 -Sign
#   (credentials loaded from .amo-credentials, or prompted and saved on first run)

param(
    [switch]$Sign,
    [string]$Version = "",   # overrides auto-increment when signing (e.g. -Version 1.2.0)
    [string]$OutFile  = ""
)

$root    = Split-Path $PSScriptRoot -Parent
$src     = Join-Path $root "BrowserExtension"
$out     = if ($OutFile) { $OutFile } else { Join-Path $root "AltTabSucks-firefox.xpi" }
$exclude = @("logs", "manifest.json", "manifest-firefox.json")
$credsFile = Join-Path $root ".amo-credentials"

if ($Sign) {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "Node.js is required to sign the extension but was not found."
        $ans = (Read-Host "Install Node.js via winget now? (y/n)").Trim()
        if ($ans -ne 'y' -and $ans -ne 'Y') {
            Write-Host "Aborted. Install Node.js manually from https://nodejs.org and re-run."
            exit 1
        }
        winget install OpenJS.NodeJS.LTS
        if ($LASTEXITCODE -ne 0) {
            Write-Error "winget install failed. Install Node.js manually from https://nodejs.org and re-run."
            exit 1
        }
        # Refresh PATH so node and npm are available in this session
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("Path", "User")
    }

    if (-not (Get-Command web-ext -ErrorAction SilentlyContinue)) {
        Write-Host "Installing web-ext globally via npm..."
        npm install -g web-ext
        if ($LASTEXITCODE -ne 0) {
            Write-Error "npm install failed. Check your Node.js installation and re-run."
            exit 1
        }
    }

    # Load saved credentials
    $apiKey    = ""
    $apiSecret = ""
    if (Test-Path $credsFile) {
        foreach ($line in Get-Content $credsFile) {
            if ($line -match '^AMO_API_KEY=(.+)$')    { $apiKey    = $Matches[1].Trim() }
            if ($line -match '^AMO_API_SECRET=(.+)$') { $apiSecret = $Matches[1].Trim() }
        }
    }

    # Prompt for any missing credentials
    $save = $false
    if (-not $apiKey) {
        $apiKey = (Read-Host "AMO API key (e.g. user:12345:67)").Trim()
        $save   = $true
    }
    if (-not $apiSecret) {
        $apiSecret = (Read-Host "AMO API secret").Trim()
        $save      = $true
    }

    if (-not $apiKey -or -not $apiSecret) {
        Write-Error "API key and secret are required for signing."
        exit 1
    }

    if ($save) {
        $ans = (Read-Host "Save credentials to .amo-credentials for future runs? (y/n)").Trim()
        if ($ans -eq 'y' -or $ans -eq 'Y') {
            "AMO_API_KEY=$apiKey`nAMO_API_SECRET=$apiSecret" | Set-Content $credsFile -Encoding UTF8
            Write-Host "Saved to .amo-credentials (gitignored)."
        }
    }

    # Determine version to use — auto-increment patch if not specified
    $ffManifestPath = Join-Path $src "manifest-firefox.json"
    $ffManifest     = Get-Content $ffManifestPath -Raw | ConvertFrom-Json
    $currentVersion = $ffManifest.version
    if ($Version) {
        $nextVersion = $Version
    } else {
        $parts = $currentVersion -split '\.'
        $parts[2] = [int]$parts[2] + 1
        $nextVersion = $parts -join '.'
    }
    Write-Host "Version: $currentVersion -> $nextVersion"

    # Stage a temp dir with manifest-firefox.json as manifest.json — web-ext reads
    # source-dir directly so we can't use the Chrome manifest.json from the repo.
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "alttabsucks-ext-$([System.IO.Path]::GetRandomFileName())"
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        foreach ($file in Get-ChildItem $src -File -Recurse) {
            $rel = $file.FullName.Substring($src.Length + 1)
            if ($rel -eq "manifest.json" -or $rel -eq "manifest-firefox.json") { continue }
            $topLevel = $rel.Split('\')[0]
            if ($exclude -contains $topLevel) { continue }
            $dest = Join-Path $tmp $rel
            New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
            Copy-Item $file.FullName $dest
        }
        # Write temp manifest with bumped version
        $tmpManifest = Get-Content (Join-Path $src "manifest-firefox.json") -Raw | ConvertFrom-Json
        $tmpManifest.version = $nextVersion
        $tmpManifest | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $tmp "manifest.json") -Encoding UTF8

        $artifactsDir = Split-Path $out -Parent
        Write-Host "Signing extension via AMO (unlisted)..."
        web-ext sign --source-dir $tmp --channel unlisted --api-key $apiKey --api-secret $apiSecret --artifacts-dir $artifactsDir
        if ($LASTEXITCODE -eq 0) {
            # Rename output to readable filename
            $signed = Get-ChildItem $artifactsDir -Filter "*.xpi" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($signed -and $signed.FullName -ne $out) {
                Move-Item $signed.FullName $out -Force
            }
            # Write bumped version back to both manifests
            $ffManifest.version = $nextVersion
            $ffManifest | ConvertTo-Json -Depth 10 | Set-Content $ffManifestPath -Encoding UTF8
            $chromeManifestPath = Join-Path $src "manifest.json"
            $chromeManifest = Get-Content $chromeManifestPath -Raw | ConvertFrom-Json
            $chromeManifest.version = $nextVersion
            $chromeManifest | ConvertTo-Json -Depth 10 | Set-Content $chromeManifestPath -Encoding UTF8
            Write-Host "Manifests updated to version $nextVersion"
        }
    } finally {
        Remove-Item $tmp -Recurse -Force
    }
    Write-Host ""
    Write-Host "Signed .xpi: $out"
    Write-Host "Install via: Firefox menu -> Add-ons -> gear -> Install Add-on From File"
    exit 0
}

# Unsigned package
if (Test-Path $out) { Remove-Item $out }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($out, 'Create')
try {
    # Add manifest-firefox.json as manifest.json
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
        $zip, (Join-Path $src "manifest-firefox.json"), "manifest.json") | Out-Null

    foreach ($file in Get-ChildItem $src -File -Recurse) {
        $rel      = $file.FullName.Substring($src.Length + 1).Replace('\', '/')
        $topLevel = $rel.Split('/')[0]
        if ($exclude -contains $topLevel) { continue }
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $rel) | Out-Null
    }
} finally {
    $zip.Dispose()
}

Write-Host "Written: $out"
Write-Host ""
Write-Host "To install (Firefox Developer Edition / ESR only):"
Write-Host "  1. about:config -> xpinstall.signatures.required = false"
Write-Host "  2. Firefox menu -> Add-ons -> gear -> Install Add-on From File -> select .xpi"
Write-Host ""
Write-Host "For regular Firefox, sign it:"
Write-Host "  npm install -g web-ext"
Write-Host "  Get credentials: https://addons.mozilla.org/developers/addon/api/key/"
Write-Host "  pwsh dev-scripts/package-firefox-extension.ps1 -Sign"
