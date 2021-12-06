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

On startup, a central GenServer will load up that parses the config and starts each API backend.
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
