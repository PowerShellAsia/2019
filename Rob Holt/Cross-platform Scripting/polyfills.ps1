function Get-ComputerName
{
    # Use attributes to suppress rules within polyfill functions
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCommands', '')]
    param()

    if ($IsWindows -ne $false)
    {
        return (Get-CimInstance -ClassName Win32_OperatingSystem).Name
    }

    return hostname
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
