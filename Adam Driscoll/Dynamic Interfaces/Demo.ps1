$Pages = @()

#Demo 0

$Pages += New-UDPage -Name "Universal Dashboard" -Content {
    
    New-UDElement -Tag "div" -Attributes @{
        style = @{
            paddingTop = "100px"
        }
    } 

    New-UDRow -Columns {
        New-UDColumn -SmallOffset 3 -SmallSize 6 -Content {
            New-UDElement -Tag "div" -Attributes @{className = 'center'} -Endpoint {
                $image = (Invoke-RestMethod "https://api.giphy.com/v1/gifs/random?api_key=$env:GiphyApiKey&tag=kitten&rating=PG").data.images.downsized
                New-UDImage -Url $image.url -Height $image.height -Width $image.width
            } -AutoRefresh -RefreshInterval 5
        }
    }

    New-UDRow -Columns {
        New-UDColumn -SmallOffset 3 -SmallSize 2 -Content {
            New-UDImage -Url 'https://github.com/ironmansoftware/universal-dashboard/raw/master/images/logo.png' -Height '200' -Width '200'
        }
        New-UDColumn -SmallSize 6 -Content {
            New-UDRow -Columns {
                New-UDHeading -Text "Interactive Websites in Universal Dashboard" -Size 3
            }
            New-UDRow -Columns {
                New-UDHeading -Text "by Adam Driscoll" -Size 4
            }
        }
    }
}

# Demo 1 

$Pages += New-UDPage -Name "Content vs Element" -Content {
    New-UDElement -Tag 'div' -Content { New-UDHeading -Text "This is static content. I've been rendered at $(Get-Date)" -Size 3 }
    New-UDElement -Tag 'div' -Endpoint { New-UDHeading -Text "This is dynamic content. I've been rendered at $(Get-Date)" -Size 3 } -AutoRefresh -RefreshInterval 1
}

# Demo 2

$Pages += New-UDPage -Name "Simple Endpoints" -Content {

    New-UDButton -Text 'Start Notepad x10' -OnClick {
        1..10 | ForEach-Object { Start-Process Notepad }
    }

    $Colors = 1..10 | ForEach-Object { [System.Drawing.Color].GetProperties().Name | Get-Random }


    New-UDRow -Columns {
        New-UDColumn -SmallOffset 3 -SmallSize 6 -Content {
            New-UDChart -Type Pie -Title 'Simple Pie Chart' -Endpoint {
                Get-Process | Group-Object -Property Name | Sort-Object -Property Count -Descending -Top 10  | Out-UDChartData -DataProperty Count -LabelProperty Name -BackgroundColor $Colors
            } 
        }
    }

    New-UDGrid -Title "Simple Grid" -Headers @("Name", "Count") -Properties @("Name", "Count") -Endpoint {
        Get-Process | Group-Object -Property Name | Sort-Object -Property Count -Descending -Top 10 | Select-Object -Property Name,Count  | Out-UDGridData
    }
}

# Demo 3

$Pages += New-UDPage -Name "Inputs" -Content {
    New-UDInput -Title "Inputs" -Endpoint {
        param(
            $SendMeAMessage,
            [bool]$YesOrNo
        )

        Show-UDToast -Message $SendMeAMessage -Title "A message from the Administrator: $YesOrNo" -Balloon
    }

    New-UDInput -Title 'Replace the Content' -Endpoint {
        param($ProcessName)

        New-UDInputAction -Content {
            New-UDGrid -Title "Processes: $ProcessName" -Headers @("Name", "Id") -Properties @("Name", "Id") -Endpoint {
                Get-Process -Name $ProcessName | Out-UDGridData
            }
        }
    }

    New-UDInput -Title 'Validate the Content' -Endpoint {
        param([Parameter(Mandatory)]$ProcessName)

        New-UDInputAction -Content {
            New-UDGrid -Title "Processes: $ProcessName" -Headers @("Name", "Id") -Properties @("Name", "Id") -Endpoint {
                Get-Process -Name $ProcessName | Out-UDGridData
            }
        }
    } -Validate

    New-UDInput -Title 'Select color' -Endpoint {
        param([ValidateSet("Red", "Green", "Blue")]$Color)

        Invoke-UDRedirect -Url "/dynamic/$Color"
    }
}

# Demo 4

$Pages += New-UDPage -Url "/dynamic/:color" -Endpoint {
    param($Color)

    New-UDCard -BackgroundColor $Color -Content {
        
    }
}

