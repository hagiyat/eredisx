defmodule Eredisx.Model.Hash do
  defmacro __using__(opts \\ []) do
    opts_repo = case Keyword.get(opts, :repo) do
      x when is_atom(x) -> [repo: x]
      _ -> []
    end

    quote do
      use Eredisx.Api.Hash, unquote(opts)
      use Eredisx.Model.Sequence, unquote(opts)
      use Eredisx.Model.Base, unquote(opts)
      import Eredisx.Model.Hash

      defstruct unquote(opts[:schema])

      def find(redis_key) do
        case hgetall(redis_key, unquote(opts_repo)) do
          {:ok, []} ->
            {:ok, :notfound}
          {:ok, key_values} ->
            {:ok, to_model(key_values, redis_key, __MODULE__.__struct__)}
          _ ->
            {:error, nil}
        end
      end

      # TODO: modelを__MODULE__.__struct__でパターンマッチ
      def save(model, redis_key) do
        {redis_key, hmset(redis_key, dump_model(model), unquote(opts_repo))}
      end

      unquote do
        if opts[:sequence] do
          quote do
            def save(model), do: save(model, generate_key)
          end
        end
      end
    end
  end

  def dump_model(%{} = model) do
    model
    |> Map.from_struct
    |> Map.to_list
    |> Enum.map(fn({key, value}) -> [key |> to_string, value] end)
    |> List.flatten
  end

  def to_model(params, key, model), do: {key, to_model(params, model)}
  def to_model(params, model) when is_list(params) and is_map(model) do
    params
    |> Enum.chunk(2)
    |> Enum.reduce(
      model,
      fn([key, value], acc) -> Map.put(acc, String.to_atom(key), value) end
    )
  end
end
