$Pages = @()
#Demo 1

$Pages += New-UDPage -Name "Basic" -Content {
    New-UDMap -Endpoint {
        New-UDMapLayerControl -Content {
            New-UDMapBaseLayer -Name "Mapnik" -Content {
                New-UDMapRasterLayer -TileServer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png' 
            } -Checked

            New-UDMapOverlay -Name "Markers" -Content {
                New-UDMapMarker -Latitude 12.9214774 -Longitude 77.666895 
            } -Checked
        }
    }
}

#Demo 2

$Pages += New-UDPage -Name "Markers" -Content {
    New-UDMap -Endpoint {
        New-UDMapLayerControl -Id 'layercontrol' -Content {
            New-UDMapBaseLayer -Name "Mapnik" -Content {
                New-UDMapRasterLayer -TileServer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png' 
            } -Checked

            New-UDMapOverlay -Name "Markers" -Content {
                New-UDMapMarker -Latitude 12.9987712 -Longitude 77.5899184 -Popup (
                    New-UDMapPopup -Content { 
                        New-UDHeading -Text "Bangalore Palace" -Size 3
                        New-UDElement -Tag 'p'
                        New-UDImage -Url '/images/bangalore-palace.jpg' -Height 150 -Width 150
                    } -MinWidth 500
                )
                New-UDMapMarker -Latitude 12.9729238 -Longitude 77.5875969 -Popup (
                    New-UDMapPopup -Content { 
                        New-UDHeading -Text "Cubbon Park" -Size 3
                        New-UDElement -Tag 'p'
                        New-UDImage -Url '/images/cubbon.jpg'  -Height 150 -Width 150
                    } -MinWidth 500
                )
                New-UDMapMarker -Latitude 12.9525425 -Longitude 77.5846605 -Popup (
                    New-UDMapPopup -Content { 
                        New-UDHeading -Text "Lalbagh Botanical Garden" -Size 3
                        New-UDElement -Tag 'p'
                        New-UDImage -Url '/images/lalbagh.jpg'  -Height 150 -Width 150
                    } -MinWidth 500
                )
                New-UDMapMarker -Latitude 12.9214774 -Longitude 77.666895 -Popup (
                    New-UDMapPopup -Content { 
                        New-UDHeading -Text "Microsoft" -Size 3
                        New-UDElement -Tag 'p'
                        New-UDImage -Url '/images/microsoft.jpg'  -Height 150 -Width 150
                    } -MinWidth 500
                )
                New-UDMapMarker -Latitude 12.9796696 -Longitude 77.5890598 -Popup (
                    New-UDMapPopup -Content { 
                        New-UDHeading -Text "Suvarana Vidhana" -Size 3
                        New-UDElement -Tag 'p'
                        New-UDImage -Url '/images/Suvarana Vidhana.jpg'  -Height 150 -Width 150
                    } -MinWidth 500
                )
            } -Checked
        }

    }
}

#Demo 3

[Xml]$Gpx = Get-Content (Join-Path $PSScriptRoot 'day1.gpx')
$Cache:Day1 = $Gpx.gpx.trk.trkseg.trkpt | ForEach-Object { 
    ,@($_.lat , $_.lon)
}

[Xml]$Gpx = Get-Content (Join-Path $PSScriptRoot 'day2.gpx')
$Cache:Day2 = $Gpx.gpx.trk.trkseg.trkpt | ForEach-Object { 
    ,@($_.lat , $_.lon)
}

[Xml]$Gpx = Get-Content (Join-Path $PSScriptRoot 'day3.gpx')
$Cache:Day3 = $Gpx.gpx.trk.trkseg.trkpt | ForEach-Object { 
    ,@($_.lat , $_.lon)
}

