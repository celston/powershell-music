. "C:\Git\powershell-music\Common.ps1"

Function TwoLongestWords($s) {
    $temp = [regex]::Split($s, "[^\w-']+") | Where-Object { $_ -ne "" -and $_ -notlike "volumes" -and $_ -notlike "doesn" -and $_ -notmatch "^\d\d\d\d-\d\d\d\d$" } | Select -Unique
    if ($temp.Count -lt 3) {
        return $temp
    }
   
    $temp | Sort-Object -Property Length -Descending | Where-Object { $_.Length -gt 1 } | Select -First 2
}

Function GetWeightRandomTrack($tracks) {
    $adjustedPopularities = $tracks | foreach { [math]::Sqrt(([int] $_.popularity) + 1) }
    $totalPopularity = ($adjustedPopularities | Measure-Object -Sum).Sum

    if ($tracks.Count -eq 0 -or $totalPopularity -eq 0) {
        return $null
    }

    $done = $false
    
    $random = Get-Random -Minimum 0 -Maximum $totalPopularity
    foreach ($track in $tracks) {
        if (-not $done) {
            $popularity = [math]::Sqrt(([int] $track.popularity) + 1)

            if ($random -lt $popularity) {
                return $track.uri
                $done = $true
            }
            else {
                $random -= $popularity
            }
        }
    }
}

Clear-Host
$DebugPreference = "Continue"

#$ProgressPreference = 'silentlyContinue'
#$plays = GetPlays 1
#$ProgressPreference = 'Continue'
$plays = Import-Clixml C:\Users\celston\last.fm\plays.xml

$plays = $plays | Where-Object Album -ne ""
#$plays = $plays | Where-Object Artist -like "NOFX"
$recentPlays = $plays | Where-Object { $_.Date -gt (Get-Date).AddDays(-60) }

#$local = GetLocalTracks
$local = Import-Clixml C:\Users\celston\last.fm\local.xml
#$local = @()

$total = 25

$randomPlays = @()
for ($i = 1; $i -le $total; $i++) {
    $randomPlay = $plays | Get-Random
    $randomPlays += $randomPlay

    $randomPlay = $recentPlays | Get-Random
    $randomPlays += $randomPlay
}

$result = @()

$total = $total * 2

$i = 1;
foreach ($play in $randomPlays) {
#foreach ($play in $plays | Select -First 10) {
    Start-Sleep -m 100
    
    Write-Debug "$($play.Artist) - $($play.Album) - $($play.Track)"
    Write-Progress "$i of $($total): $($play.Artist) - $($play.Album)"
    $i += 1

    $artist = [regex]::Replace($play.Artist, "^The ", "")
    $album = [regex]::Replace($play.Album, "^The ", "")
    $track = $play.Track

    $p = "(\w)\.(\w)"
    for ($k = 0; $k -lt 10; $k++) {
        $artist = [regex]::Replace($artist, $p, '$1$2')
    }
    for ($k = 0; $k -lt 10; $k++) {
        $track = [regex]::Replace($track, $p, '$1$2')
    }
    for ($k = 0; $k -lt 10; $k++) {
        $album = [regex]::Replace($album, $p, '$1$2')
    }

    if ($artist -eq "7Seconds") {
        $artistWords = @("artist:7", "artist:Seconds")
    }
    else {
        $artistWords = TwoLongestWords $artist | foreach { "artist:$_" }
    }
    
    $artistQuery = [string]::Join(" ", $artistWords)

    $albumWords = TwoLongestWords $album | foreach { "album:$_" }
    if ($albumWords -eq $null) {
        Write-Warning "FAILED 1: $($play.Artist) - $($play.Album) - $($play.Track) ($artistQuery $albumQuery)"
        continue
    }
    $albumQuery = [string]::Join(" ", $albumWords)

    $trackWords = TwoLongestWords $track | foreach { "track:$_" }
    if ($trackWords -eq $null) {
        Write-Warning "Track name `"$($play.Track)`" produces no individual words"
        continue
    }
    $trackQuery = [string]::Join(" ", $trackWords)

    $localArtistMatches = $local | where { $play.Artist -like $_.Artist }
    $localAlbumMatches = $localArtistMatches | where { $play.Album -like $_.Album }
    
    if ($localAlbumMatches) {
        $randomLocal = $localAlbumMatches | Get-Random
        $result += $randomLocal.Uri
    }
    else {
        $url = "https://api.spotify.com/v1/search?type=track&limit=50&q=$artistQuery $albumQuery"

        $ProgressPreference = 'silentlyContinue'
        $spotify = Invoke-RestMethod -Uri $url -TimeoutSec 10
        $ProgressPreference = 'Continue'

        $tracks = $spotify.tracks.items
    
        $randomTrack = GetWeightRandomTrack $tracks

        if ($randomTrack -eq $null) {
            Write-Warning "FAILED 2: $($play.Artist) - $($play.Album) - $($play.Track) ($artistQuery $albumQuery)"
        }
        else {
            $result += $randomTrack
        }
    }
    
    $url = "https://api.spotify.com/v1/search?type=track&limit=50&q=$artistQuery"

    $ProgressPreference = 'silentlyContinue'
    $spotify = Invoke-RestMethod -Uri $url -TimeoutSec 10
    $ProgressPreference = 'Continue'

    $tracks = $spotify.tracks.items
    if ($tracks.Count -gt 0) {
        $combinedCount = $tracks.Count + $localArtistMatches.Count
        #Write-Debug "tracks.Count: $($tracks.Count), combinedCount: $combinedCount"
        if ((Get-Random -Minimum 0 -Maximum $combinedCount) -lt $tracks.Count) {
            #Write-Debug "Remote"
            $randomTrack = GetWeightRandomTrack $tracks
            $result += $randomTrack
        }
        else {
            #Write-Debug "Local"
            $randomLocal = $localArtistMatches | Get-Random
            $result += $randomLocal.Uri
            
        }        
    }
    else {
        if ($localArtistMatches) {
            $randomLocal = $localArtistMatches | Get-Random
            $result += $randomLocal.Uri
        }
        else {
            Write-Warning "No tracks for artist $($play.Artist) ($artistQuery)"
        }
    }

    $url = "https://api.spotify.com/v1/search?type=track&limit=50&q=$artistQuery $trackQuery"

    $ProgressPreference = 'silentlyContinue'
    $spotify = Invoke-RestMethod -Uri $url -TimeoutSec 10
    $ProgressPreference = 'Continue'

    $tracks = $spotify.tracks.items
    if ($tracks.Count -gt 0) {
        $randomTrack = GetWeightRandomTrack $tracks
        $result += $randomTrack
    }
    else {
        $a = $play.Track.Replace("'", "").Replace(",", "")
        $localTrackMatches = @()
        foreach ($l in $localArtistMatches) {
            $b = $l.Name.Replace("'", "").Replace(",", "")
            if ($a -like ("*" + $b + "*") -or $b -like ("*" + $a + "*")) {
                $localTrackMatches += $l
            }
        }

        if ($localTrackMatches) {
            $randomLocal = $localTrackMatches | Get-Random
            $result += $randomLocal.Uri
        }
        else {
            Write-Warning "No tracks for artist $($play.Artist) - $($play.Track) ($artistQuery $trackQuery)"
        }
    }
}

$result = $result | Sort-Object { Get-Random }
$result | Set-Content C:\Users\celston\last.fm\playlist.txt