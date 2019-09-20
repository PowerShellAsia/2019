# Ensure that Azure modules are installed
if (-not (Get-Module Az -List))
{
    Install-Module Az -Scope CurrentUser
}

$resourceGroupName = 'psconfasia2019'
$location = 'centralindia'

$PSDefaultParameterValues = @{
    '*-Az*:ResourceGroupName' = $resourceGroupName
    '*-Az*:Location'          = $location
    '*-Az*:StorageLocation'   = $location
}

# Create a new resource group
$null = New-AzResourceGroup -Name $resourceGroupName

# Create a storage account and a new blob container
$sa = New-AzStorageAccount -Name ( -join (1..12 | % { [char](Get-Random -Min 97 -Max 122) })) -SkuName Standard_LRS
$sac = New-AzStorageContainer -Name telemetrypsconf -Context $sa.Context

# Create an ApplicationInsights resource
$ai = New-AzApplicationInsights -Name PSConfAsiaTelemetry

# Configure continuous export
$sastoken = $sac | New-AzStorageContainerSASToken -ExpiryTime (Get-Date).AddYears(50) -Permission w
$sasuri = $sa.PrimaryEndpoints.Blob + $sastoken
$null = New-AzApplicationInsightsContinuousExport -Name PSConfAsiaTelemetry -DocumentType 'Custom Event', 'Trace', 'Metric' -StorageAccountId $sa.Id -StorageSASUri $sasuri

# Create an Azure SQL resource
$sqlAdmin = [pscredential]::new('TheTelemetrier', ('P@$$w0rds are deprecated.' | ConvertTo-SecureString -AsPLaintext -Force))
$sql = New-AzSqlServer -ServerName psconfasiaql -SqlAdministratorCredentials $sqlAdmin -Location westeurope # India is not allowed to have SQL ;(
$ip = Get-PublicIpAddress
$null = New-AzSqlServerFirewallRule -ServerName $sql.ServerName -Start $ip -End $ip -FirewallRuleName TheClient
$null = New-AzSqlServerFirewallRule -AllowAllAzureIPs -ServerName $sql.ServerName

# Create a new database for your application
$db = New-AzSqlDatabase -DatabaseName app1telemetry -ServerName $sql.ServerName

<#
Create new tables, depending on the data you actually need

My telemetry contains e.g. the following custom event:
@{
    PSVersion = '1.2.3.4'
    OSType = 'Linux'
    ModuleVersion = '12.4.1'
}

My database table might look like this:
CREATE TABLE dbo.VersionEvent (PSVersion varchar(15) NOT NULL, OSType varchar(10) NOT NULL, ModuleVersion varchar(15) NOT NULL, Country nvarchar(255) NULL, City nvarchar(255) NULL);
#>
$createTable = 'CREATE TABLE dbo.VersionEvent (PSVersion varchar(15) NOT NULL, OSType varchar(10) NOT NULL, ModuleVersion varchar(15) NOT NULL, Country nvarchar(255) NULL, City nvarchar(255) NULL);'
$cString = "Server=tcp:$($sql.FullyQualifiedDomainName),1433;Initial Catalog=$($db.DatabaseName);Persist Security Info=False;User ID=$($sqlAdmin.UserName);Password=$($SqlAdmin.GetNetworkCredential().Password);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$sqlConnection = [System.Data.SQLClient.SQLConnection]::new($cString)
$sqlConnection.Open()
$sqlCommand = [System.Data.SQLClient.SQLCommand]::new($createTable)
$sqlCommand.Connection = $sqlConnection
$dbcreate = $sqlCommand.ExecuteNonQuery()

# Create and register a runbook to facilitate DB import
$aa = New-AzAutomationAccount -Name autotelemetry -Plan Basic
$aac = New-AzAutomationCredential -Name 'Database account' -Description 'Database account' -Value $sqlAdmin -AutomationAccountName autotelemetry
$aacacc = New-AzAutomation

