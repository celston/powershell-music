. "C:\Users\celston\Documents\PowerShell\Music\Common.ps1"

$DebugPreference = "Continue";

Function SearchSpotifyTracks($artist, $track) {
    $web = New-Object Net.WebClient;

    $artistSplit = [regex] "[ ()]+"
    $artistParts = $artistSplit.Split($artist) | Where-Object { $_ -ne "" }
    #Write-Debug ("Artist: " + [string]::Join(", ", $artistParts))

    $trackSplit = [regex] "\s+"
    $trackParts = $trackSplit.Split(($track -replace "[^a-zA-Z0-9 ']", "")) | Where-Object { $_ -ne "" }
    #Write-Debug ("Track: " + [string]::Join(", ", $trackParts))

    $queries = $artistParts | foreach { "artist%3A%22$_%22" }
    $queries += $trackParts | foreach { "track%3A%22$_%22" }
    $query = [string]::Join("%20", $queries)
    #Write-Debug $query

    $url = "https://api.spotify.com/v1/search?q=$query&type=track"

    Try {
        $json = $web.DownloadString($url);
    
        return ($json | ConvertFrom-Json);
    }
    Catch {
        Write-Debug "Failed Spotify track search for $artist - $track"
        Write-Debug $query
        return $null;
    }
}

$input = Import-Csv C:\Users\celston\Desktop\tracks.txt -Delimiter "`t"

$result = @()

$i = 1;
$inputCount = $input.Count
foreach ($line in $input) {
    $artist = $line.artist.Replace(" & ", " and ")
    $track = $line.name

    Write-Progress "$i of $inputCount   $artist - $track"
    $i++

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

        $sorted = $available | Sort-Object -Descending popularity

        $result += $sorted[0].uri;
    }
    else {
        Write-Debug "No Spotify track search results for $artist - $track"
    }
}

$result | Set-Content C:\Users\celston\Desktop\playlist.txt