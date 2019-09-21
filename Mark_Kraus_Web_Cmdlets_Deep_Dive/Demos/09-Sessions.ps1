$DemoBlock = {
  $Uri = 'http://127.0.0.1:8083/Get'
  $Session = $null
  '-------------------------'
  'PowerShell {0}:' -f $PSVersionTable.PSVersion
  '===== Original Request ====='
  $Response = Invoke-RestMethod -Uri $Uri -SessionVariable Session
  $Response.Headers | Format-List
  '===== Session Contents ====='
  $Session
  # Add a header and a cookie
  $Session.Headers.Add('x-test-header','foo')
  $Cookie = [System.Net.Cookie]::new('x-test-cookie', 'bar')
  $Session.Cookies.Add([uri]$Uri, $Cookie)
  '===== Headers ====='
  $Session.Headers
  '===== Cookies ====='
  $Session.Cookies.GetCookies([uri]$Uri)
  '===== Request With New Header and Cookie ====='
  $Response = Invoke-RestMethod -Uri $Uri -WebSession $Session
  $Response.Headers | Format-List
  '-------------------------'
}.ToString()
' '
' '
' '
pwsh.exe -command $DemoBlock
