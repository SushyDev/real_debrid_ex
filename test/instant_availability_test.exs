defmodule RealDebrid.Api.InstantAvailabilityTest do
  use ExUnit.Case, async: false

  describe "get/2" do
    test "returns instant availability for a hash" do
      client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
      # Big Buck Bunny hash
      hash = "8d8be8c1f3352fd90f2f8c0be37e8c6c1c0d0e8a"

      # This endpoint requires premium, so we handle both success and permission error
      case RealDebrid.Api.InstantAvailability.get(client, hash) do
        {:ok, result} ->
          assert is_map(result)
          assert result.hash == hash
          assert is_map(result.files)

        {:error, "Permission denied (account locked, not premium) or Infringing torrent"} ->
          # Expected for non-premium accounts
          assert true
      end
    end
  end

  describe "get_files/1" do
    test "extracts files from result" do
      availability = %{hash: "abc123", files: %{"rd" => []}}

      assert RealDebrid.Api.InstantAvailability.get_files(availability) == %{"rd" => []}
    end
  end

  describe "get_hash/1" do
    test "extracts hash from result" do
      availability = %{hash: "abc123", files: %{}}

      assert RealDebrid.Api.InstantAvailability.get_hash(availability) == "abc123"
    end
  end
end
