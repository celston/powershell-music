. "C:\Users\celston\Documents\PowerShell\Music\Common.ps1"

Function DoLastfmArtistTopTracks($artist) {
    $dir = "C:\Users\celston\last.fm\artist.getTopTracks\$artist"
    if (-Not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir
        
        $apiKey = "59d09be6bab770f89ca6eeb33ae2b266"
        $page = 1;
        $urlFormat = "http://ws.audioscrobbler.com/2.0/?method=artist.getTopTracks&artist={0}&api_key={1}&limit={2}&page={3}"
        $limit = 200
        $url = [string]::Format($urlFormat, $artist, $apiKey, $limit, $page)

        Write-Progress "Downloading artist.getTopTracks page $page of ? for $artist"
        $data = WebClientDownloadString $url
        $xml = [xml] $data
        $totalPages = [int] $xml.lfm.toptracks.totalPages
        if ($totalPages -gt 5) {
            $totalPages = 5;
        }
    
        $pathFormat = $dir + "\{0:000}.xml"
        $path = [string]::Format($pathFormat, $page);
        Out-File -FilePath $path -InputObject $data

        for ($page = 2; $page -le $totalPages; $page++) {
            $url = [string]::Format($urlFormat, $artist, $apiKey, $limit, $page)
            $path = [string]::Format($pathFormat, $page);
            Write-Progress "Downloading artist.getTopTracks page $page of $totalPages for $artist"
            Start-Sleep -m 100
            WebClientDownloadFile $url $path
        }
    }
    else {
        Write-Debug "Skipping artist.getTopTracks for $artist"
    }
}

$plays = GetPlays 20
$artists = $plays | Group-Object @{ Expression = { $_.Artist } } | Sort-Object Count -Descending | Select Name

foreach ($artist in $artists) {
    DoLastfmArtistTopTracks $artist.Name
}
