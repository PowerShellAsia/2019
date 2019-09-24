$RootFolder = (Get-Location).Path
$MediaFolder = Join-Path $RootFolder 'demo-1-Az-Cognitive-Service\Media'

#region install-import-login-Azure

# install module
# Install-Module PSCognitiveService -Verbose -Force -Confirm:$false

# import module
Import-Module PSCognitiveService -Verbose

# get module
Get-Command -Module PSCognitiveService

# check Azure login
if(!(Get-AzContext)){
    Connect-AzAccount -Verbose
}
else{
    Write-Host "Already logged-in to Azure`n" -ForegroundColor Green
}

#endregion install-import-login-Azure

#region local-and-azure-configuration

# create cognitive service accounts in azure
$ResourceGroup = 'demo-resource-group'
$Location = 'CentralIndia'
$CognitiveServices = @( 'ComputerVision',
                        'ContentModerator',
                        'Face',
                        'TextAnalytics',
                        'Bing.EntitySearch',
                        'Bing.Search.v7'
)

$CognitiveServices | ForEach-Object {
    $Params = @{
        AccountType       = $_ 
        ResourceGroupName = $ResourceGroup 
        SKUName           = 'F0' 
        Location          = if($_ -like "Bing*"){
                                'Global'
                            }
                            else{$Location}
    }
    New-CognitiveServiceAccount @Params | Out-Null
} 

# add subscription keys & location from azure 
# to $profile as $env variables 
# and load them in them in current session
$null = New-LocalConfiguration -FromAzure `
                               -AddKeysToProfile `
                               -Verbose

#endregion local-and-azure-configuration

# detect face, age, gender & emotion
$ImagePath = "$MediaFolder\Billgates.jpg"
# code $ImagePath

Get-Face -Path $ImagePath -Verbose |
    ForEach-Object faceAttributes| 
    Format-List *

# image description
Get-ImageDescription -Path $ImagePath|
    ForEach-Object Description | 
    Format-List

# optical character recognition
Get-ImageText -URL https://goo.gl/XyP6LJ |
    ForEach-Object {$_.regions.lines} | 
    ForEach-Object { $_.words.text -join " "}

# web search keywords
Search-Web "powershell 7" -Verbose |
    ForEach-Object {$_.webpages.value} | 
    Format-List name, url, snippet 

