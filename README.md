# Spotify API Demo

Playing around with the Spotify API using PowerShell.

A selection of functions for using the Spotify API can be found in [spotify.psm1](./spotify.psm1).

## Prerequisites

1. Set up an app [here](https://developer.spotify.com/dashboard) ([how-to](https://developer.spotify.com/documentation/web-api/tutorials/getting-started))
2. Configure redirect URL to `http://127.0.0.1/callback`
3. Select `Web API`
4. Save client id and client secret to a `.env` file (see [.env.example](./.env.example))

## Usage

See [main.ps1](./main.ps1) for some examples

## References

- Documentation : https://developer.spotify.com/documentation/web-api
- Authorization Code Flow: https://developer.spotify.com/documentation/web-api/tutorials/code-flow
- Scopes: https://developer.spotify.com/documentation/web-api/concepts/scopes
- Playlist API: https://developer.spotify.com/documentation/web-api/reference/get-playlist

## License

[MIT](./LICENSE)