. "C:\Users\celston\Documents\PowerShell\Music\Common.ps1"

$DebugPreference = "Continue"

$plays = GetPlays

$threshold = (Get-Date).AddDays(-30)

$artists = $plays | Where-Object { $_.Date -gt $threshold } | Group-Object @{ Expression = { $_.Artist } } | Sort-Object Count -Descending | Select -First 10 | ForEach-Object { $_.Name }

foreach ($artist in $artists | Select -First 1) {
    $artist
    $plays | Where-Object { $_.Artist -eq $artist } | Group-Object @{ Expression = { $_.Track } } | Sort-Object Count -Descending | Select -First 50 | ForEach-Object { $_.Name }
}