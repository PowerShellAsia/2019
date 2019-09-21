# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

Class WebListener
{
    [int]$HttpPort
    [int]$HttpsPort
    [int]$Tls11Port
    [int]$TlsPort
    [System.Management.Automation.Job]$Job

    WebListener () { }

    [String] GetStatus()
    {
        return $This.Job.JobStateInfo.State
    }
}

function New-RandomHexString
{
    param([int]$Length = 10)

    $random = [Random]::new()
    return ((1..$Length).ForEach{ '{0:x}' -f $random.Next(0xf) }) -join ''
}

[WebListener]$WebListener

function New-ClientCertificate
{
    param([string]$CertificatePath, [string]$Password)

    if ($Password)
    {
        $Passphrase = ConvertTo-SecureString -Force -AsPlainText $Password
    }

    $distinguishedName = @{
        CN = 'adatum.com'
        C = 'US'
        S = 'Washington'
        L = 'Redmond'
        O = 'A. Datum Corporation'
        OU = 'R&D'
        E = 'randd@adatum.com'
    }

    $certificateParameters = @{
        OutCertPath = $CertificatePath
        StartDate = [datetime]::Now.Subtract([timespan]::FromDays(30))
        Duration = [timespan]::FromDays(365)
        Passphrase = $Passphrase
        CertificateFormat = 'Pfx'
        KeyLength = 4096
        ForCertificateAuthority = $true
        Force = $true
    } + $distinguishedName

    SelfSignedCertificate\New-SelfSignedCertificate @certificateParameters
}

function New-ServerCertificate
{
    param([string]$CertificatePath, [string]$Password)

    if ($Password)
    {
        $Passphrase = ConvertTo-SecureString -Force -AsPlainText $Password
    }

    $distinguishedName = @{
        CN = 'localhost'
    }

    $certificateParameters = @{
        OutCertPath = $CertificatePath
        StartDate = [datetime]::Now.Subtract([timespan]::FromDays(30))
        Duration = [timespan]::FromDays(1000)
        Passphrase = $Passphrase
        KeyUsage = 'DigitalSignature','KeyEncipherment'
        EnhancedKeyUsage = 'ServerAuthentication','ClientAuthentication'
        CertificateFormat = 'Pfx'
        KeyLength = 2048
        Force = $true
    } + $distinguishedName

    SelfSignedCertificate\New-SelfSignedCertificate @certificateParameters
}

function Get-WebListener
{
    [CmdletBinding(ConfirmImpact = 'Low')]
    [OutputType([WebListener])]
    param()

    process
    {
        return [WebListener]$Script:WebListener
    }
}

function Start-WebListener
{
    [CmdletBinding(ConfirmImpact = 'Low')]
    [OutputType([WebListener])]
    param
    (
        [ValidateRange(1,65535)]
        [int]$HttpPort = 8083,

        [ValidateRange(1,65535)]
        [int]$HttpsPort = 8084,

        [ValidateRange(1,65535)]
        [int]$Tls11Port = 8085,

        [ValidateRange(1,65535)]
        [int]$TlsPort = 8086
    )

    process
    {
        $runningListener = Get-WebListener
        if ($null -ne $runningListener -and $runningListener.GetStatus() -eq 'Running')
        {
            return $runningListener
        }

        $initTimeoutSeconds  = 15
        $appExe              = (get-command WebListener).Path
        $serverPfx           = 'ServerCert.pfx'
        $serverPfxPassword   = New-RandomHexString
        $clientPfx           = 'ClientCert.pfx'
        $initCompleteMessage = 'Now listening on'
        $sleepMilliseconds   = 100

        $serverPfxPath = Join-Path ([System.IO.Path]::GetTempPath()) $serverPfx
        $Script:ClientPfxPath = Join-Path ([System.IO.Path]::GetTempPath()) $clientPfx
        $Script:ClientPfxPassword = New-RandomHexString
        New-ServerCertificate -CertificatePath $serverPfxPath -Password $serverPfxPassword
        New-ClientCertificate -CertificatePath $Script:ClientPfxPath -Password $Script:ClientPfxPassword

        $Job = Start-Job {
            $path = Split-Path -parent (get-command WebListener).Path -Verbose
            Push-Location $path -Verbose
            'appEXE: {0}' -f $using:appExe
            'serverPfxPath: {0}' -f $using:serverPfxPath
            'serverPfxPassword: {0}' -f $using:serverPfxPassword
            'HttpPort: {0}' -f $using:HttpPort
            'Https: {0}' -f $using:HttpsPort
            'Tls11Port: {0}' -f $using:Tls11Port
            'TlsPort: {0}' -f $using:TlsPort
            $env:ASPNETCORE_ENVIRONMENT = 'Development'
            & $using:appExe $using:serverPfxPath $using:serverPfxPassword $using:HttpPort $using:HttpsPort $using:Tls11Port $using:TlsPort
        }

        $Script:WebListener = [WebListener]@{
            HttpPort  = $HttpPort
            HttpsPort = $HttpsPort
            Tls11Port = $Tls11Port
            TlsPort   = $TlsPort
            Job   = $Job
        }

        # Count iterations of $sleepMilliseconds instead of using system time to work around possible CI VM sleep/delays
        $sleepCountRemaining = $initTimeoutSeconds * 1000 / $sleepMilliseconds
        do
        {
            Start-Sleep -Milliseconds $sleepMilliseconds
            $initStatus = $Job.ChildJobs[0].Output | Out-String
            $isRunning = $initStatus -match $initCompleteMessage
            $sleepCountRemaining--
        }
        while (-not $isRunning -and $sleepCountRemaining -gt 0)

        if (-not $isRunning)
        {
            $jobErrors = $Job.ChildJobs[0].Error | Out-String
            $jobOutput =  $Job.ChildJobs[0].Output | Out-String
            $jobVerbose =  $Job.ChildJobs[0].Verbose | Out-String
            $Job | Stop-Job
            $Job | Remove-Job -Force
            $message = 'WebListener did not start before the timeout was reached.{0}Errors:{0}{1}{0}Output:{0}{2}{0}Verbose:{0}{3}' -f ([System.Environment]::NewLine), $jobErrors, $jobOutput, $jobVerbose
            throw $message
        }
        return $Script:WebListener
    }
}