# Demo 5 

$Pages += New-UDPage -Name "Event Handlers" -Content {

    New-UDRow -Columns {
        New-UDColumn -SmallSize 3 -Content {
            New-UDButton -Text 'Click me' -OnClick {
                Show-UDToast -Message "Ouch!"
            }
        }
        New-UDColumn -SmallSize 3 -Content {
            New-UDSwitch -OnChange {
                Show-UDToast -Message "Value: $EventData"
            }        
        }
        New-UDColumn -SmallSize 3 -Content {
            New-UDSelect -Option {
                New-UDSelectOption -Name "Option 1" -Value 1
                New-UDSelectOption -Name "Option 2" -Value 2
                New-UDSelectOption -Name "Option 3" -Value 3
            } -OnChange {
                Show-UDToast -Message "Value: $EventData"
            }
        }
    }    
}

# Demo 6

$Pages += New-UDPage -Name 'Interactions' -Content {

    New-UDRow -Columns {
        New-UDColumn -SmallSize 3 -Content {
            New-UDButton -Text "Modal" -OnClick {
                Show-UDModal -Content {
                    New-UDHeading -Text "Hello, Bangalore!"  -Size 3
                } -Header {
                    New-UDHeading -Text "Modal" -Size 2
                } 
            }
        }
        New-UDColumn -SmallSize 3 -Content {
            New-UDButton -Text "Toast" -OnClick {
                Show-UDToast -Message "Hello, Bangalore!" -Title "Toast" -Icon pastafarianism -Position center
            }
        }
        New-UDColumn -SmallSize 3 -Content {
            New-UDButton -Text "Open New Window" -OnClick {
                Invoke-UDRedirect -Url "https://www.ironmansoftware.com" -OpenInNewWindow
            }
        }
    }    
}

# Demo 7

$Pages += New-UDPage -Name "Advanced Scenarios" -Content {
    New-UDCollapsible -Popout -Items {
        # Get value (show websocket)

        New-UDCollapsibleItem -Title "Get-UDElement" -Content {
            New-UDTextbox -Label "Enter some text" -Id 'MyTextbox'
            New-UDButton -Text 'Get the text' -OnClick {
                Show-UDToast -Message (Get-UDElement -Id 'MyTextbox').Attributes['value']
            }
        }
        New-UDCollapsibleItem -Title "Set-UDElement" -Content {
            New-UDElement -Tag 'span' -Id 'mySpan'
            New-UDButton -Text 'Update an element' -OnClick {
                Set-UDElement -Id 'mySpan' -Content {
                    $image = (Invoke-RestMethod "https://api.giphy.com/v1/gifs/random?api_key=$env:GiphyApiKey&tag=puppy&rating=PG").data.images.downsized
                    New-UDImage -Url $image.url -Height $image.height -Width $image.width
                }
            }
        }
        New-UDCollapsibleItem -Title "Add-UDElement and Clear-UDElement" -Content {
            New-UDElement -Tag 'ul' -Id 'myList'
            New-UDButton -Text 'Add new elements' -OnClick {
                Add-UDElement -ParentId 'myList' -Content {
                    New-UDElement -Tag 'li' -Content { (Get-Date).ToString() }
                }
            }
            New-UDButton -Text 'Clear elements' -OnClick {
                Clear-UDElement -Id 'myList'
            }
        }
        New-UDCollapsibleItem -Title "Add-UDElement and Clear-UDElement" -Content {

            $Colors = 1..10 | ForEach-Object { [System.Drawing.Color].GetProperties().Name | Get-Random }

            New-UDRow -Columns {
                New-UDColumn -SmallSize 6 -SmallOffset 3 -Content {
                    New-UDChart -Type Pie -Title 'Simple Pie Chart' -Id 'MyChart' -Endpoint {
                        Get-Process | Group-Object -Property Name | Sort-Object -Property Count -Descending -Top 10  | Out-UDChartData -DataProperty Count -LabelProperty Name -BackgroundColor $Colors
                    } 
                }
            }
            New-UDButton -Text 'Update Chart' -OnClick {
                Sync-UDElement -Id 'MyChart'
            }
            New-UDButton -Text 'Start Notepad x10' -OnClick {
                1..10 | ForEach-Object { Start-Process Notepad }
            }
        }
    }
}

$Dashboard = New-UDDashboard -Title "PowerShell Asia 2019" -Pages $Pages

Start-UDDashboard -Dashboard $Dashboard -Port 10001 -AutoReload