$DemoBlock = {
  $Token = 'supercalifragilisticexpialidocious'
  $SecureToken = $Token | ConvertTo-SecureString -AsPlainText -Force

  $Params = @{
    Uri = 'http://127.0.0.1:8083/Get'
    Authentication = 'OAuth'
    Token = $SecureToken
  }

  '-------------------------'
  'PowerShell {0}:' -f $PSVersionTable.PSVersion
  '===== Secrets over HTTP ====='
  Invoke-RestMethod @Params
  ' '
  '===== AllowUnencryptedAuthentication ===='
  Invoke-RestMethod @Params -AllowUnencryptedAuthentication
  '-------------------------'
}.ToString()
' '
' '
' '
pwsh.exe -command $DemoBlock
