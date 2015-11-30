Function UrlEncode($s) {
    [System.Web.HttpUtility]::UrlEncode($s)
}

Function SearchSpotifyTracks($artist) {
    $web = New-Object Net.WebClient;

    $artist = $artist.Replace(" & ", " ")
    $artist = $artist.Replace(" and ", " ")

    $pieces = $artist.Split(" ") | foreach { UrlEncode "artist:$_" }
    
    $q = [string]::Join((UrlEncode " "), $pieces)
    Write-Debug $q

    $url = "https://api.spotify.com/v1/search?q=$q&type=track";

    Try {
        $json = $web.DownloadString($url);
    
        return ($json | ConvertFrom-Json);
    }
    Catch {
        Write-Debug "Failed Spotify track search for $artist"
        return $null;
    }
}

Clear-Host

$DebugPreference = "Continue";

$result = @()

$artists = Get-Content C:\Users\celston\Desktop\artists.txt
foreach ($artist in $artists) {
    $spotify = SearchSpotifyTracks $artist
    
    if ($spotify -and $spotify.tracks.items.Count -gt 0) {
        $count = $spotify.tracks.items.Count

        foreach ($track in $spotify.tracks.items | Select -First 10) {
            $result += $track.uri
        }
    }
    else {
        Write-Debug "No Spotify track search results for $artist - $track"
    }
}

$result | Set-Content C:\Users\celston\Desktop\playlist.txt