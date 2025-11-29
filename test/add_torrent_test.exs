defmodule AddTorrentTest do
  use ExUnit.Case, async: false

  test "add torrent and delete" do
    torrent_data = Path.expand("../fixtures/big-buck-bunny.torrent", __DIR__) |> File.read!()

    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
    {:ok, body} = RealDebrid.Api.AddTorrent.add(client, torrent_data)
    assert Map.has_key?(body, :id)

    :ok = RealDebrid.Api.Delete.delete(client, body.id)
  end

  test "add torrent and select specific files and delete" do
    torrent_data = Path.expand("../fixtures/big-buck-bunny.torrent", __DIR__) |> File.read!()

    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
    {:ok, body} = RealDebrid.Api.AddTorrent.add(client, torrent_data)
    assert Map.has_key?(body, :id)

    :ok = RealDebrid.Api.SelectFiles.select(client, body.id, "1,3")
    :ok = RealDebrid.Api.Delete.delete(client, body.id)
  end

  test "add torrent and select video file and delete" do
    torrent_data = Path.expand("../fixtures/big-buck-bunny.torrent", __DIR__) |> File.read!()

    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
    {:ok, body} = RealDebrid.Api.AddTorrent.add(client, torrent_data)
    assert Map.has_key?(body, :id)

    :ok = RealDebrid.Api.SelectFiles.select(client, body.id, "2")
    :ok = RealDebrid.Api.Delete.delete(client, body.id)
  end

  test "add torrent and select all files and delete" do
    torrent_data = Path.expand("../fixtures/big-buck-bunny.torrent", __DIR__) |> File.read!()

    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
    {:ok, body} = RealDebrid.Api.AddTorrent.add(client, torrent_data)
    assert Map.has_key?(body, :id)

    :ok = RealDebrid.Api.SelectFiles.select(client, body.id, "all")
    :ok = RealDebrid.Api.Delete.delete(client, body.id)
  end
end
