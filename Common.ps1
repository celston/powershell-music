Function GetFilePaths($dir) {
    return Get-ChildItem -Path $dir -File;
}

Function WebClientDownloadFile($url, $path) {
    $client = New-Object Net.WebClient
    $client.DownloadFile($url, $path)
}

Function WebClientDownloadString($url) {
    $client = New-Object Net.Webclient
    return $client.DownloadString($url)
}

Function NormalizeTrackName($s) {
    $result = $s

    $phraseList = @( "live at .+?", "live from .+?", "Recorded Live in .+?", "\d\d\d\d", "Version", "Re-?recorded", '12"', "Alt(\.|ernate)?", "Explicit", "New", "Take", "5.1", "Early", "Full", "\d\dth Anniversary", "Album", "Soundtrack", "Advanced Resolution", "Best of", "Non-Album Track", "(Re)?mix(ed)?", '7"', "Stereo", "Live", "Version", "Re-?master(ed)?", "Single", "Original", "Album", "Mono", "LP", "Acoustic", "Demo", "Radio Edit", "Digital", "Bonus Track", "Edit(ed)?" );
    $words = "([\s]*((" + [string]::Join("|", $phraseList) + ")))+"

    $pattern = "\s*\[$words\]\s*$"
    $result = $result -ireplace $pattern, ""

    $pattern = "\s\($words\)\s*$"
    $result = $result -ireplace $pattern, ""

    $pattern = "\s*-$words\s*$"
    $result = $result -ireplace $pattern, ""

    $result = $result -replace "^\(([^)]+)\)", '$1'
    $result = $result -ireplace "^A ", ""
    $result = $result -ireplace "^The ", ""
    $result = $result -replace "'", ""
    $result = $result -replace "\s*,\s*", " "
    $result = $result -replace "\s*&\s*", " and "
    $result = $result -replace "^[.]+\s*", ""

    $bad = "[\.\[\]\(\)\/_]+"
    $result = $result -replace "\s+$bad\s+", " "
    $result = $result -replace "\s+$bad", " "
    $result = $result -replace "$bad\s+", " "
    $result = $result -replace "^$bad", ""
    $result = $result -replace "$bad$", ""

    (Get-Culture).TextInfo.ToTitleCase($result.Trim())
}

Function GetPlays($limit) {
    $dir = "C:\Users\celston\last.fm\user.getRecentTracks";
    $filePaths = GetFilePaths $dir;

    $result = @();

    $i = 1;
    if (-Not $limit) {
        $limit = $filePaths.Count
    }

    foreach ($filePath in $filePaths | Select -First $limit) {
        Write-Progress "Loading user.getRecentTracks file $i of $limit ($filePath)";
        [xml] $xml = Get-Content ($dir + "\" + $filePath);
        foreach ($track in $xml.lfm.recenttracks.track) {
            $date = Get-Date "1970-01-01 00:00:00";
            $date = $date.AddSeconds([int]$track.date.uts);

            $album = NormalizeAlbumName $track.album.innerText
            
            $play = @{
                'Artist' = $track.artist.InnerText;
                'Album' = $album;
                'Track' = NormalizeTrackName $track.name;
                'Date' = $date
            };
        
            $result += New-Object PSObject -Property $play;
        }

        $i++;
    }

    return $result;
}

Function NormalizeAlbumName($album) {
    $result = $album

    $result = [regex]::Replace($result, " \(.+\)\s*$", "")
    $result = [regex]::Replace($result, " \[.+\]\s*$", "")
    $result = [regex]::Replace($result, " -\s*.+$", "")
    $result = [regex]::Replace($result, "[\W\s]*$", "")

    $result
}

Function UrlDecode($s) {
    [System.Web.HttpUtility]::UrlDecode($s)
}

Function GetLocalTracks() {
    $local = Get-Content C:\users\celston\Desktop\local.txt

    $regex = "local/([^/]+)/([^/]+)/([^/]+)"

    $result = @()

    foreach ($uri in $local) {
        if ($uri -match $regex) {
            $hash = @{
                "artist" =  UrlDecode $matches[1];
                "album" = NormalizeAlbumName (UrlDecode $matches[2]);
                "name" = UrlDecode $matches[3];
                "uri" = $uri;
            }


            $result += New-Object PSObject -Property $hash
        }
    }

    $result
}