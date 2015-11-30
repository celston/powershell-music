. "C:\Users\celston\Documents\PowerShell\Music\Common.ps1"

$plays = GetPlays
#$plays = Import-Clixml C:\Users\celston\Desktop\plays.xml

$plays | Export-Clixml C:\Users\celston\Desktop\plays.xml
$plays | Export-Csv -NoTypeInformation C:\Users\celston\Desktop\plays.csv