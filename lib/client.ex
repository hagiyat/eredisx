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

  def end_transaction(opts \\ []) do
    commands = commands_from_agent(agent_name)
    pid = Keyword.get(opts, :pid) || (:eredis.start_link |> elem(1))
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
end
