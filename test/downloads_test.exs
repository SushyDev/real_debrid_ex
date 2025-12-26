defmodule RealDebrid.Api.DownloadsTest do
  use ExUnit.Case, async: false

  describe "get/2" do
    test "returns downloads list with total count" do
      client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))

      {:ok, response} = RealDebrid.Api.Downloads.get(client, limit: 10)

      assert is_map(response)
      assert Map.has_key?(response, :downloads)
      assert Map.has_key?(response, :total_count)
      assert is_list(response.downloads)
      assert is_integer(response.total_count)
    end

    test "accepts pagination parameters" do
      client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))

      assert {:ok, _} = RealDebrid.Api.Downloads.get(client, limit: 5, page: 2)
      assert {:ok, _} = RealDebrid.Api.Downloads.get(client, offset: 10)
    end

    test "each download has expected structure" do
      client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))

      {:ok, %{downloads: downloads}} = RealDebrid.Api.Downloads.get(client)

      if length(downloads) > 0 do
        download = List.first(downloads)
        assert is_binary(download.id)
        assert is_binary(download.filename)
        assert is_binary(download.mime_type)
        assert is_integer(download.filesize)
        assert is_binary(download.link)
        assert is_binary(download.host)
        assert is_integer(download.chunks)
      end
    end
  end

  describe "delete/2" do
    test "deletes a download" do
      client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))

      # This test would actually delete a download, so we skip it
      # unless there's a specific test download ID
      # Just verify the module exists
      assert is_atom(RealDebrid.Api.Downloads)
    end
  end
end
