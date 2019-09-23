param(
    [Object[]]$Scripts,
    [System.Collections.ArrayList][AllowEmptyCollection()]$Variables,
    [System.Collections.IDictionary]$Environment,
    [System.Collections.IDictionary]$Modules,
    [String]$ModuleName
)
Write-AnsibleLog "INFO - creating new PowerShell pipeline for $ModuleName" "module_wrapper"
$ps = [PowerShell]::Create()
if ($ModuleName -ne "script") {
    $ps.Runspace.SessionStateProxy.SetVariable("ErrorActionPreference", "Stop")
}
if ($host.Name -eq "ConsoleHost") {
    Write-AnsibleLog "INFO - setting console input encoding to UTF8 for $ModuleName" "module_wrapper"
    $ps.AddScript('[Console]::InputEncoding = New-Object Text.UTF8Encoding $false').AddStatement() > $null
}
foreach ($variable in $Variables) {
    Write-AnsibleLog "INFO - setting variable '$($variable.Name)' for $ModuleName" "module_wrapper"
    $ps.AddCommand("Set-Variable").AddParameters($variable).AddStatement() > $null
}
if ($Environment) {
    foreach ($env_kv in $Environment.GetEnumerator()) {
        Write-AnsibleLog "INFO - setting environment '$($env_kv.Key)' for $ModuleName" "module_wrapper"
        $env_key = $env_kv.Key.Replace("'", "''")
        $env_value = $env_kv.Value.ToString().Replace("'", "''")
        $escaped_env_set = "[System.Environment]::SetEnvironmentVariable('$env_key', '$env_value')"
        $ps.AddScript($escaped_env_set).AddStatement() > $null
    }
}
if ($Modules) {
    foreach ($module in $Modules.GetEnumerator()) {
        Write-AnsibleLog "INFO - create module util '$($module.Key)' for $ModuleName" "module_wrapper"
        $module_name = $module.Key
        $module_code = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($module.Value))
        $ps.AddCommand("New-Module").AddParameters(@{Name = $module_name; ScriptBlock = [ScriptBlock]::Create($module_code) }) > $null
        $ps.AddCommand("Import-Module").AddParameter("WarningAction", "SilentlyContinue") > $null
        $ps.AddCommand("Out-Null").AddStatement() > $null
    }
}
$ps.AddScript('Function Write-Host($msg) { Write-Output -InputObject $msg }').AddStatement() > $null
foreach ($script in $Scripts) {
    $ps.AddScript($script).AddStatement() > $null
}
Write-AnsibleLog "INFO - start module exec with Invoke() - $ModuleName" "module_wrapper"
$orig_out = [System.Console]::Out
$sb = New-Object -TypeName System.Text.StringBuilder
$new_out = New-Object -TypeName System.IO.StringWriter -ArgumentList $sb
try {
    [System.Console]::SetOut($new_out)
    $module_output = $ps.Invoke()
}
catch {
    Write-AnsibleError -Message "Unhandled exception while executing module" `
        -ErrorRecord $_.Exception.InnerException.ErrorRecord
    $host.SetShouldExit(1)
    return
}
finally {
    [System.Console]::SetOut($orig_out)
    $new_out.Dispose()
}
if ($ps.InvocationStateInfo.State -eq "Failed" -and $ModuleName -ne "script") {
    Write-AnsibleError -Message "Unhandled exception while executing module" `
        -ErrorRecord $ps.InvocationStateInfo.Reason.ErrorRecord
    $host.SetShouldExit(1)
    return
}
Write-AnsibleLog "INFO - module exec ended $ModuleName" "module_wrapper"
$stdout = $sb.ToString()
if ($stdout) {
    Write-Output -InputObject $stdout
}
if ($module_output.Count -gt 0) {
    Write-AnsibleLog "INFO - using the output stream for module output - $ModuleName" "module_wrapper"
    Write-Output -InputObject ($module_output -join "`r`n")
}
$rc = $ps.Runspace.SessionStateProxy.GetVariable("LASTEXITCODE")
if ($null -ne $rc) {
    Write-AnsibleLog "INFO - got an rc of $rc from $ModuleName exec" "module_wrapper"
    $host.SetShouldExit($rc)
}
if ($ps.HadErrors -or ($PSVersionTable.PSVersion.Major -lt 4 -and $ps.Streams.Error.Count -gt 0)) {
    Write-AnsibleLog "WARN - module had errors, outputting error info $ModuleName" "module_wrapper"
    if ($null -eq $rc) {
        $host.SetShouldExit(1)
    }
    foreach ($err in $ps.Streams.Error) {
        $error_msg = Format-AnsibleException -ErrorRecord $err
        Write-AnsibleLog "WARN - error msg for for $($ModuleName):`r`n$error_msg" "module_wrapper"
        $host.UI.WriteErrorLine($error_msg)
    }
}