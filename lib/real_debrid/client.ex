defmodule RealDebrid.Client do
  @moduledoc """
  HTTP client for interacting with the Real-Debrid API.

  Creates a configured HTTP client with authentication headers.
  """

  @host "https://api.real-debrid.com"
  @path "/rest/1.0"

  defstruct [:token, :host, :path, :req]

  @type t :: %__MODULE__{
          token: String.t(),
          host: String.t(),
          path: String.t(),
          req: term()
        }

  @doc """
  Creates a new Real-Debrid API client.

  ## Parameters

    - `token` - Your Real-Debrid API token
    - `opts` - Optional keyword list of options:
      - `:host` - API host (defaults to "https://api.real-debrid.com")
      - `:path` - API path (defaults to "/rest/1.0")

  ## Examples

      client = RealDebrid.Client.new("your_api_token")
      client = RealDebrid.Client.new("your_api_token", host: "https://custom.api.com")
  """
  @spec new(String.t(), keyword()) :: t()
  def new(token, opts \\ []) do
    host = Keyword.get(opts, :host, @host)
    path = Keyword.get(opts, :path, @path)

    req =
      Req.new(
        base_url: host <> path,
        headers: [{"authorization", "Bearer #{token}"}]
      )

    %__MODULE__{
      token: token,
      host: host,
      path: path,
      req: req
    }
  end

  @doc """
  Builds a full URL for an endpoint.
  """
  @spec get_url(t(), String.t()) :: String.t()
  def get_url(%__MODULE__{host: host, path: path}, endpoint) do
    host <> path <> endpoint
  end

  @doc """
  Makes a GET request to the API.
  """
  @spec get(t(), String.t(), keyword()) ::
          {:ok, map() | list() | String.t(), list()} | {:error, term()}
  def get(%__MODULE__{req: req}, endpoint, opts \\ []) do
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
  def post(%__MODULE__{req: req}, endpoint, opts \\ []) do
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
  def put_multipart(%__MODULE__{req: req}, endpoint, multipart) do
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
  def put(%__MODULE__{req: req}, endpoint, opts \\ []) do
    body = Keyword.get(opts, :body, "")
    params = Keyword.get(opts, :params, %{})
    headers = Keyword.get(opts, :headers, [])

    case Req.put(req, url: endpoint, body: body, params: params, headers: headers) do
      {:ok, %Req.Response{status: status} = response} when status in [200, 201, 204] ->
        {:ok, response.body}

      {:ok, %Req.Response{status: status, body: body}} ->
        IO.inspect(body)
        {:error, handle_status_code(status)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Makes a DELETE request to the API.
  """
  @spec delete(t(), String.t()) :: :ok | {:error, term()}
  def delete(%__MODULE__{req: req}, endpoint) do
    case Req.delete(req, url: endpoint) do
      {:ok, %Req.Response{status: status}} when status in [200, 204] -> :ok
      {:ok, %Req.Response{status: status, body: body}} ->
        IO.inspect(body)
        {:error, handle_status_code(status)}

      {:error, reason} -> {:error, reason}
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
