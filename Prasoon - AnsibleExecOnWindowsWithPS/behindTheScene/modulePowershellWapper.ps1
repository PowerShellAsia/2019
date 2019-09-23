param(
    [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Payload
)
$ErrorActionPreference = "Stop"
Write-AnsibleLog "INFO - starting module_powershell_wrapper" "module_powershell_wrapper"
$module_name = $Payload.module_args["_ansible_module_name"]
Write-AnsibleLog "INFO - building module payload for '$module_name'" "module_powershell_wrapper"
$csharp_utils = [System.Collections.ArrayList]@()
foreach ($csharp_util in $Payload.csharp_utils_module) {
    Write-AnsibleLog "INFO - adding $csharp_util to list of C# references to compile" "module_powershell_wrapper"
    $util_code = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Payload.csharp_utils[$csharp_util]))
    $csharp_utils.Add($util_code) > $null
}
if ($csharp_utils.Count -gt 0) {
    $add_type_b64 = $Payload.powershell_modules["Ansible.ModuleUtils.AddType"]
    $add_type = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($add_type_b64))
    New-Module -Name Ansible.ModuleUtils.AddType -ScriptBlock ([ScriptBlock]::Create($add_type)) | Import-Module > $null
    $new_tmp = [System.Environment]::ExpandEnvironmentVariables($Payload.module_args["_ansible_remote_tmp"])
    Add-CSharpType -References $csharp_utils -TempPath $new_tmp -IncludeDebugInfo
}
$variables = [System.Collections.ArrayList]@(@{ Name = "complex_args"; Value = $Payload.module_args; Scope = "Global" })
$module = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Payload.module_entry))
$entrypoint = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payload.module_wrapper))
$entrypoint = [ScriptBlock]::Create($entrypoint)
try {
    &$entrypoint -Scripts $script:common_functions, $module -Variables $variables `
        -Environment $Payload.environment -Modules $Payload.powershell_modules `
        -ModuleName $module_name
}
catch {
    $result = @{
        msg       = "Failed to invoke PowerShell module: $($_.Exception.Message)"
        failed    = $true
        exception = (Format-AnsibleException -ErrorRecord $_)
    }
    Write-Output -InputObject (ConvertTo-Json -InputObject $result -Depth 99 -Compress)
    $host.SetShouldExit(1)
}
Write-AnsibleLog "INFO - ending module_powershell_wrapper" "module_powershell_wrapper"