function Stop-WebListener
{
    [CmdletBinding(ConfirmImpact = 'Low')]
    [OutputType([Void])]
    param()

    process
    {
        $Script:WebListener.job | Stop-Job -PassThru | Remove-Job
        $Script:WebListener = $null
    }
}

function Get-WebListenerClientCertificate {
    [CmdletBinding(ConfirmImpact = 'Low')]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param()
    process {
        [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($Script:ClientPfxPath, $Script:ClientPfxPassword)
    }
}

function Get-WebListenerUrl {
    [CmdletBinding()]
    [OutputType([Uri])]
    param (
        [switch]$Https,

        [ValidateSet('Default', 'Tls12', 'Tls11', 'Tls')]
        [string]$SslProtocol = 'Default',

        [ValidateSet(
            'Auth',
            'Cert',
            'Compression',
            'Delay',
            'Delete',
            'Encoding',
            'Get',
            'Home',
            'Link',
            'Multipart',
            'Patch',
            'Post',
            'Put',
            'Redirect',
            'Response',
            'ResponseHeaders',
            'Resume',
            'Retry',
            '/'
        )]
        [String]$Test,

        [String]$TestValue,

        [System.Collections.IDictionary]$Query
    )
    process {
        $runningListener = Get-WebListener
        if ($null -eq $runningListener -or $runningListener.GetStatus() -ne 'Running')
        {
            return $null
        }
        $Uri = [System.UriBuilder]::new()
        # Use 127.0.0.1 and not localhost due to https://github.com/dotnet/corefx/issues/24104
        $Uri.Host = '127.0.0.1'
        $Uri.Port = $runningListener.HttpPort
        $Uri.Scheme = 'Http'

        if ($Https.IsPresent)
        {
            switch ($SslProtocol)
            {
                'Tls11' { $Uri.Port = $runningListener.Tls11Port }
                'Tls'   { $Uri.Port = $runningListener.TlsPort }
                # The base HTTPs port is configured for Tls12 only
                default { $Uri.Port = $runningListener.HttpsPort }
            }
            $Uri.Scheme = 'Https'
        }

        if ($TestValue)
        {
            $Uri.Path = '{0}/{1}' -f $Test, $TestValue
        }
        else
        {
            $Uri.Path = $Test
        }
        $StringBuilder = [System.Text.StringBuilder]::new()
        foreach ($key in $Query.Keys)
        {
            $null = $StringBuilder.Append([System.Net.WebUtility]::UrlEncode($key))
            $null = $StringBuilder.Append('=')
            $null = $StringBuilder.Append([System.Net.WebUtility]::UrlEncode($Query[$key].ToString()))
            $null = $StringBuilder.Append('&')
        }
        $Uri.Query = $StringBuilder.ToString()

        return [Uri]$Uri.ToString()
    }
}
