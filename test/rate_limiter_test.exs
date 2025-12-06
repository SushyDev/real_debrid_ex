defmodule RateLimiterTest do
  use ExUnit.Case, async: true
  alias RealDebrid.RateLimiter

  describe "RateLimiter" do
    test "starts with default max_requests" do
      {:ok, limiter} = RateLimiter.start_link()
      state = RateLimiter.get_state(limiter)
      assert state.max_requests == 250
      assert state.current_requests == 0
    end

    test "starts with custom max_requests" do
      {:ok, limiter} = RateLimiter.start_link(max_requests: 100)
      state = RateLimiter.get_state(limiter)
      assert state.max_requests == 100
    end

    test "enforces minimum of 1 request per minute" do
      {:ok, limiter} = RateLimiter.start_link(max_requests: 0)
      state = RateLimiter.get_state(limiter)
      assert state.max_requests == 1
    end

    test "enforces maximum of 250 requests per minute" do
      {:ok, limiter} = RateLimiter.start_link(max_requests: 300)
      state = RateLimiter.get_state(limiter)
      assert state.max_requests == 250
    end

    test "allows requests under the limit" do
      {:ok, limiter} = RateLimiter.start_link(max_requests: 10)

      # Make 5 requests
      for _ <- 1..5 do
        assert :ok = RateLimiter.wait(limiter)
      end

      state = RateLimiter.get_state(limiter)
      assert state.current_requests == 5
    end

    test "check returns remaining requests" do
      {:ok, limiter} = RateLimiter.start_link(max_requests: 10)

      assert {:ok, 10} = RateLimiter.check(limiter)

      RateLimiter.wait(limiter)
      assert {:ok, 9} = RateLimiter.check(limiter)

      RateLimiter.wait(limiter)
      assert {:ok, 8} = RateLimiter.check(limiter)
    end

    test "waits when limit is reached" do
      {:ok, limiter} = RateLimiter.start_link(max_requests: 2)

      # First two requests should be immediate
      start = System.monotonic_time(:millisecond)
      RateLimiter.wait(limiter)
      RateLimiter.wait(limiter)
      elapsed = System.monotonic_time(:millisecond) - start

      # Should take less than 100ms
      assert elapsed < 100

      state = RateLimiter.get_state(limiter)
      assert state.current_requests == 2

      # Third request would need to wait, but we'll just verify the state
      # instead of actually waiting (to keep tests fast)
      case RateLimiter.check(limiter) do
        {:error, wait_time} ->
          assert wait_time > 0
          # Should need to wait close to 60 seconds (60000ms)
          assert wait_time > 50_000

        other ->
          flunk("Expected {:error, wait_time}, got #{inspect(other)}")
      end
    end

    test "check returns error with wait time when limit reached" do
      {:ok, limiter} = RateLimiter.start_link(max_requests: 2)

      # Fill the bucket
      RateLimiter.wait(limiter)
      RateLimiter.wait(limiter)

      # Check should return error with wait time
      case RateLimiter.check(limiter) do
        {:error, wait_time} ->
          assert is_integer(wait_time)
          assert wait_time > 0

        other ->
          flunk("Expected {:error, wait_time}, got #{inspect(other)}")
      end
    end

    test "client integration with rate limiter enabled" do
      client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"))
      assert client.rate_limiter != nil
      assert is_pid(client.rate_limiter)
    end

    test "client integration with rate limiter disabled" do
      client = RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"), rate_limiter: false)
      assert client.rate_limiter == nil
    end

    test "client integration with custom rate limit" do
      client =
        RealDebrid.Client.new(System.get_env("REAL_DEBRID_TOKEN"),
          max_requests_per_minute: 100
        )

      state = RateLimiter.get_state(client.rate_limiter)
      assert state.max_requests == 100
    end
  end
end
