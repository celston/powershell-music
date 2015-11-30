$apiKey = "59d09be6bab770f89ca6eeb33ae2b266"
$page = 1;
$user = "celston"
$urlFormat = "http://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user={0}&api_key={1}&limit={2}&page={3}"
$limit = 200
$dir = "C:\Users\celston\last.fm\user.getRecentTracks"
$pathFormat = $dir + "\{0:000}.xml"

Get-ChildItem $dir | Remove-Item -Recurse

$url = [string]::Format($urlFormat, $user, $apiKey, $limit, $page)
$path = [string]::Format($pathFormat, $page);

Write-Progress "Downloading page $page of ?"
$ProgressPreference = 'silentlyContinue'
Invoke-WebRequest $url | Set-Content $path -Encoding UTF8
$ProgressPreference = 'Continue'

$xml = [xml] (Get-Content $path)
$totalPages = [int] $xml.lfm.recenttracks.totalPages
$totalPages

for ($page = 2; $page -lt ($totalPages + 1); $page++) {
    $url = [string]::Format($urlFormat, $user, $apiKey, $limit, $page)
    $path = [string]::Format($pathFormat, $page);
    Write-Progress "Downloading page $page of $totalPages"
    
    $ProgressPreference = 'silentlyContinue'
    Invoke-WebRequest $url | Set-Content $path -Encoding UTF8
    $ProgressPreference = 'Continue'
}