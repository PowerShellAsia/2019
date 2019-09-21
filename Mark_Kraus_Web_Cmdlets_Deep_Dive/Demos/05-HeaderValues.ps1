$DemoBlock = {
  '-------------------------'
  'PowerShell {0}:' -f $PSVersionTable.PSVersion
  $Uri = 'http://127.0.0.1:8083/ResponseHeaders?x-test-header=TestValue'
  $Response = Invoke-WebRequest -Uri $Uri
  '===== Type ====='
  $Response.Headers['x-test-header'].GetType().FullName
  '===== Index 0 ====='
  $Response.Headers['x-test-header'][0]
  '===== Select ====='
  $Response.Headers['x-test-header'] | Select-Object -First 1
  '===== ResponseHeadersVariable ====='
  $null = Invoke-RestMethod -Uri $Uri -ResponseHeadersVariable Headers
  $Headers
  '-------------------------'
}.ToString()
' '
' '
' '
pwsh.exe -command $DemoBlock
powershell.exe -command $DemoBlock