# Eredisx

[![Build Status](https://travis-ci.org/hagiyat/eredisx.svg?branch=master)](https://travis-ci.org/hagiyat/eredisx)

Eredisx is a library for writing in Elixir seems syntax an API of Redis.
Inspired from [redis-objects](https://github.com/nateware/redis-objects).

Here is an example:

```
# In your config/config.exs file
config :my_app, :eredisx_repos, [:default, :sub_table]
config :my_app, :
  repo: :default,
  pool_size: 10,
  pool_max_overflow: 15,
  host: "localhost",
  port: 6379,
  database: 1,
  reconnect: :no_reconnect,
  max_queue: :infinity

# In your application code

# With a model
defmodule User.Details do
  use Eredisx.Model.Hash,
    keyformat: "user:#id#:details",
    sequence: "user:id",
    schema: [
      nickname: "",
      profile_image: "",
      latest_login_at: Timex.Time.now(:secs),
      created_at: Timex.Time.now(:secs),
      updated_at: Timex.Time.now(:secs),
    ]
end

defmodule Sample.App do
  def users(user_ids) do
    Enum.map(user_ids, fn(id) -> User.Details.key(id) |> User.Details.find end)
  end

  def add_user(id, user = %User.Details{}) when is_integer(id) do
    User.Details.save(User.Details.key(id), user)
  end

  def add_user(key, user = %User.Details{}), do: User.Details.save(key, user)
end


# Without a model, to run the wrapper function of API.
defmodule Sample.App2 do
  def users(user_ids) do
    Enum.map(
      user_ids,
      fn(id) ->
        Eredisx.Api.Hash.hgetall("user:#{id}:details")
      end
    )
  end

  def add_user(id, key_values) when is_list(key_values) do
    args = Enum.flat_map(fn({k, v}) -> [Atom.to_string(k), v] end)
    Eredisx.Api.Hash.hmset("user:#{id}:details", args)
  end
end
```

## Installation

  1. Add eredisx to your list of dependencies in `mix.exs`:

        def deps do
          [{:eredisx, git: "git@github.com:hagiyat/eredisx.git"}]
        end

  **If [available in Hex](https://hex.pm/docs/publish)**, the package can be installed as:
  
        def deps do
          [{:eredisx, "~> 0.0.1"}]
        end

  2. Ensure eredisx is started before your application:

        def application do
          [applications: [:eredisx]]
        end

