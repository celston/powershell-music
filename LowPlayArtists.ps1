. "C:\Users\celston\Documents\PowerShell\Music\Common.ps1"

$DebugPreference = "Continue"

$plays = GetPlays 50

$artistGroups = $plays | Group-Object @{ Expression = { $_.Artist } } | Where-Object Count -lt 2

foreach ($group in $artistGroups) {
    $group.Name + ": " + $group.Count
}

$artistGroups.Count