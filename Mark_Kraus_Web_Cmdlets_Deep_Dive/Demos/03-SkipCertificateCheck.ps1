$DemoBlock = {
  '-------------------------'
  'PowerShell {0}:' -f $PSVersionTable.PSVersion
  Invoke-RestMethod -Uri 'https://127.0.0.1:8086/Get' -SkipCertificateCheck
  '-------------------------'
}.ToString()
' '
' '
' '
pwsh.exe -command $DemoBlock
powershell.exe -command $DemoBlock