$Pages += New-UDPage -Name "Vectors" -Content {
    New-UDMap -Endpoint {
        New-UDMapLayerControl -Id 'layercontrol' -Content {
            New-UDMapBaseLayer -Name "Mapnik" -Content {
                New-UDMapRasterLayer -TileServer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png' 
            } -Checked

            New-UDMapOverlay -Name "Day 1" -Content {
               New-UDMapVectorLayer -Polyline -Positions $Cache:Day1 -Color Red 
            }

            New-UDMapOverlay -Name "Day 2" -Content {
                New-UDMapVectorLayer -Polyline -Positions $Cache:Day2 -Color Green 
            }

             New-UDMapOverlay -Name "Day 3" -Content {
                New-UDMapVectorLayer -Polyline -Positions $Cache:Day3 -Color Blue 
             } 
        }
    }
}

# Demo 4

$Pages += New-UDPage -Name "Heatmap" -Content {
    New-UDMap -Endpoint {
        New-UDMapRasterLayer -TileServer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png' 
        New-UDMapHeatmapLayer -Points @(
            @(-37.9019339833, 175.3879181167, "625"),
            @(-37.90920365, 175.4053418167, "397"),
            @(-37.9057407667, 175.39478875, "540"),
            @(-37.9243174333, 175.4220341833, "112"),
            @(-37.8992012333, 175.3666729333, "815"),
            @(-37.9110874833, 175.4102195833, "360"),
            @(-37.9027096, 175.3913196333, "591"),
            @(-37.9011183833, 175.38410915, "655"),
            @(-37.9234701333, 175.4155696333, "181"),
            @(-37.90254175, 175.3926162167, "582"),
            @(-37.92450575, 175.4246711167, "90"),
            @(-37.9242924167, 175.4289432833, "47"),
            @(-37.8986079833, 175.3685293333, "801")
        )
    } -Height '100vh'
}

# Demo 5

$Pages += New-UDPage -Name "Marker Cluster" -Content {
    New-UDMap -Endpoint {
        New-UDMapLayerControl -Id 'layercontrol' -Content {
            New-UDMapBaseLayer -Name "Mapnik" -Content {
                New-UDMapRasterLayer -TileServer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png' 
            } -Checked

            New-UDMapOverlay -Name "Cluster" -Content {
                New-UDMapMarkerClusterLayer -Id 'cluster-layer' -Markers @(
                    
                )
            } -Checked
        }
    }

    New-UDTextbox -Id 'txtAddress' -Label 'Address' 

    New-UDButton -Text "Add marker to cluster" -OnClick {
        $Address = (Get-UDElement -Id 'txtAddress').Attributes['value']

        $item = Invoke-RestMethod "https://geocoder.cit.api.here.com/6.2/geocode.json?searchtext=$Address&app_id=iNPNHlPcw9k4eNctOUA6&app_code=GeTsILqZXrTDuvEFloPYqA&gen=8"
        $position = $item.response.view.result.location.displayposition

        Add-UDElement -ParentId 'cluster-layer' -Content {
            New-UDMapMarker -Latitude $position.latitude -Longitude $position.longitude
        } -Broadcast

        Show-UDToast -Message "Added marker for $Address" -Broadcast
    }
}

# Demo 6

