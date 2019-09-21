$DemoBlock = {
  add-type @'
using System.Net;
using System.Security.Cryptography.X509Certificates;
using System.Net.Security;
public class TrustAllCerts {
  public static bool ValidateServerCertificate(
    object sender,
    X509Certificate certificate,
    X509Chain chain,
    SslPolicyErrors sslPolicyErrors)
  {
    return true;
  }

  public static RemoteCertificateValidationCallback TrustAllCertsCallback = new RemoteCertificateValidationCallback(ValidateServerCertificate);
}
'@
  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [TrustAllCerts]::TrustAllCertsCallback

  '-------------------------'
  'PowerShell {0}:' -f $PSVersionTable.PSVersion
  Invoke-RestMethod -Uri 'https://127.0.0.1:8086/Get'
  '-------------------------'
}.ToString()
' '
' '
' '
pwsh.exe -command $DemoBlock
powershell.exe -command $DemoBlock