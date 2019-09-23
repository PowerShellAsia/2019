begin {
    $DebugPreference = "Continue"
    $ProgressPreference = "SilentlyContinue"
    $ErrorActionPreference = "Stop"
    Set-StrictMode -Version 2
    $script:common_functions = {
        Function ConvertFrom-AnsibleJson {
            param(
                [Parameter(Mandatory = $true, Position = 0)][String]$InputObject
            )
            $cmdlet = Get-Command -Name ConvertFrom-Json -CommandType Cmdlet
            if ("AsHashtable" -in $cmdlet.Parameters.Keys) {
                return , (ConvertFrom-Json -InputObject $InputObject -AsHashtable)
            }
            else {
                $raw_obj = ConvertFrom-Json -InputObject $InputObject
                Function ConvertTo-Hashtable {
                    param($InputObject)
                    if ($null -eq $InputObject) {
                        return $null
                    }
                    if ($InputObject -is [PSCustomObject]) {
                        $new_value = @{ }
                        foreach ($prop in $InputObject.PSObject.Properties.GetEnumerator()) {
                            $new_value.($prop.Name) = (ConvertTo-Hashtable -InputObject $prop.Value)
                        }
                        return , $new_value
                    }
                    elseif ($InputObject -is [Array]) {
                        $new_value = [System.Collections.ArrayList]@()
                        foreach ($val in $InputObject) {
                            $new_value.Add((ConvertTo-Hashtable -InputObject $val)) > $null
                        }
                        return , $new_value.ToArray()
                    }
                    else {
                        return , $InputObject
                    }
                }
                return , (ConvertTo-Hashtable -InputObject $raw_obj)
            }
        }
        Function Format-AnsibleException {
            param([System.Management.Automation.ErrorRecord]$ErrorRecord)
            $exception = @"
$($ErrorRecord.ToString())
$($ErrorRecord.InvocationInfo.PositionMessage)
    + CategoryInfo          : $($ErrorRecord.CategoryInfo.ToString())
    + FullyQualifiedErrorId : $($ErrorRecord.FullyQualifiedErrorId.ToString())
"@
            $exception += "`r`n`r`nScriptStackTrace:`r`n$($ErrorRecord.ScriptStackTrace)`r`n"
            if ($null -ne $ErrorRecord.Exception.StackTrace) {
                $exception += "`r`n$($ErrorRecord.Exception.ToString())"
            }
            return $exception
        }
    }
    .$common_functions
    $script:wrapper_functions = {
        Function Write-AnsibleError {
            param(
                [Parameter(Mandatory = $true)][String]$Message,
                [System.Management.Automation.ErrorRecord]$ErrorRecord = $null
            )
            $result = @{
                msg    = $Message
                failed = $true
            }
            if ($null -ne $ErrorRecord) {
                $result.msg += ": $($ErrorRecord.Exception.Message)"
                $result.exception = (Format-AnsibleException -ErrorRecord $ErrorRecord)
            }
            Write-Output -InputObject (ConvertTo-Json -InputObject $result -Depth 99 -Compress)
        }
        Function Write-AnsibleLog {
            param(
                [Parameter(Mandatory = $true, Position = 0)][String]$Message,
                [Parameter(Position = 1)][String]$Wrapper
            )
            $log_path = $env:ANSIBLE_EXEC_DEBUG
            if ($log_path) {
                $log_path = [System.Environment]::ExpandEnvironmentVariables($log_path)
                $parent_path = [System.IO.Path]::GetDirectoryName($log_path)
                if (Test-Path -LiteralPath $parent_path -PathType Container) {
                    $msg = "{0:u} - {1} - {2} - " -f (Get-Date), $pid, ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
                    if ($null -ne $Wrapper) {
                        $msg += "$Wrapper - "
                    }
                    $msg += $Message + "`r`n"
                    $msg_bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
                    $fs = [System.IO.File]::Open($log_path, [System.IO.FileMode]::Append,
                        [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
                    try {
                        $fs.Write($msg_bytes, 0, $msg_bytes.Length)
                    }
                    finally {
                        $fs.Close()
                    }
                }
            }
        }
    }
    .$wrapper_functions
    if (-not $(Get-Variable "json_raw" -ErrorAction SilentlyContinue)) {
        $json_raw = ''
    }
} process {
    $json_raw += [String]$input
} end {
    Write-AnsibleLog "INFO - starting exec_wrapper" "exec_wrapper"
    if (-not $json_raw) {
        Write-AnsibleError -Message "internal error: no input given to PowerShell exec wrapper"
        exit 1
    }
    Write-AnsibleLog "INFO - converting json raw to a payload" "exec_wrapper"
    $payload = ConvertFrom-AnsibleJson -InputObject $json_raw
    if ($payload.min_os_version) {
        $min_os_version = [Version]$payload.min_os_version
        $actual_os_version = [Version](Get-Item -Path $env:SystemRoot\System32\kernel32.dll).VersionInfo.ProductVersion
        Write-AnsibleLog "INFO - checking if actual os version '$actual_os_version' is less than the min os version '$min_os_version'" "exec_wrapper"
        if ($actual_os_version -lt $min_os_version) {
            Write-AnsibleError -Message "internal error: This module cannot run on this OS as it requires a minimum version of $min_os_version, actual was $actual_os_version"
            exit 1
        }
    }
    if ($payload.min_ps_version) {
        $min_ps_version = [Version]$payload.min_ps_version
        $actual_ps_version = $PSVersionTable.PSVersion
        Write-AnsibleLog "INFO - checking if actual PS version '$actual_ps_version' is less than the min PS version '$min_ps_version'" "exec_wrapper"
        if ($actual_ps_version -lt $min_ps_version) {
            Write-AnsibleError -Message "internal error: This module cannot run as it requires a minimum PowerShell version of $min_ps_version, actual was $actual_ps_version"
            exit 1
        }
    }
    $action = $payload.actions[0]
    Write-AnsibleLog "INFO - running action $action" "exec_wrapper"
    $entrypoint = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payload.($action)))
    $entrypoint = [ScriptBlock]::Create($entrypoint)
    $encoded_output = $payload.encoded_output
    try {
        $output = &$entrypoint -Payload $payload
        if ($encoded_output -and $null -ne $output) {
            $b64_output = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($output))
            Write-Output -InputObject $b64_output
        }
        else {
            $output
        }
    }
    catch {
        Write-AnsibleError -Message "internal error: failed to run exec_wrapper action $action" -ErrorRecord $_
        exit 1
    }
    Write-AnsibleLog "INFO - ending exec_wrapper" "exec_wrapper"
}