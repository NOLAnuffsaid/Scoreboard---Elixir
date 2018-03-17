defmodule Scoreboard.Mixfile do
  use Mix.Project

  def project do
    [
      app: :scoreboard,
      version: "0.0.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      escript: escript(),
      deps: deps(),
      preferred_cli_env: [vcr: :test, "vcr.delete": :test, "vcr.check": :test, "vcr.show": :test],
      dialyzer: [
                  plt_add_deps: :apps_direct,
                  paths: ["_build/dev/lib/scoreboard"],
                  ignore_warnings: "dialyzer.ignore-warnings"
                ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def applications do
    [
      applications: applications(Mix.env),
    ]
  end

  defp applications(:dev) do
    applications([]) ++ [:remix]
  end

  defp applications(_all) do
    [:logger, :httpoison, :timex]
  end

  defp escript do
    [main_module: Scoreboard]
  end

  defp deps() do
    [
      {:floki, "~> 0.20.0"},
      {:httpoison, "~> 1.0.0", override: true},
      {:timex, "~> 3.2.1"},
      {:remix, "~> 0.0.2", only: :dev},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:exvcr, "~> 0.8", only: :test}
    ]
  end
end
