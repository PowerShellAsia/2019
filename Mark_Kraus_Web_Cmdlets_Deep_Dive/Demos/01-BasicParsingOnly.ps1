$DemoBlock = {
  $params = @{
    Uri = 'http://127.0.0.1:8083/'
  }
  $Result = Invoke-WebRequest @Params
  '-------------------------'
  'PowerShell {0}:' -f $PSVersionTable.PSVersion
  $Result.ParsedHtml
  '-------------------------'
}.ToString()
' '
' '
' '
pwsh.exe -command $DemoBlock
powershell.exe -command $DemoBlock