# Create your runbook code, e.g.
$code = {
[CmdletBinding()]
param
(
    [bool]
    $OnPrem = $false,
    
    [bool]
    $SkipRemove = $false
)

if (-not $OnPrem)
{
    $connectionName = "AzureRunAsConnection"
    try
    {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

        Write-Verbose "Logging in to Azure..."
        $null = Add-AzureRmAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
    }
    catch
    {
        if (!$servicePrincipalConnection)
        {
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        }
        else
        {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }

    $Cred = Get-AutomationPSCredential -Name 'Database account'
}

$Path = $pwd.Path
$ctx = (Get-AzureRmStorageAccount -ResourceGroupName psconfasia2019 -Name %STORAGEACCOUNT% -ErrorAction SilentlyContinue).Context
$key = (Get-AzureRmStorageAccountKey -ResourceGroupName psconfasia2019 -Name %STORAGEACCOUNT%)[0].Value
$ci = invoke-restmethod -uri https://restcountries.eu/rest/v2/all -method get

if (-not $Cred) {$Cred = Get-Credential}

if ($null -eq $ctx -and $RemoveStorageBlob)
{
    Write-Error -Message 'Storage context cannot be empty if RemoveStorageBlob is selected.'
    return
}

$cString = "Server=tcp:psconfasiaql.database.windows.net,1433;Initial Catalog=app1telemetry;Persist Security Info=False;User ID=$($Cred.UserName);Password=$($Cred.GetNetworkCredential().Password);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $cstring

if (-not $Path.EndsWith('\')) { $Path = "$Path\" }
$Path = (Get-Item -Path $Path).FullName

$null = Get-AzureStorageBlob -Container telemetrypsconf -Context $ctx | Get-AzureStorageBlobContent -Destination $Path

$content = Get-ChildItem -Path $Path -Recurse -File -Filter *.blob | Foreach-Object {
    $blobname = ($_.FullName.Replace($Path, '') -replace '\\', '/')
    $_ | Get-Content -Encoding UTF8 | ConvertFrom-Json | Add-Member -Name BlobString -MemberType NoteProperty -Value $blobname -PassThru
} 

try
{
    $connection.Open()
    Write-Verbose 'Opened database connection'
}
catch
{
    Write-Error "Cannot continue if connection is not open. $($_.Exception.Message)"
    return
}

try
{
    foreach ($item in $content)
    {
        $creationTime = ([datetime]$item.context.data.eventTime).ToString('yyyy-MM-dd HH:mm:ss')

        # Your logic here
        switch ($item.Event.Name)
        {
            MyModuleImportEvent 
            { 
                $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
                
                # Some logic to determine the proper geo info
                # e.g. set City to the capital of a country if empty
                $country = $item.context.location.Country

                if ($null -eq $country) {break}
                $city = $item.context.location.City

                if ($null -eq $city)
                {
                    $city = @($ci | Where { $_.nativename -eq $country -or $_.name -eq $country}).capital
                }

                if ($null -eq $city)
                {
                    $city = ($ci | where name -like "$($country)*").capital
                }

                if ($null -eq $city)
                {
                    $city = ($ci | where altspellings -contains $country).capital
                }

                if ($null -eq $city)
                {
                    # this should not happen
                    $city = 'Atlantis'
                }


                $insert = @(
                    ($item.context.custom.dimensions | Where-Object { $_.PSObject.Properties.Name -eq 'psversion' }).psversion
                    ($item.context.custom.dimensions | Where-Object { $_.PSObject.Properties.Name -eq 'ostype' }).ostype
                    ($item.context.custom.dimensions | Where-Object { $_.PSObject.Properties.Name -eq 'moduleversion' }).moduleversion
                    $country
                    $city
                    $creationTime
                )

                $command.CommandText = ("INSERT INTO dbo.VersionEvent VALUES ('{0}', '{1}', '{2}', '{3}', '{4}', '{5}');" -f $insert) -replace "''", 'NULL'
                $command.Connection = $connection
                Write-Verbose $command.CommandText
                if (-not $SkipInsert) { $null = $command.ExecuteNonQuery() }
            }
        }

        if (-not $SkipRemove)
        {
            Write-Verbose "Removing $($item.BlobString)"
            Remove-AzureStorageBlob -Blob $item.BlobString -Context $ctx -Container 'telemetrypsconf' -ErrorAction SilentlyContinue
        }
    }
}
catch
{
    Write-Verbose "$($item.event.Name) - $($_.Exception.Message)"
}
finally
{
    $connection.Close()
    Write-Verbose 'Connection to DB closed'
}

}

($code.ToString() -replace '%STORAGEACCOUNT%', $sa.StorageAccountName)| Set-Content .\runbook.ps1

# Lastly, import the runbook
$rbi = Import-AzAutomationRunbook -Path .\runbook.ps1 -Description 'Import telemetry into database' -Name RunLolaRun -Type PowerShell -AutomationAccountName $aa.AutomationAccountName

# It still needs to be published, otherwise it will not be available in its current state
$register = Publish-AzAutomationRunbook -Name RunLolaRun -AutomationAccountName $aa.AutomationAccountName


# Configure (and deploy) your module
Invoke-PSMDTemplate -TemplateName PSFModule -Name PowerOfTelemetry -Parameters @{description = 'Sends telemetry'}

# The bootstrapped module is good as it is. We just need to add a little
@"

Set-PSFConfig -Module 'TelemetryHelper' -Name 'PowerOfTelemetry.ApplicationInsights.InstrumentationKey' -Value '$($ai.InstrumentationKey)' -Initialize -Validation 'bool' -Hidden
Set-PSFConfig -Module 'TelemetryHelper' -Name 'PowerOfTelemetry.OptIn' -Value `$false -Initialize -Validation 'bool'
Set-PSFConfig -Module 'TelemetryHelper' -Name 'PowerOfTelemetry.OptInVariable' -Value 'PowerOfTelemetryOptIn' -Initialize -Validation 'string' -Hidden
Set-PSFConfig -Module 'TelemetryHelper' -Name 'PowerOfTelemetry.RemovePII' -Value `$true -Initialize -Validation 'bool'
"@ | Add-Content -Path .\PowerOfTelemetry\internal\configurations\configuration.ps1


@'

# Send import telemetry
Send-THEvent -EventName MyModuleImportEvent -PropertiesHash @{
    psversion     = [string]$PSVersionTable.PSVersion
    ostype        = [Environment]::OSVersion.Platform
    moduleversion = [string](Get-Module -Name PowerOfTelemetry -List)[0].Version
} -DoNotFlush
'@ | Add-Content -Path .\PowerOfTelemetry\internal\scripts\preimport.ps1

$null = robocopy ".\PowerOfTelemetry" "$env:OneDriveConsumer\Documents\PowerShell\Modules\PowerOfTelemetry" /MIR
$null = robocopy ".\PowerOfTelemetry" "$env:OneDriveConsumer\Documents\WindowsPowerShell\Modules\PowerOfTelemetry" /MIR

# Opt-in to telemetry and import the module to get your first trace!
# Ideally, this is a user choice ;)
$env:PowerOfTelemetryOptIn = 'yes'
[Environment]::SetEnvironmentVariable('PowerOfTelemetryOptIn', 'yes')
Import-Module PowerOfTelemetry

# Verify what is going on
Get-THTelemetryConfiguration -ModuleName PowerOfTelemetry

# It takes a couple of seconds for the continuous export to run
# Once it's done, we can start the runbook
$job = Start-AzAutomationRunbook -Name RunLolaRun -AutomationAccountName $aa.AutomationAccountName

while ((Get-AzAutomationJob -Id $job.JobId -AutomationAccountName $aa.AutomationAccountName).Status -ne 'Completed')
{
    Start-Sleep -Seconds 1
}

$jobVerbose = Get-AzAutomationJobOutput -Id $job.JobId -AutomationAccountName $aa.AutomationAccountName -Stream Verbose | Get-AzAutomationJobOutputRecord
$jobVerbose.Value.Message

# And now...
start https://msit.powerbi.com
start https://flow.microsoft.com