defmodule Eredisx.Model.Sets do
  defmacro __using__(opts \\ []) do
    opts_repo = case Keyword.get(opts, :repo) do
      x when is_atom(x) -> [repo: x]
      _ -> []
    end

    quote do
      use Eredisx.Api.Sets, unquote(opts)
      use Eredisx.Model.Sequence, unquote(opts)
      use Eredisx.Model.Base, unquote(opts)
      import Eredisx.Model.Sets

      def add(redis_key, values) do
        result = case sadd(redis_key, values, unquote(opts_repo)) do
          {:ok, v} when v == "0" -> :duplicated
          {:ok, _} -> :ok
          _ -> :error
        end
        {redis_key, result}
      end

      def remove(redis_key, value) do
        result = case srem(redis_key, [value], unquote(opts_repo)) do
          {:ok, v} when v == "0" -> :notfound
          {:ok, _} -> :ok
          _ -> :error
        end
        {redis_key, result}
      end

      def members(redis_key), do: smembers(redis_key, unquote(opts_repo)) |> Tuple.append(redis_key)

      def member?(redis_key, value) do
        case sismember(redis_key, value, unquote(opts_repo)) do
          {:ok, v} when v == "0" -> {:ok, false}
          {:ok, _} -> {:ok, true}
          _ -> {:error, nil}
        end
      end

    end
  end
end
