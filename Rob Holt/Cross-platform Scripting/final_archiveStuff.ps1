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

#region Polyfill functions

function Test-IsLockedDown
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleTypes', '')]
    param()

    return ($IsWindows -ne $false) -and
        [System.Management.Automation.Security.SystemPolicy]::GetSystemLockdownPolicy() -ne 'None'
}

function Get-ComputerName
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCommands', '')]
    param()

    if ($IsWindows -ne $false)
    {
        return (Get-CimInstance -ClassName Win32_OperatingSystem).Name
    }

    return hostname
}

function Compress-CrossArchive
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCommands', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleTypes', '')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $LiteralPath,

        [Parameter()]
        [string]
        $DestinationPath,

        [switch]
        $Force
    )

    if ($PSVersionTable.PSVersion.Major -ge 5)
    {
        return Compress-Archive -LiteralPath $LiteralPath -DestinationPath $DestinationPath -Force:$Force
    }

    $LiteralPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($LiteralPath)
    $DestinationPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DestinationPath)

    if ($Force -and (Test-Path $DestinationPath))
    {
        Remove-Item -Force -LiteralPath $LiteralPath
    }

    Add-Type -AssemblyName "System.IO.Compression.Filesystem"
    [System.IO.Compression.ZipFile]::CreateFromDirectory($LiteralPath, $DestinationPath)
}

function Get-WildcardEscapedString
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleTypes', '')]
    param([string]$String)

    if ($PSVersionTable.PSVersion.Major -ge 5)
    {
        return [WildcardPattern]::Escape($String)
    }

    return $String
}

#endregion Polyfills

if (Test-IsLockedDown)
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
#Import-Module -FullyQualifiedName @{ ModuleName = 'ArchiveHelper'; ModuleVersion = '1.1' }
Import-Module -Name ArchiveHelper -Version '1.1'

# Get files to archive
$scriptFiles = Get-ScriptsToArchive -RootPath $ArchiveItemsFromDirPath

# Dictionary to collect hashes
$hashes = New-Object 'System.Collections.Generic.Dictionary[string,string]'
foreach ($scriptFile in $scriptFiles)
{
    # Copy the file to be archived over
    $path = Get-WildcardEscapedString -String $scriptFile.FullName
    Copy-Item -Path $path -Destination $archiveTempDir

    # Get the hash of the file and add it to the catalog
    $hash = (Get-FileHash -LiteralPath $path).Hash
    $hashes[$path] = $hash
}

# Add the hash catalog to the archive directory
$computerName = Get-ComputerName
$catalogPath = Join-Path $archiveTempDir "$computerName.json"
ConvertTo-Json $hashes | Out-File -LiteralPath $catalogPath -Force

# Zip up the directory and put it in the archive location
if (-not (Test-Path $ArchiveDestinationPath))
{
    $null = New-Item -ItemType Directory -Force -Path $ArchiveDestinationPath
}
$catalogHash = (Get-FileHash $catalogPath).Hash
$archivePath = Join-Path $ArchiveDestinationPath "$computerName-$catalogHash.zip"
Compress-CrossArchive -LiteralPath $archiveTempDir -DestinationPath $archivePath -Force

return $archivePath
