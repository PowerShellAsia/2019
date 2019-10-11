# They can be totally different
Get-ChildItem $env:TEMP
Get-ChildItem /tmp

# Instead use the .NET abstraction
[System.IO.Path]::GetTempPath()
# Also
[System.IO.Path]::GetTempFileName()

# In PS 7, there's also a temp:/ provider
Get-ChildItem temp:/