# image search
$keyword = 'Jeffery Snover'
$ImgURLs = (Search-Image -Text $keyword `
                        -Count 10).value.contenturl

Foreach ($Url in $ImgURLs) {
    Start-Process $url -WindowStyle Minimized
    Start-Sleep -Seconds 1
}

#region capture-and-store-images-from-a-web-search

Invoke-Item C:\temp\

$Params = @{
    Text = "Bangalore"
    Count = 10
    Safesearch = 'Strict'
    Verbose = $true
}
$Results = (Search-Image @Params).value.contenturl
$Results | ForEach-Object {
try {
    # sleep to avoid exhausting API rate limits
    Start-Sleep -Seconds 1 

    # analyze image and get a caption
    $desc = (Get-ImageDescription -URL $_).description
    $filename = 'untitled'
    $caption = $desc.captions.text

    # creates a logical file name
    $filename = $caption

    # add numbers to file name for same captions
    $path = "c:\temp\$filename.jpg"
    $i = 1
    while(Test-Path $path){
        if($filename -like "*(*)*"){
            $OpenBraces = $filename.IndexOf('(')
            $filename = $($filename[0..($OpenBraces-1)] -join '') +"($i)"
        }
        else{ $filename = $filename+"($i)" }
        $path = "c:\temp\$filename.jpg"; $i++
    }
    Write-Host "Downloading: $path" -ForegroundColor Cyan
    
    # download the images
    Invoke-WebRequest "$_" -OutFile $path 
}
catch {
    $_.exception.message
}
}
#endregion capture-and-store-images-from-a-web-search

# sentiment analysis
$sentences = @( "Morning! Such a wonderful day",
                "I am feeling little sad today",
                "I don't write pester tests!" )
Get-Sentiment -Text $sentences | ForEach-Object {
    Foreach($item in $_.documents){
        [PSCustomObject]@{
            Text = $sentences[$($item.id-1)]
            Positivity = "{0:P2}" -f $item.score
            Sentiment = if($item.score -lt 0.5){
                            'Negative'
                        }
                        else{
                            'Positive'
                        }
        }
    }
} | Format-List

# indentify key phrases
$sentences = @'
Welcome to the PowerShell GitHub Community!
PowerShell Core is a cross-platform (Windows, Linux, and macOS) automation and configuration tool/framework that works well with your existing tools and is optimized
for dealing with structured data (e.g. JSON, CSV, XML, etc.), REST APIs, and object models.
'@ -split [System.Environment]::NewLine

Get-KeyPhrase -Text $sentences | ForEach-Object {
    Foreach($item in $_.documents){
        [PSCustomObject]@{
            Text = $sentences[$($item.id-1)]
            KeyPhrases = $item.keyPhrases
        }
    }
} | ForEach-Object KeyPhrases

#region generate-word-cloud-from-a-web-search

# web search a keyword to get snippets
# extract key phrases from snippets
# build a word cloud from these key phrases
$Snippets = Search-Web "PowerShell Core" -Count 10 |
    ForEach-Object {$_.webpages.value.snippet}

$Data = @()
$Data = $Snippets | ForEach-Object {
    Get-KeyPhrase -Text $_ -ea SilentlyContinue  # extract keywords
} 
$Words = $Data.documents.keyphrases.split(' ') 

$Path = "$env:TEMP\cloud.svg"
$Params = @{
    Path = $Path
    Typeface = 'Consolas'
    ImageSize = '3000x2000'
    AllowRotation = 'None'
    Padding = 5
    StrokeWidth = 1
}
# generate word cloud using 'PSWordCloud' module
Import-Module PSWordCloud
$Words | New-WordCloud @Params
Start-Process Chrome $Path

#endregion generate-word-cloud-from-a-web-search


# detect langauge
$Languages = @( "This is English",
                "Esto es en espanol",
                "C'est en francais")
Trace-Language -Text $Languages |
    ForEach-Object {$_.documents.detectedlanguages}

# moderate content - text, image (path/url)
Test-AdultRacyContent -Text "Hello World" -Verbose | 
    ForEach-Object Classification |
    Format-List

#region test-webpages-for-adult-racy-content

# lets create a web scrape all images urls from my website
# and check if any adult or racy content exists
$Website = "http://www.ridicurious.com"
$webclient = New-Object System.Net.WebClient
$webpage = $webclient.DownloadString($Website)
$regex = "[(http(s)?):\/\/(www\.)?a-z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-z0-9@:%_\+.~#?&//=]*)((.jpg(\/)?)|(.png(\/)?)){1}(?!([\w\/]+))"

$ImgUrls = $webpage | 
            Select-String -pattern $regex -Allmatches | 
            ForEach-Object {$_.Matches} | 
            Select-Object $_.Value -Unique | 
            Where-Object {$_ -like "http*"} |
            Select-Object -First 10 

ForEach($url in $ImgUrls.value) {
    Test-AdultRacyContent -URL $url -ea SilentlyContinue | 
    Select-Object @{n='URL';e={$URL}},*classified |
    Format-List

    Start-Sleep -Seconds 1
}
#endregion test-webpages-for-adult-racy-content

<# There can a dozen of usecases in IT
    1. Ticketing System
        Priortize\tag tickets based on customer comment sentiment
    2. Github
        Content moderation bots
    3. Chat Ops [PoshBots]
        Image analysis and understanding the intent
        "restart 'server1' in 30 mins"
#>

# Back to slides
