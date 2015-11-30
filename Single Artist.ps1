Get-Variable -Exclude PWD,*Preference | Remove-Variable -EA 0

. "C:\Users\celston\Documents\PowerShell\Music\Common.ps1"

$plays = Import-Clixml C:\Users\celston\Desktop\plays.xml
$filteredPlays = $plays | Where-Object { $_.Artist -eq "Drive-By Truckers" }
$groupedUserPlays = $filteredPlays | Group-Object Track
#$groupedUserPlays
$userTrackNames = $groupedUserPlays | foreach { $_.Name }

$artistTopTracksXml = [xml] (Get-Content "C:\Users\celston\last.fm\artist.getTopTracks\Drive-By Truckers\001.xml")

$artistTopTracks = @()
foreach ($artistTrack in $artistTopTracksXml.lfm.toptracks.track) {
    $temp = New-Object PSObject -Property @{
        name = NormalizeTrackName $artistTrack.name
        score = [int] ([math]::Round([math]::Sqrt([int] $artistTrack.playcount)) * [math]::Sqrt([int] $artistTrack.listeners))
    }
    $artistTopTracks += $temp
}

$artistTopTrackNames = $artistTopTracks | Group-Object name | foreach { $_.Name }

$result = @{}
foreach ($t in $userTrackNames) {
    if (-not $result.ContainsKey($t)) {
        $result[$t] = New-Object PSObject -Property @{
            user = $false
            artist = $false
        }
    }
    $result[$t].user = $true
}
foreach ($t in $artistTopTrackNames) {
    if (-not $result.ContainsKey($t)) {
        $result[$t] = New-Object PSObject -Property @{
            user = $false
            artist = $false
        }
    }
    $result[$t].artist = $true
}

$result.GetEnumerator() | sort -Property name
$artistTopTrackNames | Where-Object { $userTrackNames -notcontains $_ }