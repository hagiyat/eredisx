defmodule Eredisx.Client do
  def agent_name do
    :erlang.pid_to_list(self) |> to_string |> String.to_atom
  end

  def commands_from_agent(name) do
    commands = Agent.get(name, &(&1))
    Agent.stop(name)
    commands
  end

  def start_pipeline do
    Agent.start_link(fn -> [] end, name: agent_name)
  end

  def exec_pipeline do
    query_pipeline(commands_from_agent(agent_name))
  end

  def start_transaction do
    Agent.start_link(fn -> [["multi"]] end, name: agent_name)
  end

  def end_transaction do
    commands = commands_from_agent(agent_name)
    pid = :eredis.start_link
    result = for [api|args] <- commands ++ [["exec"]] do
      query(api, args, pid: pid)
    end
    result |> List.last
  end

  @doc """
  execute Redis command.

  ## arguments:

  - **api:** name of redis command.
  - **args:** arguments of redis command.
  - **opts:**
    - pid: pid of :eredis.
  """
  def query(api, args, opts \\ []) do
    pid = Keyword.get(opts, :pid)
    args = List.wrap(to_string(api)) ++ List.wrap(args)
    case GenServer.whereis(agent_name) do
      agent when is_pid(agent) ->
        Agent.update(agent, fn(commands) -> commands ++ [args] end)
      _ ->
        if(is_nil(pid), do: :eredis.q(elem(:eredis.start_link, 1), args), else: :eredis.q(pid, args))
    end
  end

  def query_pipeline(commands) when is_list(commands) do
    elem(:eredis.start_link, 1) |> :eredis.qp(commands)
  end

  @doc """
  Usage:
  ```
  AnyRepo.pipeline do
    key = "testvalue"
    Eredisx.Api.String.set(key, 100)
    Eredisx.Api.String.incr(key)
    Eredisx.Api.String.incr(key)
    Eredisx.Api.String.set(key, "hogefuga")
  end
  ```
  """
  defmacro pipeline(block) do
    quote do
      res = Task.async(fn ->
        start_pipeline
        unquote(Keyword.get(block, :do, nil))
        exec_pipeline
      end)
      |> Task.await
      |> Enum.unzip
      {if(elem(res, 0) |> Enum.all?(&(&1 == :ok)), do: :ok, else: :error), elem(res, 1)}
    end
  end

  @doc """
  Usage:
  ```
  AnyRepo.transaction do
    key = "testvalue_transaction"
    Eredisx.Api.General.del(key)
    Eredisx.Api.String.set(key, "fugafuga")
    Eredisx.Api.String.incr(key)
    Eredisx.Api.String.incr(key)
    Eredisx.Api.String.set(key, "fugafuga" |> String.reverse)
  end
  ```
  """
  defmacro transaction(block) do
    quote do
      start_transaction
      unquote(Keyword.get(block, :do, nil))
      {:ok, result} = end_transaction

      errors = result |> Enum.filter(fn(v) -> Regex.match?(~r/\Aerr /i, v) end)
      {if(length(errors) > 0, do: :error, else: :ok), result}
    end
  end
end
