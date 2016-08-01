defmodule Eredisx.Model.List do
  defmacro __using__(opts \\ []) do
    opts_repo = case Keyword.get(opts, :repo) do
      x when is_atom(x) -> [repo: x]
      _ -> []
    end

    quote do
      use Eredisx.Api.List, unquote(opts)
      use Eredisx.Model.Base, unquote(opts)
      use Eredisx.Model.Sequence, unquote(opts)
      import Eredisx.Model.List

      def members(redis_key), do: lrange(redis_key, 0, -1)
    end
  end
end
