defmodule Eredisx.Client do
  use Supervisor

  @pipelined_buffer_name :erdisx_pipeline_buffer

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = get_configs |> Enum.map(fn({atom, poolboy_option, eredis_option}) ->
      :poolboy.child_spec(atom, poolboy_option, eredis_option)
    end)

    :ets.new(@pipelined_buffer_name, [:named_table, :duplicate_bag, :public, {:read_concurrency, true}])
    supervise(children, strategy: :one_for_one)
  end

  defp get_default_config do
    case Application.get_env(:amigo_messaging, Eredisx) do
      env when is_list(env) -> {:ok, env[:default]}
    end
  end

  defp get_all_config do
    Application.get_env(:amigo_messaging, Eredisx)
  end

  defp get_configs do
    {:ok, default_config} = get_default_config
    get_all_config |> Enum.map(
      fn({atom, config}) ->
        poolboy_option = [
          {:name, {:local, atom}},
          {:worker_module, :eredis},
          {:size, Keyword.get(config, :pool_size) || 5},
          {:max_overflow, Keyword.get(config, :pool_max_overflow) || 10}
        ]
        eredis_option =
          Enum.reduce(config, default_config, fn({key, value}, acc) -> Keyword.put(acc, key, value) end)
          |> Keyword.drop(~w(pool_size pool_max_overflow)a)
          |> Enum.map(fn({k, v}) -> {k, if(is_binary(v), do: String.to_char_list(v), else: v)} end)
        {atom, poolboy_option, eredis_option}
      end
    )
  end

  def bag_key do
    :erlang.pid_to_list(self) |> to_string |> String.to_atom
  end

  def start_pipeline, do: :ets.insert(@pipelined_buffer_name, {bag_key, "start"})
  def start_transaction, do: :ets.insert(@pipelined_buffer_name, {bag_key, ["multi"]})

  def exec_pipeline(opts \\ []) do
    commands = tl(:ets.lookup(@pipelined_buffer_name, bag_key)) |> Enum.map(fn({_k, v}) -> v end)
    :ets.delete(@pipelined_buffer_name, bag_key)
    query_pipeline(commands, opts)
  end

  def end_transaction(opts \\ []) do
    repo = Keyword.get(opts, :repo) || :default
    commands = :ets.lookup(@pipelined_buffer_name, bag_key) |> Enum.map(fn({_k, v}) -> v end)
    :ets.delete(@pipelined_buffer_name, bag_key)
    pid = checkout(repo: repo)
    result = for [api|args] <- commands ++ [["exec"]] do
      query(api, args, pid: pid, repo: repo)
    end
    checkin(pid, repo: repo)
    result |> List.last
  end

  def checkout(opts \\ []), do: :poolboy.checkout(Keyword.get(opts, :repo) || :default)
  def checkin(pid, opts \\ []), do: :poolboy.checkin(Keyword.get(opts, :repo) || :default, pid)

  @doc """
  execute Redis command.

  ## arguments:

  - **api:** name of redis command.
  - **args:** arguments of redis command.
  - **opts:**
    - repo: setting name specified in the config.
    - pid: pid of :eredis.
  """
  def query(api, args, opts \\ []) do
    pool = Keyword.get(opts, :repo) || :default
    pid = Keyword.get(opts, :pid)
    args = List.wrap(to_string(api)) ++ List.wrap(args)

    case :ets.lookup(@pipelined_buffer_name, bag_key) do
      commands when is_list(commands) and length(commands) > 0 ->
        :ets.insert(@pipelined_buffer_name, {bag_key, args})
      _ ->
        if(is_nil(pid), do: :poolboy.transaction(pool, &(:eredis.q(&1, args))), else: :eredis.q(pid, args))
    end
  end

  def query_pipeline(commands, opts \\ []) when is_list(commands) do
    :poolboy.transaction(Keyword.get(opts, :repo) || :default, &(:eredis.qp(&1, commands)))
  end

  @doc """
  Usage:
    Eredisx.Client.redis_pipeline do
      key = "testvalue"
      Eredisx.Api.String.set(key, 100)
      Eredisx.Api.String.incr(key)
      Eredisx.Api.String.incr(key)
      Eredisx.Api.String.set(key, "hogefuga")
    end
  """
  defmacro redis_pipeline(block) do
    repo = Keyword.get(block, :repo) || :default
    quote do
      spawn fn ->
        Eredisx.Client.start_pipeline
        unquote(Keyword.get(block, :do, nil))
        Eredisx.Client.exec_pipeline(repo: unquote(repo))
      end
    end
  end

  @doc """
  Usage:
    Eredisx.Client.redis_transaction do
      key = "testvalue_transaction"
      Eredisx.Api.General.del(key)
      Eredisx.Api.String.set(key, "fugafuga")
      Eredisx.Api.String.incr(key)
      Eredisx.Api.String.incr(key)
      Eredisx.Api.String.set(key, "fugafuga" |> String.reverse)
    end
  """
  defmacro redis_transaction(block) do
    repo = Keyword.get(block, :repo) || :default
    quote do
      Eredisx.Client.start_transaction
      unquote(Keyword.get(block, :do, nil))
      {:ok, result} = Eredisx.Client.end_transaction(repo: unquote(repo))

      errors = result |> Enum.filter(fn(v) -> Regex.match?(~r/\Aerr /i, v) end)
      {if(length(errors) > 0, do: :error, else: :ok), result}
    end
  end
end
