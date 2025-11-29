ExUnit.start()

defmodule AssertionTest do
  # 3) Note that we pass "async: true", this runs the tests in the
  #    test module concurrently with other test modules. The
  #    individual tests within each test module are still run serially.
  use ExUnit.Case, async: false

  # 4) Use the "test" macro instead of "def" for clarity.
  test "client create" do
    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
    assert client.token != nil
    assert client.host == "https://api.real-debrid.com"
    assert client.path == "/rest/1.0"
  end

  test "client login" do
    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
    {:ok, user} = RealDebrid.Api.User.get(client)
    assert Map.has_key?(user, :id)
  end

end
