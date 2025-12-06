ExUnit.start()

defmodule AssertionTest do
  use ExUnit.Case, async: false

  test "client create" do
    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
    assert client.token != nil
    assert client.host == "https://api.real-debrid.com"
    assert client.path == "/rest/1.0"
  end

  test "client create with custom retry options" do
    client =
      RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"),
        max_retries: 5,
        retry_delay: 2000
      )

    assert client.token != nil
  end

  test "client login" do
    client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
    {:ok, user} = RealDebrid.Api.User.get(client)
    assert Map.has_key?(user, :id)
  end
end
