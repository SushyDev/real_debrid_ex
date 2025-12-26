# RealDebrid

An Elixir client library for the [Real-Debrid](https://real-debrid.com/) API.

## Installation

Add `real_debrid` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:real_debrid, github: "sushydev/real_debrid_ex"}
  ]
end
```

## Usage

### Creating a Client

```elixir
# Create a client with your API token
client = RealDebrid.Client.new("your_api_token")

# With custom rate limit (1-250 requests per minute)
client = RealDebrid.Client.new("your_api_token", 
  max_requests_per_minute: 100
)

# With custom retry configuration
client = RealDebrid.Client.new("your_api_token", 
  max_retries: 5,      # Default: 3
  retry_delay: 2000    # Base delay in ms, default: 1000
)

# Disable proactive rate limiting (only use reactive backoff)
client = RealDebrid.Client.new("your_api_token", rate_limiter: false)
```

### Rate Limiting & Automatic Backoff

The Real-Debrid API is limited to **250 requests per minute**. This library implements a **two-layer rate limiting strategy**:

#### 1. Proactive Rate Limiting (Default: Enabled)
- **Token bucket algorithm** tracks requests per minute
- **Automatically waits** before sending requests that would exceed the limit
- **Configurable**: Set `max_requests_per_minute` (1-250) when creating client
- **Prevents 429 errors** before they happen
- **Zero overhead**: Works transparently without code changes

#### 2. Reactive Backoff (Always Enabled)
- **Automatic retries**: Failed requests due to rate limiting are automatically retried
- **Exponential backoff**: Delay doubles with each retry attempt (1s, 2s, 4s, 8s...)
- **Jitter**: Random delay added to prevent thundering herd
- **Configurable**: Customize `max_retries` and `retry_delay` when creating client

Both systems work together seamlessly - proactive limiting prevents most 429 errors, while reactive backoff handles any that slip through (e.g., from other API clients sharing the same token).

You can disable proactive rate limiting with `rate_limiter: false` if you prefer to rely solely on reactive backoff.

### User Information

```elixir
{:ok, user} = RealDebrid.Api.User.get(client)
```

### Torrents

```elixir
# List torrents
{:ok, %{torrents: torrents, total_count: count}} = RealDebrid.Api.Torrents.get(client, limit: 100, page: 1)

# Get all torrents (handles pagination)
{:ok, all_torrents} = RealDebrid.Api.Torrents.get_all(client)

# Get torrent info
{:ok, info} = RealDebrid.Api.TorrentInfo.get(client, torrent_id)

# Add a magnet link
{:ok, %{id: id}} = RealDebrid.Api.AddMagnet.add(client, "magnet:?xt=...")

# Select files
:ok = RealDebrid.Api.SelectFiles.select(client, torrent_id, "all")

# Delete a torrent
:ok = RealDebrid.Api.Delete.delete(client, torrent_id)
```

### Unrestricting Links

```elixir
# Unrestrict a single link
{:ok, response} = RealDebrid.Api.UnrestrictLink.unrestrict(client, "https://...")

# Check link support
{:ok, check} = RealDebrid.Api.Unrestrict.check(client, "https://...")
```

### Downloads

```elixir
# Get downloads list
{:ok, %{downloads: downloads}} = RealDebrid.Api.Downloads.get(client, limit: 50)

# Delete a download
:ok = RealDebrid.Api.Downloads.delete(client, download_id)
```

### Settings

```elixir
# Get settings
{:ok, settings} = RealDebrid.Api.Settings.get(client)

# Update a setting
:ok = RealDebrid.Api.Settings.update(client, "locale", "en")
```

### Hosts

```elixir
# Get supported hosts
{:ok, hosts} = RealDebrid.Api.Hosts.get(client)

# Get hosts status
{:ok, status} = RealDebrid.Api.Hosts.get_status(client)

# Get hosts domains
{:ok, domains} = RealDebrid.Api.Hosts.get_domains(client)
```

### Streaming

```elixir
# Get transcoding options
{:ok, transcode} = RealDebrid.Api.Streaming.get_transcode(client, file_id)

# Get media info
{:ok, media_info} = RealDebrid.Api.Streaming.get_media_infos(client, file_id)
```

### Traffic

```elixir
# Get traffic info
{:ok, traffic} = RealDebrid.Api.Traffic.get(client)

# Get traffic details
{:ok, details} = RealDebrid.Api.Traffic.get_details(client, start: "2024-01-01", end: "2024-01-31")
```

### Server Time

```elixir
# Get server time
{:ok, time} = RealDebrid.Api.Time.get(client)

# Get server time in ISO format
{:ok, iso_time} = RealDebrid.Api.Time.get_iso(client)
```

## API Coverage

This library covers the complete Real-Debrid API:

- **Auth**: Disable access token
- **User**: Get user information
- **Torrents**: List, add (magnet/file), select files, delete, get info
- **Downloads**: List, delete
- **Unrestrict**: Check, unrestrict link/folder/container
- **Streaming**: Get transcode options, media info
- **Hosts**: List hosts, status, regex patterns, domains
- **Settings**: Get/update settings, avatar management
- **Traffic**: Get traffic info and details
- **Time**: Get server time

## License

MIT