$Pages += New-UDPage -Name "Interactive  maps" -Content {
    New-UDButton -Text 'Add Circle' -OnClick {
        Add-UDElement -ParentId 'Feature-Group' -Content {
            New-UDMapVectorLayer -Id 'Vectors' -Circle -Latitude 51.505 -Longitude -0.09 -Radius 500 -Color blue -FillColor blue -FillOpacity .5 
        }
    }
    
    New-UDButton -Text 'Remove Circle' -OnClick {
        Remove-UDElement -Id 'Vectors' 
    }
    
    New-UDButton -Text 'Add Marker' -OnClick {
        Add-UDElement -ParentId 'Feature-Group' -Content {
            New-UDMapMarker -Id 'marker' -Latitude 51.505 -Longitude -0.09 -Popup (
                New-UDMapPopup -Content {
                    New-UDCard -Title "Test"
                } -MaxWidth 600
            ) 
        }
    }
    
    New-UDButton -Text 'Remove Marker' -OnClick {
        Remove-UDElement -Id 'marker' 
    }
    
    New-UDButton -Text 'Add Layer' -OnClick {
        Add-UDElement -ParentId 'layercontrol' -Content {
            New-UDMapOverlay -Id 'MyNewLayer' -Name "MyNewLayer" -Content {
                New-UDMapFeatureGroup -Id 'Feature-Group2' -Content {
                    1..100 | % {
                        New-UDMapVectorLayer -Id 'test' -Circle -Latitude "51.$_" -Longitude -0.09 -Radius 50 -Color red -FillColor blue -FillOpacity .5        
                    }
                }
            } -Checked
            
        }
    }
    
    New-UDButton -Text 'Remove Layer' -OnClick {
        Remove-UDElement -Id 'MyNewLayer' 
    }
    
    New-UDButton -Text 'Move' -OnClick {
        Set-UDElement -Id 'map' -Attributes @{
            latitude = 51.550
            longitude = -0.09
            zoom = 10
        }
    }
    
    New-UDButton -Text "Add marker to cluster" -OnClick {
        Add-UDElement -ParentId 'cluster-layer' -Content {
            $Random = Get-Random -Minimum 0 -Maximum 100
            $RandomLat = $Random + 400
            New-UDMapMarker -Latitude "51.$RandomLat" -Longitude "-0.$Random"
        }
    }
    
    New-UDButton -Text "Add points to heatmap" -OnClick {
        Add-UDElement -ParentId 'heatmap' -Content {
            @(
                @(51.505, -0.09, "625"),
                @(51.505234, -0.0945654, "625"),
                @(51.50645, -0.098768, "625"),
                @(51.5056575, -0.0945654, "625"),
                @(51.505955, -0.095675, "625"),
                @(51.505575, -0.09657, "625"),
                @(51.505345, -0.099876, "625"),
                @(51.505768, -0.0923432, "625"),
                @(51.505567, -0.02349, "625"),
                @(51.50545654, -0.092342, "625"),
                @(51.5045645, -0.09342, "625")
            )
        }
    }
    
    New-UDButton -Text "Clear heatmap" -OnClick {
        Clear-UDElement -Id 'heatmap'
    }
    
    New-UDMap -Id 'map' -Endpoint {
        New-UDMapLayerControl -Id 'layercontrol' -Content {
            New-UDMapBaseLayer -Name "Mapnik" -Content {
                New-UDMapRasterLayer -TileServer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png' 
            } -Checked
    
            New-UDMapOverlay -Name "Markers" -Content {
                New-UDMapFeatureGroup -Id 'Feature-Group' -Content {
                    New-UDMapMarker -Id 'marker' -Latitude 51.505 -Longitude -0.09
                } -Popup (
                    New-UDMapPopup -Content {
                        New-UDCard -Title "Test123"
                    } -MaxWidth 600
                )
            } -Checked
    
            New-UDMapOverlay -Name 'Vectors' -Content {
                New-UDMapFeatureGroup -Id 'Vectors' -Content {
    
                }
            } -Checked
    
            New-UDMapOverlay -Name "Heatmap" -Content {
                New-UDMapHeatmapLayer -Id 'heatmap' -Points @() 
            } -Checked 
    
            New-UDMapOverlay -Name "Cluster" -Content {
                New-UDMapMarkerClusterLayer -Id 'cluster-layer' -Markers @(
                    1..100 | ForEach-Object {
                        $Random = Get-Random -Minimum 0 -Maximum 100
                        $RandomLat = $Random + 400
                        New-UDMapMarker -Latitude "51.$RandomLat" -Longitude "-0.$Random"
                    }
                )
            } -Checked
    
        }
        
    } -Latitude 51.505 -Longitude -0.09 -Zoom 13 -Height '100vh' -Animate
}

$Folder = Publish-UDFolder -Path "$PSScriptRoot\images" -RequestPath '/images'
$Dashbard = New-UDDashboard -Title "PowerShell Conference Asia 2019" -Pages $Pages
Start-UDDashboard -Port 10001 -Force -AutoReload -PublishedFolder $Folder -Dashboard $Dashbard