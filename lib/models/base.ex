defmodule Eredisx.Model.Base do
  defmacro __using__(opts) do
    opts_repo = case Keyword.get(opts, :repo) do
      x when is_atom(x) -> [repo: x]
      _ -> []
    end

    quote do
      import Eredisx.Model.Base

      def destroy(redis_key) do
        case Eredisx.Api.General.del(redis_key, unquote(opts_repo)) do
          {:ok, ret} ->
            {if(ret == "0", do: :notfound, else: :ok), redis_key}
          _ ->
            {:error, redis_key}
        end
      end
    end
  end
end
