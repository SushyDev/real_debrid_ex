defmodule RealDebrid.Api.AddTorrent do
  @moduledoc """
  Add a torrent file to Real-Debrid.
  """

  alias RealDebrid.Client

  @type response :: %{
          id: String.t(),
          uri: String.t()
        }

  @doc """
  Add a torrent file to the user's torrents.

  ## Parameters

    - `client` - The Real-Debrid client
    - `torrent_data` - Binary content of the torrent file (must be raw binary, not a stream)
    - `opts` - Optional keyword list:
      - `:host` - The host to use (optional)

  ## Returns

    - `{:ok, %{id: id, uri: uri}}` on success
    - `{:error, reason}` on failure
  """
  @spec add(Client.t(), binary(), keyword()) :: {:ok, response()} | {:error, term()}
  def add(%Client{} = client, torrent_data, opts \\ []) when is_binary(torrent_data) do
    host = Keyword.get(opts, :host)

    # Build params for query string
    params = if host, do: %{host: host}, else: %{}

    # Send torrent file as raw body with application/x-bittorrent content-type
    case Client.put(client, "/torrents/addTorrent",
           body: torrent_data,
           params: params,
           headers: [{"content-type", "application/x-bittorrent"}]
         ) do
      {:ok, body} ->
        {:ok,
         %{
           id: body["id"],
           uri: body["uri"]
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
