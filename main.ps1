Import-Module "$PSScriptRoot\spotify.psm1" -Force

# Prerequisites
## Set environment variables from .env file
Set-EnvFromEnvFile -Path ".env"
#  Open this URL and copy the authorization code from the browser to the environment variable SPOTIFY_AUTHORIZATION_CODE
Get-SpotifyAuthorizationCodeUrl
# Get the access token using the authorization code
$userAccessToken = Get-SpotifyAccessTokenByAuthorizationCode -AuthorizationCode $env:SPOTIFY_AUTHORIZATION_CODE

# ------------------------------------------------------#
# Playlist testing
# ------------------------------------------------------#

# Right-click on the playlist > Share > Copy Share Link. The link will contain the playlist ID. It is the string between playlist/ and ?si=.
$playlistId = "<your_playlist_id_here>"  # Replace with your actual playlist ID

$alltracks = Get-SpotifyPlaylistTracks -PlaylistId $playlistId -AccessToken $userAccessToken

$numberOfTracks = $alltracks.Count
$numberOfArtists = ($alltracks.track.artists.name | Select-Object -Unique).Count

$top50Artists = $alltracks.track.artists.name | Group-Object | Sort-Object -Property Count -Descending | Select-Object -First 50 Count, Name
$artistsOnlyPlayedOnce = $alltracks.track.artists.name | Group-Object | Where-Object { $_.Count -eq 1 } | Select-Object -ExpandProperty Name

$top50SongsByPopularity = $alltracks.track | Sort-Object id | Get-Unique -AsString | Sort-Object -Property popularity -Descending | Select-Object -First 50 | ForEach-Object {
    [PSCustomObject]@{
        Popularity = $_.popularity
        Name       = $_.name
        Artist     = ($_.artists | ForEach-Object { $_.name }) -join ', '
    }
}

# Note use name and artists to group tracks, as some tracks have different ids but are the same song (e.g. remixes)
$tracksPlayedMoreThanOnce = $alltracks.track | Group-Object name, artists | Where-Object { $_.Count -gt 1 } | ForEach-Object {
    [PSCustomObject]@{
        Name    = $_.Group[0].name
        Count   = $_.Count
        Artists = ($_.Group | ForEach-Object { $_.artists.name } | Select-Object -Unique) -join ', '
    }
} | Sort-Object -Property Count -Descending
