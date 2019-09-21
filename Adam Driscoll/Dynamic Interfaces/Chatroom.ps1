function Start-UDChatroom {
    param($Port = 10000)
    $loginPage = New-UDLoginPage -AuthenticationMethod @(
        New-UDAuthenticationMethod -Endpoint {
            param([PSCredential]$Credentials)
    
            New-UDAuthenticationResult -Success -UserName $Credentials.UserName
        }   
    ) 
    
    $dashboard = New-UDDashboard -Title "PowerShell Universal Dashboard Chatroom" -Content {
        New-UDRow -Columns { 
            New-UDColumn -Size 12 -Endpoint {
                New-UDCodeEditor -Id 'chatroom' -Height '90ch' -Width '100%' -Theme 'vs-dark'
            }
        }
    
        New-UDRow -Columns { 
            New-UDColumn -Size 8 {
                New-UDElement -Id "message" -Tag "input" -Attributes @{
                    type = "text"
                    value = ''
                    placeholder = "Type a chat message"
                }
            }
    
            New-UDColumn -Size 2 {
                New-UDElement -Tag "a" -Attributes @{
                    className = "btn"
                    onClick = {
                        $MessageTimestamp = Get-Date
                        $txtMessage = Get-UDElement -Id "message" 
                        $MessageContent = $txtMessage.Attributes['value']
    
                        if ([String]::IsNullOrEmpty($MessageContent)) {
                            return
                        }
                        
                        Set-UDElement -Id "message" -Attributes @{ 
                            type = "text"
                            value = ''
                            placeholder = "Type a chat message" 
                        }
    
                        Add-UDElement -ParentId "chatroom" -Content {  "[$MessageTimestamp] $($User): $MessageContent $([Environment]::Newline)" } -Broadcast
                    }
                } -Content {"Send"}
            }
        }
    } -LoginPage $LoginPage 
    
    Start-UDDashboard -Port $Port -Dashboard $dashboard -AllowHttpForLogin -Force
}

