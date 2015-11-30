. "C:\Users\celston\Documents\PowerShell\Music\Common.ps1"

Function SearchSpotifyTracks($artist, $track) {
    $web = New-Object Net.WebClient;

    $url = "https://api.spotify.com/v1/search?q=artist%3A%22{0}%22%20track%3A%22{1}%22&type=track" -f $artist, $track;

    Try {
        $json = $web.DownloadString($url);
        $
    
        return ($json | ConvertFrom-Json);
    }
    Catch {
        Write-Debug "Failed Spotify track search for $artist - $track"
        return null;
    }
}

$DebugPreference = "Continue";

$plays = GetPlays;
$result = @();

$trackSplit = [regex]"\s-\s"

for ($i = 0; $i -lt 5000; $i++) {
    Write-Progress $i
    $rand = Get-Random -Minimum 0 -Maximum $plays.Count;
    $play = $plays[$rand];

    $artist = $play.Artist.Replace(" & ", " and ")
    $track = ([regex]"\s-\s").Split($play.Track)[0]
    
    Start-Sleep -m 100
    $spotify = SearchSpotifyTracks $artist $track

    if ($spotify -and $spotify.tracks.items.Count -gt 0) {
        $count = $spotify.tracks.items.Count

        $available = @()
        foreach ($item in $spotify.tracks.items) {
            if ($item.available_markets.Contains("US")) {
                $available += $item;
            }
        }
        if ($available.Count -eq 0) {
            Write-Debug "No available tracks for $artist - $track"
            $available = $spotify.tracks.items
        }

        $explicit = @()
        foreach ($item in $available) {
            if ($item.explicit) {
                $explicit += $item;
            }
        }
        if ($explicit.Count -gt 0) {
            $available = $explicit
        }

        $rand = Get-Random -Minimum 0 -Maximum $available.Count;
        $result += $available[$rand].uri;
    }
    else {
        Write-Debug "No Spotify track search results for $artist - $track"
    }
}

$result.Count
$result;