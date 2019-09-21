[CmdletBinding()]
param()

function prompt { 'PS> ' }

$WebListenerPath = Join-Path $PSScriptRoot 'WebListener'
$PublishPath = Join-Path $WebListenerPath 'Publish'
$PSModulesPath = Join-Path $WebListenerPath 'PSModules'
$DotnetCmd = Get-Command dotnet -CommandType Application | 
  Sort-Object Version -Descending |
  Select-Object -First 1

$WebListenerIsRunning = $Global:WebListener.Job.State -eq 'Running'

if ($IsLinux) {
    $Runtime = "linux-x64"
} elseif ($IsMacOS) {
    $Runtime = "osx-x64"
} else {
    $RID = & $DotnetCmd --info | ForEach-Object {
        if ($_ -match "RID") {
            $_ -split "\s+" | Select-Object -Last 1
        }
    }

    # We plan to release packages targetting win7-x64 and win7-x86 RIDs,
    # which supports all supported windows platforms.
    # So we, will change the RID to win7-<arch>
    $Runtime = $RID -replace "win\d+", "win7"
}


' '
' '
'---------------------------------------------------------'
'WebListenerPath:      {0}' -f $WebListenerPath
'PSModulesPath:        {0}' -f $PSModulesPath
'DotnetCmd:            {0}' -f $DotnetCmd.Path
'Runtime:              {0}' -f $Runtime
'PublishPath:          {0}' -f $PublishPath
'WebListenerIsRunning: {0}' -f $WebListenerIsRunning
'---------------------------------------------------------'
' '
' '

$PathParts = $env:Path -split ([System.IO.Path]::PathSeparator)
if($PublishPath -notin $PathParts) {
  'Appending Path with "{0}"' -f $PublishPath
  ' '
  $env:Path = '{0}{1}{2}' -f @(
    $env:Path,
    ([System.IO.Path]::PathSeparator),
    $PublishPath
  )
}

$PSModulePathParts = $env:PSModulePath -split ([System.IO.Path]::PathSeparator)
if($PSModulesPath -notin $PSModulePathParts) {
  'Appending PSModulePath with "{0}"' -f $PSModulesPath
  ' '
  $env:PSModulePath = '{0}{1}{2}' -f @(
    $env:PSModulePath,
    ([System.IO.Path]::PathSeparator),
    $PSModulesPath
  )
}


if(-not $WebListenerIsRunning){
  'Moving to "{0}"' -f $WebListenerPath
  Push-Location $WebListenerPath
  ' '

  'Running: dotnet restore'
  '---------------------------------------------------------'
  & $DotnetCmd restore
  '---------------------------------------------------------'
  ' '
  ' '

  'Running: dotnet publish --framework netcoreapp2.1 --configuration Release --runtime {0} --output {1}' -f $Runtime,$PublishPath
  '---------------------------------------------------------'
  & $DotnetCmd publish --framework netcoreapp2.1 --configuration Release --runtime $Runtime --output $PublishPath
  '---------------------------------------------------------'
  ' '
  ' '

  'Returning to "{0}"' -f (Pop-Location -PassThru)
  ' '

  'Importing WebListener module'
  Import-Module WebListener
  ' '

  'Starting WebListener'
  $Global:WebListener = Start-WebListener
  $Global:WebListener
  ' '
}
