defmodule Scoreboard do
  @moduledoc """
  Documentation for Scoreboard.
  """

  import Scoreboard.Parser, only: [parse: 1]

  alias Scoreboard.Scraper.ScheduleScraper
  alias Scoreboard.Scraper.GameScraper
  alias Scoreboard.Calls

  @bad_arg_msg """
  No args given.

  Here are the acceptable args for Scoreboard:

  -t [team], --team [team]  ............... used to set a team, or teams, to search for.

  Example:

  scoreboard -t saints
  scoreboard --team pelicans
  scoreboard --team cavaliers --team lakers -t warriors
"""

  @doc ~S"""
  main/1

  handles case where an empty list of args passed to app.

  ## Example

      iex> Scoreboard.main([])
      "No args given.\n\nHere are the acceptable args for Scoreboard:\n\n-t [team], --team [team]  ............... used to set a team, or teams, to search for.\n\nExample:\n\nscoreboard -t saints\nscoreboard --team pelicans\nscoreboard --team cavaliers --team lakers -t warriors\n"

  """
  @spec main([{atom(), String.t()}]) :: atom()
  def main(args) when length(args) == 0 do
    IO.puts @bad_arg_msg
  end

  @doc ~S"""
  main/1

  handles list of args passed to app.
  """
  def main(args) do
    args
    |> parse()
    |> Enum.map(fn (team) -> Task.async(fn -> Calls.find_all_schedule_urls(team) end) end)
    |> Enum.reduce([], fn (pid, acc) -> acc ++ Task.await(pid) end)
    |> Enum.reduce([],
         fn
           ({:found, urls}, acc) -> acc ++ urls
           ({:not_found, _}, acc) -> acc
         end)
    |> Enum.map(fn (url) -> Task.async(fn -> Calls.get_schedule_page(url) end) end)
    |> Enum.map(&Task.await/1)
    |> GameScraper.find_all_games()
  end
end
