[CmdletBinding()]
param(
    # Path to directory where archive will be created
    [Parameter()]
    [string]
    $ArchiveDestinationPath = "$HOME\Downloads\Archive\",

    # Path to directory to pull items to archive from
    [Parameter()]
    [string]
    $ArchiveItemsFromDirPath = $PWD
)

$ErrorActionPreference = 'Stop'

if ([System.Management.Automation.Security.SystemPolicy]::GetSystemLockdownPolicy() -ne 'None')
{
    Write-Error 'System lockdown prevents running archive script'
    return
}

# Normalize paths
$ArchiveDestinationPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($ArchiveDestinationPath)
$ArchiveItemsFromDirPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($ArchiveItemsFromDirPath)

# Set up temp archive dir location
$archiveTempDir = Join-Path ([System.IO.Path]::GetTempPath()) "tmpArchiveDir"
$null = New-Item -ItemType Directory -Path $archiveTempDir -Force

# Import helper module to get folders to archive
Import-Module -FullyQualifiedName @{ ModuleName = 'ArchiveHelper'; ModuleVersion = '1.1' }

# Get files to archive
$scriptFiles = Get-ScriptsToArchive -RootPath $ArchiveItemsFromDirPath

# Dictionary to collect hashes
$hashes = New-Object 'System.Collections.Generic.Dictionary[string,string]'
foreach ($scriptFile in $scriptFiles)
{
    # Copy the file to be archived over
    $path = [WildcardPattern]::Escape($scriptFile.FullName)
    Copy-Item -Path $path -Destination $archiveTempDir

    # Get the hash of the file and add it to the catalog
    $hash = (Get-FileHash -LiteralPath $path).Hash
    $hashes[$path] = $hash
}

# Add the hash catalog to the archive directory
$computerName = (Get-WmiObject -Class Win32_ComputerSystem).Name
$catalogPath = Join-Path $archiveTempDir "$computerName.json"
ConvertTo-Json $hashes | Out-File -LiteralPath $catalogPath -NoNewline -Force

# Zip up the directory and put it in the archive location
if (-not (Test-Path $ArchiveDestinationPath))
{
    $null = New-Item -ItemType Directory -Force -Path $ArchiveDestinationPath
}
$catalogHash = (Get-FileHash $catalogPath).Hash
$archivePath = Join-Path $ArchiveDestinationPath "$computerName-$catalogHash.zip"
Compress-Archive -LiteralPath $archiveTempDir -DestinationPath $archivePath -Force

return $archivePath
