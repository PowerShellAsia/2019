$sb= [scriptblock]::Create((Invoke-WebRequest -Uri http://aka.ms/install-powershell.ps1).Content) 
& $sb -daily
