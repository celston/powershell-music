. "C:\Users\celston\Documents\PowerShell\Music\Common.ps1"

Clear-Host
$DebugPreference = "Continue"

#$ProgressPreference = 'silentlyContinue'
#$plays = GetPlays 1 | Where-Object Album -ne ""
#$ProgressPreference = 'Continue'
$plays = Import-Clixml C:\Users\celston\Desktop\plays.xml

$plays = $plays | Where-Object Album -ne "" | Where-Object { $_.Date -gt (Get-Date 2014-12-01) }

$result = @()

$total = 3200

for ($i = 1; $i -le $total; $i++) {
#foreach ($play in $plays | Select -First 10) {
    Write-Progress "$i of $($total): $($play.Artist) - $($play.Album)"
    $play = $plays | Get-Random

    $artist = [regex]::Replace($play.Artist, "^The ", "")

    $p = "(\w)\.(\w)"
    for ($k = 0; $k -lt 10; $k++) {
        $artist = [regex]::Replace($artist, $p, '$1$2')
    }

    $album = [regex]::Replace($play.Album, "^The ", "")
    for ($k = 0; $k -lt 10; $k++) {
        $album = [regex]::Replace($album, $p, '$1$2')
    }

    $artistWords = [regex]::Split($artist, "[^\w-']+") | Sort-Object -Property Length -Descending | Where-Object { $_.Length -gt 1 } | Select -First 2 | foreach { "artist:$_" }
    $artistQuery = [string]::Join(" ", $artistWords)

    $albumWords = [regex]::Split($album, "[^\w-']+") | Sort-Object -Property Length -Descending | Where-Object { $_.Length -gt 1 } | Select -First 2 | foreach { "album:$_" }
    if ($albumWords -eq $null) {
        Write-Debug "FAILED: $($play.Artist) - $($play.Album) - $($play.Track) ($artistQuery $albumQuery)"
        continue
    }
    $albumQuery = [string]::Join(" ", $albumWords)

    $url = "https://api.spotify.com/v1/search?type=track&q=$artistQuery $albumQuery"
    #$url

    $ProgressPreference = 'silentlyContinue'
    $spotify = Invoke-RestMethod -Uri $url -TimeoutSec 10
    $ProgressPreference = 'Continue'

    $tracks = $spotify.tracks.items
    
    $adjustedPopularities = $tracks | foreach { [math]::Sqrt(([int] $_.popularity)) }
    $totalPopularity = ($adjustedPopularities | Measure-Object -Sum).Sum
    #$totalPopularity

    if ($tracks.Count -eq 0 -or $totalPopularity -eq 0) {
        Write-Debug "FAILED: $($play.Artist) - $($play.Album) - $($play.Track) ($artistQuery $albumQuery)"
        continue
    }
    
    $random = Get-Random -Minimum 0 -Maximum $totalPopularity
    $done = $false
    foreach ($track in $tracks) {
        if (-not $done) {
            $popularity = [math]::Sqrt(([int] $track.popularity))

            if ($random -lt $popularity) {
                $result += $track.uri
                $done = $true
            }
            else {
                $random -= $popularity
            }
        }
    }
    if (-not $done) {
        Write-Debug "FAILED: $($play.Artist) - $($play.Album) - $($play.Track) ($artistQuery $albumQuery)"
    }
    #$result.tracks.items | Sort-Object -Property popularity -Descending
}

$result | Set-Content C:\Users\celston\Desktop\playlist.txt