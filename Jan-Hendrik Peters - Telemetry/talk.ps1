# Slides: https://aka.ms/PSConfTelemetry
break

$prep = {
    start 'https://msit.powerbi.com/groups/cc40ec7d-856a-4196-b20c-49030744d9c4/reports/3d753385-b049-45da-8962-a332ee144ebc/ReportSection'
    start 'https://ms.portal.azure.com/#@microsoft.onmicrosoft.com/resource/subscriptions/c011b157-620d-485a-808a-513bba1f4f21/resourceGroups/AutomatedLabTelemetry/providers/microsoft.insights/components/automatedlabinsight/overview'
    start ./Telemetry.pptx
    $null = Set-AzContext -Subscription AL4
    $PSDefaultParameterValues = @{
        '*:ResourceGroupName' = 'AutomatedLabTelemetry'
        '*AzSql*:Servername' = 'automatedlab'
        '*:AutomationAccountName' = 'telemetryautomation'
    }
}

. $prep

# Now that we saw the result of telemetry, let's see how we got there

# The first part of telemetry is the initialisation of the client itself
# For this purpose we use PSFramework (https://psframework.org)

# It is very convenient to control a compliant opt-in by using an environment variable that the user or IT department can control
Set-PSFConfig -Module TelemetryHelper -Name AutomatedLab.OptInVariable -Value AUTOMATEDLAB_TELEMETRY_OPTIN

# Application Insights sends information that we do not want, and that most security-minded people would not like to see
# getting sent uncontrollably, like the host name and other data. Should you want this information, simply set RemovePii to $false
Set-PSFConfig -Module TelemetryHelper -Name AutomatedLab.RemovePii -Value $true

# Lastly, to make any telemetry work, an instrumentation key is required
# This is available in your Application Insights resource
$aiKey = (Get-AzApplicationInsights -ResourceGroupName AutomatedLabTelemetry).InstrumentationKey
Set-PSFConfig -Module TelemetryHelper -Name AutomatedLab.ApplicationInsights.InstrumentationKey -Value $aiKey

# Apart from environmental variables, the user can opt-in manually using the following LoC
Set-PSFConfig -Module TelemetryHelper -Name AutomatedLab.OptIn -Value $true -PassThru | Register-PSFConfig


# After all that configuration, it is time to actually use the telemetry
Get-Command -Verb Send -Module TelemetryHelper

# With AutomatedLab we mainly send events that carry properties and often also metrics
# Take a look at our 'Lab Started' event for instance, while we set up another one in the background
powershell_ise.exe ./lab.ps1
$lab = Import-Lab -Name rakete -PassThru -NoValidation
$properties = @{
    "version"    = (Get-Module AutomatedLab).Version
    "hypervisor" = $lab.DefaultVirtualizationEngine
    "osversion"  = [environment]::OSVersion.Version
    "psversion"  = $PSVersionTable.PSVersion
}

$metrics = @{
    "machineCount" = $lab.Machines.Count
}

# The ModuleName property is optional. When called from within the module, it is auto-populated
Send-THEvent -EventName LabStarted -PropertiesHash $properties -MetricsHash $metrics -ModuleName AutomatedLab

# Metrics are normally collected over time to be analyzed. Like performance counters, a single metric might
# not make much sense, whereas a collection of multiple entries during a time window certainly does


# After the event has been sent, it will live in the Application Insights account for up to 90 days
# or up to 730 days for an additional charge. For AutomatedLab, we rather have our data in a SQL database
$cred = Get-Credential saruman
Set-AzSqlServerFirewallRule -FirewallRuleName jhp -StartIpAddress (Get-PublicIpAddress) -EndIpAddress (Get-PublicIpAddress)
Invoke-DbaSqlcmd -ServerInstance automatedlab.database.windows.net -Database telly `
                -Query "SELECT * FROM dbo.labInfo WHERE City='Markt Indersdorf'" -Credential $cred

Invoke-DbaSqlcmd -ServerInstance automatedlab.database.windows.net -Database telly `
                -Query "SELECT City FROM dbo.labInfo" -Credential $cred | Group-Object City | Sort Count -Descending | Select -First 10

# So, why is there nothing from Bengaluru?
Invoke-DbaSqlcmd -ServerInstance automatedlab.database.windows.net -Database telly `
                -Query "SELECT TOP 10 * FROM dbo.labInfo WHERE City='Bengaluru'" -Credential $cred

# Continuous Export within Application Insights only exports to a blob storage account
$ctx = (Get-AzStorageAccount -Name automatedlabtelemetry -ErrorAction SilentlyContinue).Context
$null = Get-AzStorageBlob -Container telemetry -Context $ctx | Get-AzStorageBlobContent -Destination .

# Let's have a look at the compressed JSON content
$labEvent = Get-ChildItem -Path .\automatedlabinsight_03367df3a45f4ba89163e73999e2c7b6 -Recurse -File |
    Sort-Object -Property PSParentPath -Descending | Select-Object -First 1 | Get-Content -Raw | ConvertFrom-Json

# This is mainly what we are after
$labEvent.context

# Properties can be found here
$labEvent.context.custom.dimensions | fl *

# And metrics here
$labEvent.context.custom.metrics

# In order to get this data into the database, we are using an Azure Automation runbook. You could also use other mechanisms - after all,
# these files are just JSON blobs
$job = Start-AzAutomationRunbook -Name ImportBlobContent

while ((Get-AzAutomationJob -Id $job.JobId).Status -ne 'Completed')
{
    Start-Sleep -Seconds 1
}

$jobVerbose = Get-AzAutomationJobOutput -Id $job.JobId -Stream Verbose | Get-AzAutomationJobOutputRecord
$jobVerbose.Value.Message

# With that done, we can do anything to the data
Invoke-DbaSqlcmd -ServerInstance automatedlab.database.windows.net -Database telly `
                -Query "SELECT TOP 10 * FROM dbo.labInfo WHERE City='Bengaluru'" -Credential $cred

# Power BI is just one of the tools for this job, it helps create convincing reports
start "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe" C:\Users\janhe\OneDrive\documents\ALInsightsAzSql.pbix

'Thank you for your attention, enjoy the rest of the conference!' | Out-Voice -Rate 2
