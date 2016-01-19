defmodule Eredisx.Model.SortedSet do
  defmacro __using__(opts \\ []) do
    opts_repo = case Keyword.get(opts, :repo) do
      x when is_atom(x) -> [repo: x]
      _ -> []
    end

    quote do
      use Eredisx.Api.SortedSet, unquote(opts)
      use Eredisx.Model.Sequence, unquote(opts)
      use Eredisx.Model.Base, unquote(opts)
      import Eredisx.Model.SortedSet

      def add(redis_key, score, member) do
        result = case zadd(redis_key, [score, member], unquote(opts_repo)) do
          {:ok, "1"} -> :ok
          {:ok, _} -> :duplicated
          _ -> :error
        end
        {redis_key, result}
      end

      def remove(redis_key, member) do
        result = case zrem(redis_key, member, unquote(opts_repo)) do
          {:ok, "1"} -> :ok
          {:ok, _}  -> :notfound
          _ -> :error
        end
        {redis_key, result}
      end

      def range(redis_key, start: start, stop: stop) do
        {redis_key, zrange(redis_key, start, stop, unquote(opts_repo))}
      end
      def members(redis_key), do: range(redis_key, start: 0, stop: -1)

      def member?(redis_key, member) do
        case zscore(redis_key, member, unquote(opts_repo)) do
          {:ok, :undefined} -> false
          {:ok, _} -> true
          _ -> false
        end
      end
    end
  end
end
