Clear-Host

$apiKey = "59d09be6bab770f89ca6eeb33ae2b266"
$page = 1;
$user = "celston"
$artist = "Bad Religion"
$limit = 200
$urlFormat = "http://ws.audioscrobbler.com/2.0/?method=user.getartisttracks&user={0}&artist={1}&api_key={2}&limit={3}&page={4}&format=json"

$albumHash = @{}
$tracks = @()

for ($page = 1; $page -le 14; $page++) {
    $url = [string]::Format($urlFormat, $user, $artist, $apiKey, $limit, $page)
    $response = Invoke-RestMethod $url

    foreach ($track in $response.artisttracks.track) {
        $tracks += $track
    }
}

foreach ($track in $tracks) {
    $album = $track.album.'#text' -replace " \(.+", "" -replace "^The ", "" -replace "Gray Race", "Grey Race"
    if (!$albumHash.ContainsKey($album)) {
        $albumHash[$album] = 0
    }
    $albumHash[$album]++
}

$rank = 1
$albumHash.GetEnumerator() | Sort-Object Value -Descending | foreach { New-Object PSObject -Property @{ Name = $_.Key; Count = $_.Value; Rank = $rank++ } }