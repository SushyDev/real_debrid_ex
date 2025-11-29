defmodule TorrentInfoTest do
  use ExUnit.Case, async: false

  test "torrent info" do
    torrent_data = Path.expand("../fixtures/big-buck-bunny.torrent", __DIR__) |> File.read!()

    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
    {:ok, body} = RealDebrid.Api.AddTorrent.add(client, torrent_data)
    assert Map.has_key?(body, :id)

    {:ok, info} = RealDebrid.Api.TorrentInfo.get(client, body.id)

    assert Map.has_key?(info, :id)
    assert Map.has_key?(info, :filename)
    assert Map.has_key?(info, :files)
    assert Map.has_key?(info, :added)
    assert Map.has_key?(info, :bytes)
    assert is_list(info.files)

    :ok = RealDebrid.Api.Delete.delete(client, body.id)
  end
end
