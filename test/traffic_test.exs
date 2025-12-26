defmodule RealDebrid.Api.TrafficTest do
  use ExUnit.Case, async: false

  describe "get/1" do
    test "returns traffic information" do
      client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))

      {:ok, traffic} = RealDebrid.Api.Traffic.get(client)

      assert is_map(traffic)
      # Traffic map has host keys with traffic info
      if map_size(traffic) > 0 do
        {_host, info} = Enum.at(traffic, 0)
        assert is_integer(info.left)
        assert is_integer(info.bytes)
        assert is_integer(info.links)
        assert is_integer(info.limit)
        assert is_binary(info.type)
      end
    end
  end

  describe "get_details/2" do
    test "returns traffic details" do
      client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))

      {:ok, details} = RealDebrid.Api.Traffic.get_details(client)

      assert is_map(details)
    end

    test "accepts date range parameters" do
      client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))

      today = Date.utc_today()
      start_date = today |> Date.add(-30) |> Date.to_iso8601()
      end_date = today |> Date.to_iso8601()

      assert {:ok, _} =
               RealDebrid.Api.Traffic.get_details(client, start: start_date, end: end_date)
    end
  end
end
