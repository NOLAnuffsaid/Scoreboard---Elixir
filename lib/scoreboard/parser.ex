defmodule Scoreboard.Parser do
  @moduledoc """
  Parser for args passed to main.
  """

  require Logger

  @type argv :: {OptionParser.parsed(), OptionParser.argv(), OptionParser.errors()}

  @doc """
  parse/1

  Will parse CLI args list.

  ## Example
      iex> Scoreboard.Parser.parse(["-t", "saints"])
      ["saints"]

  """
  @spec parse([String.t()]) :: [String.t()]
  def parse(args) do
    {kw_teams, _, _} = OptionParser.parse(args, strict: [team: :keep], aliases: [t: :team]) |> log_data()

    Keyword.values kw_teams
  end

  @spec log_data(argv) :: argv
  def log_data(args) do
    args
    |> log_unknown_args()
    |> log_invalid_args()
    |> log_valid_teams()
  end

  defp log_unknown_args({_, unknowns, _} = args) when length(unknowns) > 0 do
    output = """
    Unknown args:
    """
    Task.async( fn -> Logger.warn output end)
    args
  end

  defp log_unknown_args(args) do
    args
  end

  defp log_invalid_args({_, _, invalid} = args) when length(invalid) > 0 do
    output = invalid
             |> Enum.map(fn ({switch, _}) -> "#{switch}" end)
             |> Enum.join("\n")

    Task.async(fn -> Logger.error("Invalid args:\n" <> output) end)
    args
  end

  defp log_invalid_args(args) do
    args
  end

  defp log_valid_teams({switches, _, _} = args) when length(switches) > 0 do
    teams = switches
            |> Keyword.values()
            |> Enum.join("\n")
    output = "Teams requested:\n#{teams}\n\n"
    Task.async(fn -> Logger.info(output) end)
    args
  end

  defp log_valid_teams(args) do
    args
  end
end
