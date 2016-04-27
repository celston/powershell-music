. "C:\Git\powershell-music\Common.ps1"

$local = Get-Content C:\users\celston\last.fm\local.txt

$remoteRegex = "open.spotify.com/track/(.+)"
$localRegex = "local/([^/]+)/([^/]+)/([^/]+)"

$result = @()

$i = 1
$count = $local.Count

foreach ($line in $local) {
    Write-Progress "$i of $count"
    $i++

    Start-Sleep -m 250
    if ($line -match $remoteRegex) {
        $url = "https://api.spotify.com/v1/tracks/$($matches[1])"
        $ProgressPreference = 'silentlyContinue'
        $response = Invoke-RestMethod $url
        $ProgressPreference = 'Continue'
        
        $hash = @{
            "artist" = $response.artists[0].name;
            "album" = NormalizeAlbumName ($response.album.name);
            "name" = $response.name;
            "uri" = $response.uri;
        }
        
        $result += New-Object PSObject -Property $hash
    }
    elseif ($line -match $localRegex) {
        $hash = @{
            "artist" =  UrlDecode $matches[1];
            "album" = NormalizeAlbumName (UrlDecode $matches[2]);
            "name" = UrlDecode $matches[3];
            "uri" = $line;
        }


        $result += New-Object PSObject -Property $hash
    }
}

$result
$result | Export-Clixml C:\Users\celston\last.fm\local.xml