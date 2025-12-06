defmodule RealDebrid.RateLimiter do
  @moduledoc """
  Token bucket rate limiter for the Real-Debrid API.

  Uses a GenServer to track request timestamps and enforce rate limits
  proactively before requests are made.
  """

  use GenServer
  require Logger

  @type t :: pid()

  # Client API

  @doc """
  Starts a new rate limiter.

  ## Options

    - `:max_requests` - Maximum requests per minute (default: 250, min: 1, max: 250)
    - `:name` - Optional name for the GenServer
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    max_requests = Keyword.get(opts, :max_requests, 250)
    name = Keyword.get(opts, :name)

    # Validate max_requests
    max_requests = max(1, min(max_requests, 250))

    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, max_requests, gen_opts)
  end

  @doc """
  Waits until a request can be made within the rate limit.

  This function will block if the rate limit has been reached, waiting
  until enough time has passed to make another request.

  Returns `:ok` when it's safe to proceed with the request.
  """
  @spec wait(t()) :: :ok
  def wait(limiter) do
    GenServer.call(limiter, :wait, :infinity)
  end

  @doc """
  Checks if a request can be made immediately without waiting.

  Returns `{:ok, remaining}` where remaining is the number of requests
  that can be made, or `{:error, wait_time}` where wait_time is the
  milliseconds to wait.
  """
  @spec check(t()) :: {:ok, non_neg_integer()} | {:error, non_neg_integer()}
  def check(limiter) do
    GenServer.call(limiter, :check)
  end

  @doc """
  Gets the current state of the rate limiter.

  Returns a map with:
  - `:max_requests` - Maximum requests per minute
  - `:current_requests` - Current number of requests in the window
  - `:oldest_request` - Timestamp of oldest request (if any)
  """
  @spec get_state(t()) :: map()
  def get_state(limiter) do
    GenServer.call(limiter, :get_state)
  end

  # Server Callbacks

  @impl true
  def init(max_requests) do
    state = %{
      max_requests: max_requests,
      # Queue to track request timestamps (in milliseconds)
      requests: :queue.new(),
      # 60 seconds in milliseconds
      window_ms: 60_000
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:wait, _from, state) do
    # Clean old requests outside the time window
    state = clean_old_requests(state)

    case can_make_request?(state) do
      {:ok, _remaining} ->
        # Add current request timestamp
        state = add_request(state)
        {:reply, :ok, state}

      {:error, wait_time} ->
        # Sleep for the required time, then add request
        Process.sleep(wait_time)
        # Clean again after sleeping
        state = clean_old_requests(state)
        # Now add the request
        state = add_request(state)
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call(:check, _from, state) do
    state = clean_old_requests(state)
    result = can_make_request?(state)
    {:reply, result, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    state = clean_old_requests(state)
    request_count = :queue.len(state.requests)

    oldest_request =
      case :queue.peek(state.requests) do
        {:value, timestamp} -> timestamp
        :empty -> nil
      end

    result = %{
      max_requests: state.max_requests,
      current_requests: request_count,
      oldest_request: oldest_request
    }

    {:reply, result, state}
  end

  # Private Functions

  defp clean_old_requests(%{requests: requests, window_ms: window_ms} = state) do
    now = System.monotonic_time(:millisecond)
    cutoff = now - window_ms

    # Remove all requests older than the window
    requests =
      :queue.filter(
        fn timestamp -> timestamp > cutoff end,
        requests
      )

    %{state | requests: requests}
  end

  defp can_make_request?(%{requests: requests, max_requests: max_requests, window_ms: window_ms}) do
    request_count = :queue.len(requests)

    if request_count < max_requests do
      {:ok, max_requests - request_count}
    else
      # Calculate how long to wait until oldest request expires
      case :queue.peek(requests) do
        {:value, oldest} ->
          now = System.monotonic_time(:millisecond)
          expires_at = oldest + window_ms
          wait_time = max(0, expires_at - now)
          {:error, wait_time + 1}

        :empty ->
          {:ok, max_requests}
      end
    end
  end

  defp add_request(%{requests: requests} = state) do
    now = System.monotonic_time(:millisecond)
    requests = :queue.in(now, requests)
    %{state | requests: requests}
  end
end
