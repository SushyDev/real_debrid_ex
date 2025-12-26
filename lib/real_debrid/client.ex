defmodule RealDebrid.Client do
  @moduledoc """
  HTTP client for interacting with the Real-Debrid API.

  Creates a configured HTTP client with authentication headers, proactive
  rate limiting, and automatic backoff handling.

  ## Rate Limiting

  The Real-Debrid API is limited to 250 requests per minute. This client
  implements a two-layer rate limiting strategy:

  1. **Proactive Rate Limiting**: A token bucket algorithm prevents requests
     from exceeding the configured rate limit before they're sent.
  2. **Reactive Backoff**: If a 429 response is received, requests are
     automatically retried with exponential backoff.

  ## Configuration

  You can customize both rate limiting and retry behavior:

      # Basic usage
      client = RealDebrid.Client.new("token")

      # Custom rate limit (1-250 requests per minute)
      client = RealDebrid.Client.new("token", max_requests_per_minute: 100)

      # Custom retry behavior
      client = RealDebrid.Client.new("token", max_retries: 5, retry_delay: 2000)

      # Disable proactive rate limiting
      client = RealDebrid.Client.new("token", rate_limiter: false)

  All configuration is transparent - no code changes needed in API calls.
  """

  @host "https://api.real-debrid.com"
  @path "/rest/1.0"

  defstruct [:token, :host, :path, :req, :rate_limiter]

  @type t :: %__MODULE__{
          token: String.t(),
          host: String.t(),
          path: String.t(),
          req: term(),
          rate_limiter: pid() | nil
        }

  @doc """
  Creates a new Real-Debrid API client.

  ## Parameters

    - `token` - Your Real-Debrid API token
    - `opts` - Optional keyword list of options:
      - `:host` - API host (defaults to "https://api.real-debrid.com")
      - `:path` - API path (defaults to "/rest/1.0")
      - `:max_requests_per_minute` - Maximum requests per minute (defaults to 250, range: 1-250)
      - `:rate_limiter` - Enable/disable rate limiter (defaults to true, set to false to disable)
      - `:max_retries` - Maximum number of retry attempts for rate-limited requests (defaults to 3)
      - `:retry_delay` - Base delay in milliseconds for exponential backoff (defaults to 1000)

  ## Examples

      client = RealDebrid.Client.new("your_api_token")
      client = RealDebrid.Client.new("your_api_token", host: "https://custom.api.com")
      client = RealDebrid.Client.new("your_api_token", max_requests_per_minute: 100)
      client = RealDebrid.Client.new("your_api_token", max_retries: 5, retry_delay: 2000)
      client = RealDebrid.Client.new("your_api_token", rate_limiter: false)

  ## Note on Rate Limiting

  Since rate limits are per-token in the Real-Debrid API, each client creates
  its own rate limiter. If you need to make requests with the same token from
  multiple places in your application, consider creating a single client and
  passing it around rather than creating multiple clients with the same token.
  """
  @spec new(String.t(), keyword()) :: t()
  def new(token, opts \\ []) do
    host = Keyword.get(opts, :host, @host)
    path = Keyword.get(opts, :path, @path)
    max_retries = Keyword.get(opts, :max_retries, 3)
    retry_delay = Keyword.get(opts, :retry_delay, 1000)
    rate_limiter_opt = Keyword.get(opts, :rate_limiter, true)
    max_requests_per_minute = Keyword.get(opts, :max_requests_per_minute, 250)

    req =
      Req.new(
        base_url: host <> path,
        headers: [{"authorization", "Bearer #{token}"}],
        retry: &should_retry?/2,
        max_retries: max_retries,
        retry_delay: fn attempt -> calculate_backoff(attempt, retry_delay) end,
        retry_log_level: :warning
      )

    # Create rate limiter if enabled
    # Each client gets its own rate limiter since limits are per-token
    rate_limiter =
      if rate_limiter_opt do
        {:ok, limiter} =
          RealDebrid.RateLimiter.start_link(max_requests: max_requests_per_minute)

        limiter
      else
        nil
      end

    %__MODULE__{
      token: token,
      host: host,
      path: path,
      req: req,
      rate_limiter: rate_limiter
    }
  end

  @doc """
  Stops the rate limiter associated with this client.

  This is important for resource cleanup when you're done with a client.
  Each client owns its own rate limiter, so this will stop it.

  ## Examples

      client = RealDebrid.Client.new("token")
      # ... use client ...
      RealDebrid.Client.stop(client)
  """
  @spec stop(t()) :: :ok
  def stop(%__MODULE__{rate_limiter: limiter}) when is_pid(limiter) do
    try do
      GenServer.stop(limiter)
    catch
      :exit, {:noproc, _} ->
        :ok
    end

    :ok
  end

  def stop(%__MODULE__{}), do: :ok

  # Determines if a request should be retried (arity-2 version for newer Req)
  @spec should_retry?(Req.Request.t(), Req.Response.t() | Exception.t()) :: boolean()
  defp should_retry?(_request, %{status: 429}), do: true
  defp should_retry?(_request, %{status: status}) when status >= 500, do: true
  defp should_retry?(_request, _response), do: false

  @spec calculate_backoff(non_neg_integer(), pos_integer()) :: pos_integer()
  defp calculate_backoff(attempt, base_delay) do
    # Exponential backoff: base_delay * 2^attempt
    exponential_delay = (base_delay * :math.pow(2, attempt)) |> trunc()

    # Add jitter (random value between 0 and 20% of the delay)
    jitter = :rand.uniform(trunc(exponential_delay * 0.2))

    # Cap at 60 seconds to prevent excessive waits
    min(exponential_delay + jitter, 60_000)
  end

  @doc """
  Builds a full URL for an endpoint.
  """
  @spec get_url(t(), String.t()) :: String.t()
  def get_url(%__MODULE__{host: host, path: path}, endpoint) do
    host <> path <> endpoint
  end

  # Private helper to enforce rate limiting before making requests
  @spec check_rate_limit(t()) :: :ok
  defp check_rate_limit(%__MODULE__{rate_limiter: nil}), do: :ok

  defp check_rate_limit(%__MODULE__{rate_limiter: limiter}),
    do: RealDebrid.RateLimiter.wait(limiter)

  @doc """
  Makes a GET request to the API.
  """
  @spec get(t(), String.t(), keyword()) ::
          {:ok, map() | list() | String.t(), list()} | {:error, term()}
  def get(%__MODULE__{req: req} = client, endpoint, opts \\ []) do
    check_rate_limit(client)

    params = Keyword.get(opts, :params, %{})
    decode_body = Keyword.get(opts, :decode_body, true)

    case Req.get(req, url: endpoint, params: params, decode_body: decode_body) do
      {:ok, response} ->
        status = response.status
        body = response.body
        headers = response.headers

        if status in [200, 204] do
          {:ok, body, headers}
        else
          {:error, handle_status_code(status)}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Makes a POST request to the API with form data.
  """
  @spec post(t(), String.t(), keyword()) :: {:ok, map() | list() | nil} | {:error, term()}
  def post(%__MODULE__{req: req} = client, endpoint, opts \\ []) do
    check_rate_limit(client)

    form = Keyword.get(opts, :form, %{})
    expected_status = Keyword.get(opts, :expected_status, 200)

    case Req.post(req, url: endpoint, form: form) do
      {:ok, %Req.Response{status: ^expected_status} = response} -> {:ok, response.body}
      {:ok, response} -> {:error, handle_status_code(response.status)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Makes a PUT request to the API with multipart form data.
  """
  @spec put_multipart(t(), String.t(), list()) :: {:ok, map()} | {:error, term()}
  def put_multipart(%__MODULE__{req: req} = client, endpoint, multipart) do
    check_rate_limit(client)

    case Req.put(req, url: endpoint, form_multipart: multipart) do
      {:ok, %Req.Response{status: status} = response} when status in [200, 201, 204] ->
        {:ok, response.body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, body <> handle_status_code(status)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Makes a PUT request to the API with raw binary body.
  """
  @spec put(t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def put(%__MODULE__{req: req} = client, endpoint, opts \\ []) do
    check_rate_limit(client)

    body = Keyword.get(opts, :body, "")
    params = Keyword.get(opts, :params, %{})
    headers = Keyword.get(opts, :headers, [])

    case Req.put(req, url: endpoint, body: body, params: params, headers: headers) do
      {:ok, %Req.Response{status: status} = response} when status in [200, 201, 204] ->
        {:ok, response.body}

      {:ok, %Req.Response{status: status, body: _body}} ->
        {:error, handle_status_code(status)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Makes a DELETE request to the API.
  """
  @spec delete(t(), String.t()) :: :ok | {:error, term()}
  def delete(%__MODULE__{req: req} = client, endpoint) do
    check_rate_limit(client)

    case Req.delete(req, url: endpoint) do
      {:ok, %Req.Response{status: status}} when status in [200, 204] ->
        :ok

      {:ok, %Req.Response{status: status, body: _body}} ->
        {:error, handle_status_code(status)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Handles API error status codes.
  """
  @spec handle_status_code(integer()) :: String.t()
  def handle_status_code(status) do
    case status do
      202 -> "Action already done"
      400 -> "Bad Request (see error message)"
      401 -> "Bad token (expired, invalid)"
      403 -> "Permission denied (account locked, not premium) or Infringing torrent"
      404 -> "Not found"
      429 -> "Too many requests (rate limit exceeded)"
      503 -> "Service unavailable (see error message)"
      504 -> "Service timeout (see error message)"
      _ -> "[#{status}] Unknown error"
    end
  end
end
