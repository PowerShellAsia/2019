$DemoBlock = {
  $Url = 'https://www.google.com/'
  $SearchQuery = 'How to web scrape with PowerShell'

  $WebResult = Invoke-WebRequest -Uri $Url
  
  $Document = $WebResult.ParsedHtml
  $Query = $Document.getElementsByName('q') | Select-Object -First 1
  $Query.value = $SearchQuery
  $Form = $Document.forms | Select-Object -First 1
  
  $SubmitBase = [Uri]::New([uri]$Url, $Form.action)
  $query = '?'
  foreach($FormInput in $Form.getElementsByTagName('input') ){
    $query = '{0}{1}={2}&' -f @(
      $query,
      [System.Net.WebUtility]::UrlEncode($FormInput.Name),
      [System.Net.WebUtility]::UrlEncode($FormInput.Value)
    )
  }
  $Submit = [uri]::new($SubmitBase,$Query)

  $SearchResult = Invoke-WebRequest -Uri $Submit

  $SearchDocument = $SearchResult.ParsedHtml
  $SearchResults = $SearchDocument.getElementsByTagName('h3') | 
    Where-Object {$_.className -eq 'r'}
  $Output = foreach($Result in $SearchResults) {
    $HtmlStripped = $Result.childNodes[0].innerHTML -replace '\<[^>]*>'
    $UrlQuery = $Result.childNodes[0].href -replace '^about:'
    $ResultUrl = [Uri]::New([uri]$Url, $UrlQuery)
    'Title:'
    '  ' + ([System.Net.WebUtility]::HtmlDecode($HtmlStripped))
    'Url:'
    '  ' + $ResultUrl
    ' '
  }
  $Output | Format-List
}.ToString()

powershell.exe -command $DemoBlock
' '
' '
' '