defmodule Dash.Project do
  defstruct [
    id: nil,
    name: nil,
    client: nil,
    color: nil,
    billable?: false
  ]

  def random_color() do
    [random_color_value(), random_color_value(), random_color_value()]
    |> Enum.join()
  end

  defp random_color_value() do
    :rand.uniform(256)
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
  end
end
