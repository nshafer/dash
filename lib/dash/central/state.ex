defmodule Dash.Central.State do
  defstruct [
    config: nil,
    projects: %{},
    current: nil,
    workblocks: [],
    adapter_pids: [],
  ]
end
