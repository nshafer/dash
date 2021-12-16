defmodule Dash.Central.State do
  defstruct [
    config: nil,
    current: nil,
    adapter_pids: [],
  ]
end
