defmodule RealDebrid.HelpersTest do
  use ExUnit.Case, async: true
  alias RealDebrid.Helpers

  doctest RealDebrid.Helpers

  describe "parse_integer/2" do
    test "parses string integers" do
      assert Helpers.parse_integer("123", 0) == 123
      assert Helpers.parse_integer("0", 99) == 0
      assert Helpers.parse_integer("-42", 0) == -42
    end

    test "returns default for nil" do
      assert Helpers.parse_integer(nil, 100) == 100
    end

    test "returns default for invalid strings" do
      assert Helpers.parse_integer("abc", 50) == 50
      assert Helpers.parse_integer("", 25) == 25
    end

    test "passes through integers" do
      assert Helpers.parse_integer(456, 0) == 456
      assert Helpers.parse_integer(0, 99) == 0
    end
  end

  describe "get_header/2" do
    test "retrieves header from map" do
      headers = %{"x-total-count" => ["100"], "x-page" => ["1"]}
      assert Helpers.get_header(headers, "x-total-count") == ["100"]
      assert Helpers.get_header(headers, "x-page") == ["1"]
    end

    test "returns nil for missing header in map" do
      headers = %{"x-total-count" => ["100"]}
      assert Helpers.get_header(headers, "missing") == nil
    end

    test "retrieves header from list" do
      headers = [{"x-total-count", "100"}, {"x-page", "1"}]
      assert Helpers.get_header(headers, "x-total-count") == "100"
      assert Helpers.get_header(headers, "x-page") == "1"
    end

    test "returns nil for missing header in list" do
      headers = [{"x-total-count", "100"}]
      assert Helpers.get_header(headers, "missing") == nil
    end
  end

  describe "maybe_add_param/3" do
    test "adds parameter when value is not nil" do
      params = []
      result = Helpers.maybe_add_param(params, :limit, 100)
      assert result == [limit: 100]
    end

    test "does not add parameter when value is nil" do
      params = [page: 1]
      result = Helpers.maybe_add_param(params, :limit, nil)
      assert result == [page: 1]
    end

    test "builds parameter list incrementally" do
      params =
        []
        |> Helpers.maybe_add_param(:limit, 100)
        |> Helpers.maybe_add_param(:page, nil)
        |> Helpers.maybe_add_param(:offset, 50)

      assert params == [offset: 50, limit: 100]
    end
  end

  describe "get_torrent_by_hash/2" do
    test "finds torrent with atom keys" do
      torrents = [
        %{hash: "abc123", name: "Torrent 1"},
        %{hash: "def456", name: "Torrent 2"}
      ]

      assert Helpers.get_torrent_by_hash(torrents, "abc123") == %{
               hash: "abc123",
               name: "Torrent 1"
             }
    end

    test "finds torrent with string keys" do
      torrents = [
        %{"hash" => "abc123", "name" => "Torrent 1"},
        %{"hash" => "def456", "name" => "Torrent 2"}
      ]

      assert Helpers.get_torrent_by_hash(torrents, "abc123") == %{
               "hash" => "abc123",
               "name" => "Torrent 1"
             }
    end

    test "returns nil when not found" do
      torrents = [
        %{hash: "abc123", name: "Torrent 1"}
      ]

      assert Helpers.get_torrent_by_hash(torrents, "xyz999") == nil
    end

    test "returns nil for empty list" do
      assert Helpers.get_torrent_by_hash([], "abc123") == nil
    end
  end
end
