#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$SourcePath = (Join-Path $PSScriptRoot "Builld Ideas\Spark - comet\spark-comet.build"),

    [string]$DestinationDirectory = (Join-Path $env:USERPROFILE "OneDrive\Documents\My Games\Path of Exile 2\BuildPlanner")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$source = (Resolve-Path -LiteralPath $SourcePath).ProviderPath
if ([System.IO.Path]::GetExtension($source) -ne ".build") {
    throw "Source must be a .build file: $source"
}

$destinationDirectoryPath = [System.IO.Path]::GetFullPath($DestinationDirectory)
$destination = Join-Path $destinationDirectoryPath ([System.IO.Path]::GetFileName($source))
if ([string]::Equals($source, $destination, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Source and destination must be different files."
}

[System.IO.Directory]::CreateDirectory($destinationDirectoryPath) | Out-Null
$temporaryPath = Join-Path $destinationDirectoryPath (".build-sync-{0}.tmp" -f [guid]::NewGuid().ToString("N"))

try {
    [System.IO.File]::Copy($source, $temporaryPath, $false)
    $json = [System.IO.File]::ReadAllText($temporaryPath)
    if (-not $json.TrimStart().StartsWith("{")) {
        throw "Source must contain a JSON build object."
    }
    $build = $json | ConvertFrom-Json
    if ($null -eq $build -or $build -isnot [pscustomobject] -or
        $null -eq $build.PSObject.Properties["name"] -or
        $build.name -isnot [string] -or [string]::IsNullOrWhiteSpace($build.name)) {
        throw "Source must contain a JSON build object with a non-empty name."
    }

    $expectedHash = (Get-FileHash -LiteralPath $temporaryPath -Algorithm SHA256).Hash
    if (Test-Path -LiteralPath $destination -PathType Leaf) {
        if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -eq $expectedHash) {
            Write-Output "Already up to date: $destination"
            return
        }
        # Publish only the validated snapshot; the game never sees a partial build.
        [System.IO.File]::Replace($temporaryPath, $destination, [System.Management.Automation.Language.NullString]::Value)
    } else {
        [System.IO.File]::Move($temporaryPath, $destination)
    }

    if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $expectedHash) {
        throw "Build copy verification failed: $destination"
    }
    Write-Output "Synced build: $destination"
} finally {
    if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
        Remove-Item -LiteralPath $temporaryPath
    }
}
