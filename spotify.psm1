function Set-EnvFromEnvFile {
    param (
        [string]$Path = ".env"
    )

    if (-Not (Test-Path $Path)) {
        Write-Error "Environment file not found: $Path"
        return
    }

    $envContent = Get-Content -Path $Path
    foreach ($line in $envContent) {
        if ($line -match '^\s*#') {
            continue  # Skip comments
        }
        if ($line -match '^\s*$') {
            continue  # Skip empty lines
        }
        $parts = $line -split '=', 2
        if ($parts.Count -eq 2) {
            [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim(), [System.EnvironmentVariableTarget]::Process)
        }
    }
}

# Get Spotify Access Token by Client Credentials, to be able to access public data like artists and albums
function Get-SpotifyAccessTokenByClientCredentials {
    param (
        [string]$ClientId = $env:SPOTIFY_CLIENT_ID,
        [string]$ClientSecret = $env:SPOTIFY_CLIENT_SECRET
    )

    $authUrl = "https://accounts.spotify.com/api/token"

    $headers = @{
        'Content-Type' = "application/x-www-form-urlencoded"
    }

    $body = @{
        grant_type    = "client_credentials"
        client_id     = $ClientId
        client_secret = $ClientSecret
    }

    $response = Invoke-RestMethod -Uri $authUrl -Method Post -Body $body -Headers $headers
    return $response.access_token
}

# Get Spotify Access Token by Authorization Code, to be able to access user-specific data like playlists
function Get-SpotifyAccessTokenByAuthorizationCode {
    param (
        [string]$AuthorizationCode = $env:SPOTIFY_AUTHORIZATION_CODE,
        [string]$RedirectUri = "http://127.0.0.1:3000/callback",
        [string]$ClientId = $env:SPOTIFY_CLIENT_ID,
        [string]$ClientSecret = $env:SPOTIFY_CLIENT_SECRET
    )

    $authUrl = "https://accounts.spotify.com/api/token"

    $headers = @{
        'Content-Type'  = "application/x-www-form-urlencoded"
        'Authorization' = "Basic " + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($ClientId):$($ClientSecret)"))
    }

    $body = @{
        grant_type   = "authorization_code"
        code         = $AuthorizationCode
        redirect_uri = $RedirectUri
    }

    $response = Invoke-RestMethod -Uri $authUrl -Method Post -Body $body -Headers $headers
    return $response.access_token
}

# Get Spotify Authorization Code URL, to be able to authorize the app and get the authorization code (must be done in a browser)
function Get-SpotifyAuthorizationCodeUrl {
    param (
        [string]$ClientId = $env:SPOTIFY_CLIENT_ID,
        [string]$RedirectUri = "http://127.0.0.1:3000/callback",
        [string]$Scope = "playlist-read-private playlist-read-collaborative"
    )

    $authUrl = "https://accounts.spotify.com/authorize"
    $queryParams = @{
        client_id     = $ClientId
        response_type = "code"
        redirect_uri  = $RedirectUri
        scope         = $Scope
    }

    $authRequestUrl = "$($authUrl)?" + [uri]::EscapeUriString((($queryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"))
    Write-Host "Open the following URL in your browser to authorize the app:"
    Write-Output $authRequestUrl
}

# Get Spotify Playlist by ID, to be able to access playlist details
function Get-SpotifyPlaylist {
    param (
        [string]$PlaylistId,
        [string]$AccessToken = $env:SPOTIFY_ACCESS_TOKEN,
        [string]$Market = "NO"
    )

    $playlistUrl = "https://api.spotify.com/v1/playlists/{0}?market={1}" -f $PlaylistId, $Market

    $headers = @{
        'Authorization' = "Bearer $AccessToken"
    }

    $response = Invoke-RestMethod -Uri $playlistUrl -Method Get -Headers $headers
    return $response
}

# Get Spotify Playlist Tracks, to be able to access all tracks in a playlist
function Get-SpotifyPlaylistTracks {
    param (
        [string]$PlaylistId,
        [string]$AccessToken = $env:SPOTIFY_ACCESS_TOKEN
    )

    $tracks = @()

    $headers = @{
        'Authorization' = "Bearer $AccessToken"
    }

    $playlist = Get-SpotifyPlaylist -PlaylistId $PlaylistId -AccessToken $AccessToken
    $nextUrl = $playlist.tracks.href

    $tracks = while ($nextUrl) {
        $response = Invoke-RestMethod -Uri $nextUrl -Method Get -Headers $headers
        $response.items

        if ($response.next) {
            $nextUrl = $response.next
        } else {
            $nextUrl = $null
        }
    }

    return $tracks
}