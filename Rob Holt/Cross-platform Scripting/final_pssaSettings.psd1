@{
    Rules = @{
        PSUseCompatibleSyntax = @{
            Enable = $true
            TargetVersions = @(
                '6.2',
                '5.1',
                '4.0'
            )
        }
        PSUseCompatibleCommands = @{
            Enable = $true
            TargetProfiles = @(
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework',
                'win-48_x64_10.0.17763.0_6.1.3_x64_4.0.30319.42000_core'
                'ubuntu_x64_18.04_6.1.3_x64_4.0.30319.42000_core'
                'win-8_x64_6.3.9600.0_4.0_x64_4.0.30319.42000_framework'
            )
            #IgnoreCommands = @('Get-CimInstance')
        }
        PSUseCompatibleTypes = @{
            Enable = $true
            TargetProfiles = @(
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework',
                'win-48_x64_10.0.17763.0_6.1.3_x64_4.0.30319.42000_core'
                'ubuntu_x64_18.04_6.1.3_x64_4.0.30319.42000_core'
                'win-8_x64_6.3.9600.0_4.0_x64_4.0.30319.42000_framework'
            )
            IgnoreTypes = @(
                'System.Management.Automation.Security.SystemPolicy'
            )
        }
    }
}