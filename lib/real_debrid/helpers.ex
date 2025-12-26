defmodule RealDebrid.Helpers do
  @moduledoc """
  Helper functions for working with Real-Debrid data and API responses.
  """

  @doc """
  Find a torrent by its hash in a list of torrents.

  Works with maps having either atom or string keys for `:hash` / `"hash"`.

  ## Parameters

    - `torrents` - List of torrent maps
    - `hash` - The torrent hash to find

  ## Returns

    - `torrent` if found
    - `nil` if not found
  """
  @spec get_torrent_by_hash([map()], String.t()) :: map() | nil
  def get_torrent_by_hash(torrents, hash) do
    Enum.find(torrents, fn torrent ->
      Map.get(torrent, :hash) == hash or Map.get(torrent, "hash") == hash
    end)
  end

  @doc """
  Parse an integer from various input types.

  ## Parameters

    - `value` - The value to parse (can be nil, string, integer, or list)
    - `default` - The default value to return if parsing fails

  ## Returns

    - Parsed integer or default value

  ## Examples

      iex> RealDebrid.Helpers.parse_integer("123", 0)
      123

      iex> RealDebrid.Helpers.parse_integer(nil, 0)
      0

      iex> RealDebrid.Helpers.parse_integer(456, 0)
      456

      iex> RealDebrid.Helpers.parse_integer(["789"], 0)
      789
  """
  @spec parse_integer(nil | String.t() | integer() | [String.t()], integer()) :: integer()
  def parse_integer(nil, default), do: default

  def parse_integer([value | _], default) when is_binary(value) do
    parse_integer(value, default)
  end

  def parse_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end

  def parse_integer(value, _default) when is_integer(value), do: value

  @doc """
  Get a header value from response headers.

  Handles both map-based and list-based header formats from Req.

  ## Parameters

    - `headers` - Headers from Req response (map or list)
    - `key` - The header key to retrieve

  ## Returns

    - Header value (string or list) if found
    - `nil` if not found

  ## Examples

      iex> RealDebrid.Helpers.get_header(%{"x-total-count" => ["100"]}, "x-total-count")
      ["100"]

      iex> RealDebrid.Helpers.get_header([{"x-total-count", "100"}], "x-total-count")
      "100"
  """
  @spec get_header(map() | list(), String.t()) :: any()
  def get_header(headers, key) when is_map(headers) do
    case Map.fetch(headers, key) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  def get_header(headers, key) when is_list(headers) do
    case List.keyfind(headers, key, 0) do
      {_, value} -> value
      nil -> nil
    end
  end

  @doc """
  Add a parameter to a list if the value is not nil.

  Useful for building query parameter lists conditionally.

  ## Parameters

    - `params` - Existing parameter list
    - `key` - Parameter key to add
    - `value` - Parameter value (skipped if nil)

  ## Returns

    - Updated parameter list

  ## Examples

      iex> RealDebrid.Helpers.maybe_add_param([], :limit, 100)
      [limit: 100]

      iex> RealDebrid.Helpers.maybe_add_param([], :limit, nil)
      []
  """
  @spec maybe_add_param(keyword(), atom(), any()) :: keyword()
  def maybe_add_param(params, _key, nil), do: params
  def maybe_add_param(params, key, value), do: [{key, value} | params]
end
