defmodule Dash.Central.Config do
  @config_locations ~w(./dash.toml ~/dash.toml /etc/dash.toml)

  defstruct [:goals, :adapters]

  def load() do
    find_config_file!()
    |> load_config_file()
    |> normalize_config()
  end

  def list_adapters(config) do
    Map.keys(config.adapters)
  end

  def get_adapters(config) do
    config.adapters
  end

  def get_adapter_config(config, adapter) do
    Map.get(config.adapters, adapter, %{})
  end

  # Private functions
  defp find_config_file!() do
    case find_config_file(@config_locations) do
      {:ok, location} -> location
      :error -> raise "Could not find config file, checked: #{@config_locations}"
    end
  end

  defp find_config_file(locations)
  defp find_config_file([]), do: :error
  defp find_config_file([location | rest]) do
    location = Path.expand(location)

    if File.exists?(location) do
      {:ok, location}
    else
      find_config_file(rest)
    end
  end

  defp load_config_file(filename) do
    Toml.decode_file!(filename, filename: "dash.toml", keys: :atoms)
  end

  defp normalize_config(conf) do
    %__MODULE__{
      goals: %{
        daily: conf[:goals][:daily] || 8,
        weekly: conf[:goals][:weekly] || 40,
        billable: %{
          daily: conf[:goals][:billable][:daily] || 8,
          weekly: conf[:goals][:billable][:weekly] || 40,
        }
      },
      adapters: conf[:adapter] || %{},
    }
  end
end
