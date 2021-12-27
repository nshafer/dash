# Dash

Show a basic dashboard with the following information:

1. Current clocked in status... either toggl or upwork
2. An overall stacked bar graph showing total time this week, broken up by project, scaled to goal amount.
3. A day graph for each day of the week:
  a. Broken up by hour
  b. Each hour colored in with colored boxes for each minute and color attributed for that time period.
  c. Has a progress indicator for the day for total worked hours.

## Runtime configuration

Read all runtime configuration from a .toml file:

- Weekly time goal
- Weekly billable time goal
- Daily time goal
- Daily billable time goal
- Array of API backends to start
- Backend specific configuration

## Architecture

On startup, the Central GenServer will load up that parses the config and starts each API backend.
State will only be stored in this GenServer. For now it will not persist to disk. Maybe later.
The backends will update the central state by calling update functions whenever they have new data.
When the state changes, pubsub messages will be fired off.
The frontend for now will be a LiveView that subscribes to updates from the central manager.

### Pluggable backends (toggl, upwork, etc)

Each backend will run as a GenServer perpetually.
Config data is available from the central genserver.
It is responsible for getting data from the service it is responsible for with whatever means necessary.
This could be simple polling on a timer, such as once a minute.
Or it could do something more advanced, such as connect via websockets, or graphql subscribe.
All data from the API will need to be transformed into the data required by the central data store.
When it has data, it calls central functions to update the state.

## Data

Each adapter will be responsible for submitting data to the Central GenServer in the format it expects.

### Project configuration

The first thing the adapter must submit, before it submits any WorkBlocks, is configuration of projects that it will
be submitting data about. This can be inferred from the API, or configured in the adapter's configuration, or wherever.

It will submit each project in turn by calling `Dash.Central.add_project(project_name, opts)` where opts can include
additional optional information, such as color. A unique ID will be returned to be used for submitting future data.

Duplicate project names and colors, etc are allowed, in case they are tracked in multiple places.

### WorkBlocks

The adapter will first specify the date range of data that it is submitting. This is so that it can choose to submit
a whole weeks worth, maybe on startup or on a regular interval, then only submit data in smaller chunks on a more
regular basis, such as daily or hourly. It is up to the adapter and however it is best done with that adapter's API.

When new data is submitted, all existing data will be erased that intersects with the new data period.

The data will be submitted as a list of time ranges with a start and end, the project's ID, and maybe some other
metadata. Such as:

```elixir
Dash.Central.submit_work(period_start, period_end, [
  %{
    project: 123,
    start_time: ~U[2021-12-16 21:30:00Z],
    end_time: ~U[2021-12-16 21:40:00Z],
    description: "Dash design",
  },
  %{
    project: 456,
    ...
  },
  ...
])
```

The Central GenServer will first remove all WorkBlocks that start or end in between `period_start` and `period_end`,
then update the central store. It will finally compare what was removed, and what was inserted, and determine if it
should send an update message using PubSub for any views that care.

### CurrentTask

If a task is currently being worked on, and is "running" on the backend API that the adapter monitors, then the adapter
will submit information on that current task to Dash.Central. This format is the same as a WorkBlock, just minus
an `end_time` since it's still running. Such as:

```elixir
Dash.Central.submit_current_task(%{
  project: 123,
  start_time: ~U[2021-12-16 21:30:00Z],
  end_time: ~U[2021-12-16 21:40:00Z],
  description: "Dash design",
})
```

There can be multiple current tasks running, so the backend should be sure to call
`Dash.Central.end_current_task(project_id)` when it is no longer running.

## Visualization

The Project and WorkBlock data will be accessible at any time by calling Dash.Central. In addition, there will be
several centrally available utilities for transforming that data into other representations that will be more fitting
for display. Such as histograms or aggregates by minute/hour/day of projects.

The data will be displayed with a Phoenix LiveView.

## Development setup

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
