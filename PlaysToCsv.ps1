. "C:\Git\powershell-music\Common.ps1"

$plays = GetPlays

$plays | Export-Clixml C:\Users\celston\last.fm\plays.xml
$plays | Export-Csv -NoTypeInformation C:\Users\celston\last.fm\plays.csv