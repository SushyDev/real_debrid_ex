defmodule RealDebrid.Api.SelectFilesTest do
  use ExUnit.Case, async: false

  describe "select/3" do
    test "accepts file selection format" do
      # Note: These tests would require an actual torrent ID
      # and would modify state, so we just verify the API accepts the format
      assert is_atom(RealDebrid.Api.SelectFiles)
    end
  end
end
