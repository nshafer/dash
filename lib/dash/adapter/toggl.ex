defmodule Dash.Adapter.Toggl do
  use GenServer
  require Logger

  @behaviour Dash.Adapter

  @fetch_interval_ms 60 * 1000

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  @impl true
  def fetch() do
    GenServer.cast(__MODULE__, :fetch)
  end

  # Server

  @impl true
  def init(config) do
    Logger.info("Dash.Adapter.Toggl started (#{inspect self()})")

    state = %{
      config: config,
      fetch_timer: nil,
      project_xref: %{},
    }
    |> schedule_fetch()

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:fetch, state) do
    {:noreply, fetch(state)}
  end

  @impl true
  def handle_info(:do_fetch, state) do
    {:noreply, fetch(state)}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.info("Dash.Adapter.Toggl.terminate: #{inspect reason}")
    :ok
  end

  def schedule_fetch(state) do
    %{state | fetch_timer: Process.send_after(self(), :do_fetch, @fetch_interval_ms)}
  end

  def fetch(%{config: config, project_xref: project_xref} = state) do
    Logger.debug("Dash.Adapter.Toggl.fetch")

    with(
      {:ok, entries} <- fetch_time_entries(config),
      project_xref <- process_projects(config, entries, project_xref)
    ) do
      # IO.inspect(entries, label: "entries")
      %{state | project_xref: project_xref}
    else
      error ->
        Logger.error("Fetch error: #{inspect error}")
        state
    end
  end

  @doc """
  For all of the entries retrieved, process each one in turn to check if we have fetched the project info for a given
  "pid" yet or not. If not, fetch it and update central, otherwise skip it.
  """
  def process_projects(config, entries, project_xref) do
    for entry <- entries, reduce: project_xref do
      project_xref ->
        pid = Map.get(entry, "pid", nil)

        if pid != nil and not Map.has_key?(project_xref, pid) do
          Logger.debug("Fetching project #{pid}")
          with(
            {:ok, pdata} <- fetch_project(config, pid),
            {:ok, cdata} <- maybe_fetch_client(config, pdata["cid"])
          ) do
            Logger.debug("  got pdata: #{inspect pdata}")
            Logger.debug("  got cdata: #{inspect cdata}")
            proj = Dash.Central.add_project(pdata["name"], client: cdata["name"], color: pdata["hex_color"])
            Logger.debug("  added: #{inspect proj}")
            Map.put(project_xref, pid, proj)
          else
            error ->
              Logger.error("Error fetching project #{pid}: #{inspect error}")
              project_xref
          end
        else
          project_xref
        end
    end
  end

  def fetch_time_entries(config) do
    if Application.get_env(:dash, :fake_api_calls, false) do
      {:ok, fake_time_entries()}
    else
      url =
        "https://api.track.toggl.com/api/v8/time_entries"
        |> URI.new!()
        |> Map.put(:query, URI.encode_query(%{"start_date" => week_start_string()}))
        |> URI.to_string()

      request(config, :get, url)
    end
  end

  def fetch_project(config, pid) do
    if Application.get_env(:dash, :fake_api_calls, false) do
      {:ok, fake_project(pid)}
    else
      url =
        "https://api.track.toggl.com/api/v8/projects/#{pid}"
        |> URI.new!()
        |> URI.to_string()

      with(
        {:ok, payload} <- request(config, :get, url),
        {:ok, data} <- Map.fetch(payload, "data")
      ) do
        {:ok, data}
      end
    end
  end

  def maybe_fetch_client(_config, nil), do: {:ok, nil}
  def maybe_fetch_client(config, cid) do
    if Application.get_env(:dash, :fake_api_calls, false) do
      {:ok, fake_client(cid)}
    else
      url =
        "https://api.track.toggl.com/api/v8/clients/#{cid}"
        |> URI.new!()
        |> URI.to_string()

      with(
        {:ok, payload} <- request(config, :get, url),
        {:ok, data} <- Map.fetch(payload, "data")
      ) do
        {:ok, data}
      end
    end
  end

  defp request(config, method, url, opts \\ []) do
    request = %Mojito.Request{
      method: method,
      url: url,
      headers: Keyword.get(opts, :headers, []) |> add_auth_header(config),
      body: Keyword.get(opts, :body, nil),
      opts: Keyword.get(opts, :mojito_opts, []),
    }

    with(
      {:ok, response} <- Mojito.request(request),
      {:ok, payload} <- Jason.decode(response.body),
      :ok <- validate_status_code(response)
    ) do
      {:ok, payload}
    end
  end

  defp validate_status_code(response) do
    if response.status_code >= 200 and response.status_code < 300 do
      :ok
    else
      {:error, "Server returned error: (#{response.status_code}) #{response.body}"}
    end
  end

  defp add_auth_header(headers, config) do
    {key, value} = Mojito.Headers.auth_header(config.token, "api_token")

    Mojito.Headers.put(headers, key, value)
  end

  defp week_start_string() do
    Dash.Central.week_start()
    |> DateTime.to_iso8601()
  end

  # Some fake data to use while developing so we don't keep hitting the toggl api
  def fake_time_entries() do
    [
      %{
        "at" => Dash.Time.today! |> DateTime.new!(~T[07:34:41], Dash.Time.timezone()),
        "description" => "Worked on Amber Chron Manager",
        "duration" => 2316,
        "guid" => "6fde6fbfb5f9aeb07d89d55ec15fd046",
        "id" => 2299840596,
        "pid" => 156783969,
        "start" => Dash.Time.today! |> DateTime.new!(~T[06:56:05], Dash.Time.timezone()),
        "stop" => Dash.Time.today! |> DateTime.new!(~T[07:34:41], Dash.Time.timezone()),
        "uid" => 2130859,
        "wid" => 1352395
      },
      %{
        "at" => Dash.Time.today! |> DateTime.new!(~T[08:45:12], Dash.Time.timezone()),
        "description" => "Worked on this thing",
        "duration" => 4069,
        "guid" => "020129de4ed7f8e9262a44c4edf5b413",
        "id" => 2305765062,
        "pid" => 177367363,
        "start" => Dash.Time.today! |> DateTime.new!(~T[07:37:23], Dash.Time.timezone()),
        "stop" => Dash.Time.today! |> DateTime.new!(~T[07:45:12], Dash.Time.timezone()),
        "uid" => 2130859,
        "wid" => 1352395
      },
      %{
        "at" => Dash.Time.today! |> DateTime.new!(~T[08:04:12], Dash.Time.timezone()),
        "description" => "Worked on this thing",
        "duration" => -1640628809,
        "guid" => "fc0c8758bb1eaf1353e646812f5fc1d6",
        "id" => 2305785835,
        "pid" => 177367363,
        "start" => Dash.Time.today! |> DateTime.new!(~T[08:04:12], Dash.Time.timezone()),
        "uid" => 2130859,
        "wid" => 1352395
      }
    ]
  end

  def fake_project(156783969) do
    %{
        "at" => "2020-06-09T04:06:21+00:00",
        "cid" => 46790827,
        "color" => "6",
        "hex_color" => "#06a893",
        "id" => 156783969,
        "name" => "Amber Chron Manager",
        "wid" => 1352395
    }
  end

  def fake_project(177367363) do
    %{
        "at" => "2021-12-06T19:07:50+00:00",
        "color" => "14",
        "hex_color" => "#525266",
        "id" => 177367363,
        "name" => "Dash",
        "wid" => 1352395
    }
  end

  def fake_client(46790827) do
    %{
        "at" => "2020-01-28T16:30:42+00:00",
        "id" => 46790827,
        "name" => "Company, LLC",
        "wid" => 1352395
    }
  end
end
