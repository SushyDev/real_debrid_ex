defmodule ApiTorrentsTest do
  use ExUnit.Case, async: false

  test "torrents list" do
    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
    {:ok, %{torrents: torrents}} = RealDebrid.Api.Torrents.get(client, limit: 10, page: 1)
    assert is_list(torrents)
  end

  test "torrents list limit error" do
    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
    {:error, reason} = RealDebrid.Api.Torrents.get(client, limit: 6000, page: 1)
    assert reason == "limit must be between 1 and 5000, got 6000"
  end

  test "torrents list page 2" do
    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))

    {:ok, %{torrents: page1}} = RealDebrid.Api.Torrents.get(client, limit: 5, page: 1)
    assert is_list(page1)

    {:ok, %{torrents: page2}} = RealDebrid.Api.Torrents.get(client, limit: 5, page: 2)
    assert is_list(page2)

    assert page1 != page2
  end
end
