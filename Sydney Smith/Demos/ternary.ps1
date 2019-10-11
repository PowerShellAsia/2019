if($IsWindows)
   {
      $Winvariable = $true;
   }
   else
   {
      $Winvariable = $false;
   }
Write-Output $Winvariable

$Winvariable = ($IsWindows) ? $true : $false 

if($IsWindows)
{
   if($ISCoreCLR)
   {
      $variable = $true;
   }
   else
   {
      $variable = $false;
   }
}
else
{
   $variable = $false;
}
Write-Output $variable 

($IsWindows) ? (($IsCoreCLR) ? $true : $false) : $false;
