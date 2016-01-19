defmodule Eredisx.Model.Sequence do
  @moduledoc"""
  Eredisxのvalueを使ってシーケンス番号の制御をする
  """
  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      if opts[:keyformat] && String.contains?(opts[:keyformat], "#id#") do
        def key(id) when is_integer(id) or is_binary(id) do
          String.replace(unquote(opts[:keyformat]), "#id#", to_string(id))
        end

        if opts[:sequence] do
          import Eredisx.Model.Sequence
          @doc """
          次の番号取得
          """
          def next_sequence do
            {:ok, seq} = Eredisx.Api.String.incr(unquote(opts[:sequence]), unquote(if(opts[:repo], do: [repo: opts[:repo]], else: [])))
            seq
          end

          @doc """
          今の番号取得
          """
          def current_sequence do
            {:ok, seq} = Exredis.Api.String.get(unquote(opts[:sequence]), unquote(if(opts[:repo], do: [repo: opts[:repo]], else: [])))
            seq
          end

          def generate_key, do: next_sequence |> key
        end
      end
    end
  end
end
