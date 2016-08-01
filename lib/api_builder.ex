defmodule Eredisx.ApiBuilder do
  defmacro defapis(commands), do: generate_apis(:default, commands)
  defmacro defapis(repo, commands), do: generate_apis(repo, commands)

  def generate_apis(default_repo, commands) do
    for {api, args, api_options, document, version} <- parse_commands(commands) do
      {operator, _, [{atomed, _, _}, default_argument]} = Code.string_to_quoted!("options \\\\ []")
      option_arg = {operator, [], [{atomed, [], __MODULE__}, default_argument]}

      options_help = Enum.reduce(api_options, ["## options:"], fn([name, capture, params], acc) ->
        params = elem(Enum.unzip(params), 0) |> Enum.join(", ")
        params = if(params == "", do: capture, else: params)
        acc ++ List.wrap("- **#{name}:** #{params}")
      end)

      quote do
        @doc """
        #{unquote(document)}

        #{unquote(Enum.join(options_help, "\n"))}

        @#{unquote(version)}
        """
        def unquote(api)(unquote_splicing(args ++ List.wrap(option_arg))) do
          repo = Keyword.get(options, :repo) || unquote(default_repo || :default)
          IO.inspect [__MODULE__, repo]
          options = Keyword.drop(options, [:repo])

          except_options = unquote(api_options)
          option_values = Enum.filter_map(
            except_options,
            fn([key, _, _]) -> Keyword.has_key?(options, key) end,
            fn([key, capture, params]) ->
              opts = Keyword.get(options, key)
              if opts != nil && params != [] && length(List.wrap(opts)) != length(params) do
                raise ArgumentError, message: "options/#{key}, argument does not match."
              end

              if params == [], do: [opts], else: [capture, opts]
            end
          )

          Eredisx.Client.query(unquote(to_string(api)), ([unquote_splicing(args)] ++ option_values) |> List.flatten, repo: repo)
        end
      end
    end
  end

  defp parse_commands(commands) do
    String.strip(commands)
    |> String.split("\n\n")
    |> Enum.map(fn(command) -> String.split(command, "\n") end)
    |> Enum.map(fn([command, document, version]) ->
      {api, args, options} = parse_command(command)
      {
        String.downcase(api) |> String.to_atom,
        quote_args(args),
        options ++ [[:repo, "If you want to specify a non-default connection of redis, set the name of the connection of redis. ", []]],
        document,
        version
      }
    end)
  end

  # ドキュメントを解析してApi名、引数、オプションに分解する
  defp parse_command(source) do
    source = merge_dot_option(source)
    options = pick_options(source)
    [api|args] = Regex.replace(~r/\[.+\]/, source, "") |> String.strip |> String.split(" ")
    {api, args, parse_options(options)}
  end

  defp escape_special_charactors(source) do
    String.replace(source, "-", "_")
    |> String.downcase
    |> String.replace("|", "_or_")
  end

  # ex: `key [key ...] => keys`
  # ex: `score member [score member ...] => score_with_members`
  defp merge_dot_option(source) do
    Regex.replace(
      ~r/([\w\s]+?)\s+?\[\1\s+\.\.\.\]/,
      source,
      fn(_, capture) -> (String.split(capture, " ") |> Enum.join("_with_")) <> "s" end
    )
  end

  # ネストパターンは無視して最上位だけ拾う
  defp pick_options(source) do
    Regex.scan(~r/\[((?R)|[^\[]|[^\]])+\]/U, source)
    |> Enum.map(
      fn([arg, _]) ->
        arg
        |> String.slice(1..-2)
        |> String.replace(~r/\[.+\]/, "")
        |> String.strip
        |> String.split(" ")
      end)
  end

  defp parse_options(options) do
    Enum.map(
      options,
      fn([name|values]) ->
        {capture, value} = case Regex.run(~r/(\w+?)_with_(\w+)/, name) do
          [_, cap, param] -> {cap, param}
          _ -> {name, nil}
        end
        # 2段だけネストパラメータを展開する
        params = Enum.map(List.wrap(value) ++ values, fn(value) ->
          case Regex.run(~r/(\w+?)_with_(\w+)/, value) do
            [_, prefix, param] -> {param, prefix}
            _ -> {value, nil}
          end
        end)
        [String.to_atom(escape_special_charactors(name)), capture, params]
      end
    )
  end

  defp quote_args(args) do
    args
    |> List.wrap
    |> Enum.filter_map(
        fn(arg) -> String.length(arg) > 1 end,
        fn(arg) -> {escape_special_charactors(arg) |> String.to_atom, [], __MODULE__} end
      )
  end
end
