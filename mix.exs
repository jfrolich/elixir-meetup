defmodule Meetup.MixProject do
  use Mix.Project

  def project do
    [
      app: :meetup,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Meetup]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:faker_elixir_octopus, "~> 1.0.0", only: [:dev, :test]},
      {:defer, path: "../defer"},
      {:dataloader, path: "../dataloader"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
