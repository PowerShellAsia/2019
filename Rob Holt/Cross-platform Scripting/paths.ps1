# Path that works on UNIX, but not Windows
New-Item -Path '<file>*.txt'

# File names on Linux can even contain '\'
# For cross-compatibility:
#   - Avoid weird characters in file names
#   - Don't use the same name with different casing
#   - Just use Windows-compatible file names
#   - PowerShell always handles '/' and '\' the same,
#     but for .NET APIs, '/' always works when '\' could be in the filename

# This doesn't work in Windows PowerShell
Join-Path here there everywhere

# Can use this instead
[System.IO.Path]::Combine('here', 'there', 'everywhere')

# Sometimes convenient to define a wrapper
function Join-Path2
{
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]
        $Path
    )

    return [System.IO.Path]::Combine($Path)
}

# Splitting path variables

$env:PSModulePath -split ';'

$env:PSModulePath -split [System.IO.Path]::PathSeparator
$env:Path -split [System.IO.Path]::PathSeparator

# Making relative paths work nicely

function Test-PathFunction
{
    param(
        [Parameter()]
        [string]
        $Path
    )

    if ([System.IO.Path]::IsPathRooted($Path))
    {
        return $Path
    }

    return Join-Path (Get-Location) $Path
}

# BUT
Test-PathFunction -Path 'filesystem::/'

# Cmdlet.GetUnresolvedProvidePathFromPSPath() is a mouthful,
# but it's the most complete handling of raw paths
function Test-PathFunction2
{
    param(
        [Parameter()]
        [string]
        $Path
    )

    $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
}
