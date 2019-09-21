$DemoBlock = {
  $Body = @'
<HTML>
  <HEAD>
    <Title>Bad Request</Title>
  </HEAD>
  <BODY>
    <H1>Bad request. Please try again!<h1>
  </BODY>
</HTML>
'@
  $Body = [System.Net.WebUtility]::UrlEncode($Body)
  $Url = 'http://127.0.0.1:8083/Response/?statuscode=400&contenttype=text%2Fhtml&body={0}' -f $Body
  '-------------------------'
  'PowerShell {0}:' -f $PSVersionTable.PSVersion
  try {
    Invoke-RestMethod -Uri $Url -ErrorAction Stop
  } catch {
    $ErrorDetails = $_.ErrorDetails
    $Response = $_.Exception.Response
  }
  $Response.GetType().FullName
  '===== Server Property ====='
  $Response.Headers.Server
  '===== Server Index Key ====='
  $Response.Headers['Server']
  '===== Raw Response ====='
  try {
    $Stream = $Response.GetResponseStream()
    $Stream.Position = 0
    $Reader = [System.IO.StreamReader]::new($Stream)
    'From Stream:'
    $Reader.ReadToEnd()
  } catch {
    'From ErrorDetails'
    $ErrorDetails.Message
  }
  '-------------------------'
}.ToString()
' '
' '
' '
pwsh.exe -command $DemoBlock
powershell.exe -command $DemoBlock