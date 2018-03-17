defmodule Scoreboard.Calls do
  @moduledoc "Maintains all calls to external data sources."

  alias Scoreboard.Scraper
  alias Scoreboard.Scraper.ScheduleScraper
  alias Scoreboard.Scraper.GameScraper

  @pro_leagues [:nfl, :nba, :nhl, :mlb]
  @host "https://www.cbssports.com"

  @doc """
  Makes async call for each team given
  """
  @spec find_all_schedule_urls(String.t) :: [{atom, Scraper.result}]
  def find_all_schedule_urls(team) do
    for league <- @pro_leagues, do: {league, find_schedule_urls(league, team)}
  end

  @doc """
  Makes async call for each team given
  """
  @spec find_schedule_urls(atom, String.t) :: Scraper.result
  def find_schedule_urls(league, team) do
    league
    |> Atom.to_string()
    |> get_teams_page()
    |> ScheduleScraper.find_schedule(team)
  end

  @doc """
  Retrieves pro league's teams page
  """
  @spec get_teams_page(String.t) :: {atom, Scraper.response}
  def get_teams_page(league) do
    HTTPoison.get("#{@host}/#{league}/teams")
  end

  @doc """
  Retrieves team specific schedule page
  """
  @spec get_schedule_page(String.t) :: {atom, Scraper.response}
  def get_schedule_page(url) do
    HTTPoison.get("#{@host}#{url}")
  end

end
