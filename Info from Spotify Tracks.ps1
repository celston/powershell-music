Clear-Host

Get-Content 'C:\Users\celston\Desktop\New Text Document (2).txt' |
foreach { Invoke-RestMethod $_.Replace("open.spotify.com/track/", "api.spotify.com/v1/tracks/") } |
foreach { """" + $_.artists[0].name + """,""" + $_.name + """,""" + $_.album.name + """" }