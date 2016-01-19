defmodule Eredisx.Repo do
  defmacro __using__(opts) do
    quote do
      use Supervisor
      import Eredisx.Client

      @default_eredis_config [
        host: 'localhost',
        port: 6379,
        database: 0,
        reconnect: :no_reconnect,
        max_queue: :infinity
      ]
      @default_poolboy_config [
        pool_size: 5,
        max_overflow: 10
      ]

      @otp_app unquote(Keyword.get(opts, :otp_app))

      def start_link do
        Supervisor.start_link(__MODULE__, [])
      end

      def init(_opts \\ []) do
        IO.inspect(__MODULE__)
        config = Application.get_env(@otp_app, __MODULE__)
        poolboy_option = Eredisx.Repo.parse_poolboy_options(config, @default_poolboy_config)
        eredis_option = Eredisx.Repo.parse_eredis_option(config, @default_eredis_config)

        children = [:poolboy.child_spec(__MODULE__, poolboy_option, eredis_option)]

        supervise(children, strategy: :one_for_one)
      end
    end
  end

  def parse_poolboy_options(config, default_poolboy_config) do
    [
      {:name, {:local, __MODULE__}},
      {:worker_module, :eredis},
      {:size, Keyword.get(config, :pool_size) || Keyword.get(default_poolboy_config, :pool_size)},
      {:max_overflow, Keyword.get(config, :pool_max_overflow) || Keyword.get(default_poolboy_config, :max_overflow)}
    ]
  end

  def parse_eredis_option(config, default_eredis_config) do
    to_chars = fn(v) -> if(is_binary(v), do: String.to_char_list(v), else: v) end
    Enum.map(default_eredis_config, fn({key, default_value}) ->
      {key, to_chars.(Keyword.get(config, key, default_value))}
    end)
  end

end

defmodule Test.Repo do
  use Eredisx.Repo, otp_app: :hoge

  def testpl do
    pipeline do
      query(:set, ~w(hogev fuga))
      query(:incr, "hogev")
      query(:set, ~w(hogev 1000))
      query(:incr, "hogev")
    end
  end
  def testtr do
    transaction do
      query(:set, ~w(hogev 1))
      query(:incr, "hogev")
    end
  end
end
