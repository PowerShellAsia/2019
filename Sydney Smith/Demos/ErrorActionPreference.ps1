$ErrorActionPreference

Stop-Process 13,23

Stop-Process 13,23 -ErrorAction Break

$ErrorActionPreference

$ErrorActionPreference = Break

1/0

