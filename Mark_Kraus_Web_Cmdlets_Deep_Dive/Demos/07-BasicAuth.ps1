$DemoBlock = {
  $User = 'Admin'
  $Password = 'hunter2'
  $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
  $Credential = [PSCredential]::new($User, $SecurePassword)

  $Params = @{
    Uri = 'http://127.0.0.1:8083/Auth/Basic'
    Authentication = 'Basic'
    Credential = $Credential
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
