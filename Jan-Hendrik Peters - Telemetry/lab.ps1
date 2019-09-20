if (-not (Get-Module -List AutomatedLab))
{
    Install-Module -Force -AllowClobber AutomatedLab
}

$labName = 'psconfasia19'
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

Add-LabMachineDefinition -Name mach1 -Roles FileServer -Memory 6gb -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)'

Install-Lab

Remove-Lab -Confirm:$false