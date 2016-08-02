defmodule Eredisx.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :eredisx,
     version: @version,
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :eredis, :poolboy]]
  end

  defp deps do
    [
      {:eredis,  "~> 1.0.8"},
      {:poolboy, "~> 1.5"},
      {:ex_doc, "~> 0.10", only: :docs},
      {:earmark, "~> 0.1", only: :docs}
    ]
  end
end
