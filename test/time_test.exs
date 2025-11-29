defmodule ApiTimeTest do
  use ExUnit.Case, async: false

  test "time get" do
    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
    {:ok, time} = RealDebrid.Api.Time.get(client)
    assert is_binary(time)
  end

  test "time iso get" do
    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
    {:ok, time} = RealDebrid.Api.Time.get_iso(client)
    assert is_binary(time)
  end
end
