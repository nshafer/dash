defmodule Dash.Time do
  def timezone() do
    Application.get_env(:dash, :timezone, "UTC")
  end

  @doc """
  Get the current DateTime in the app;s configured timezone
  """
  def now!() do
    DateTime.now!(timezone())
  end

  @doc """
  Returns the current Date
  """
  def today!() do
    now!() |> DateTime.to_date()
  end

  @doc """
  Converts the given time to the app's configured timezone
  """
  def to_local!(dt) do
    dt
    |> DateTime.shift_zone!(timezone())
  end
end
