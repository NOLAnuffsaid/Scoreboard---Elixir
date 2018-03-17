defmodule Scoreboard.Scraper.ScheduleScraper do
  @moduledoc "Retrieves schedules for the given teams or cities"

  alias Scoreboard.Scraper

  @doc "Returns the schedule urls for the given team or city."
  @spec find_schedule({atom, Scraper.response}, String.t) :: Scraper.result
  def find_schedule({:ok, %HTTPoison.Response{body: body, status_code: 200}}, team) do
    schedule_url = body
                   |> Floki.attribute("a", "href")
                   |> Enum.filter(&(String.contains?(&1, "schedule")))
                   |> Enum.filter(
                        fn (url) -> String.split(team)
                                    |> Enum.all?(
                                         fn (part_subj) -> String.contains?(url, part_subj)
                                         end)
                        end)

    if(Enum.empty?(schedule_url), do: {:not_found, nil}, else: {:found, schedule_url})
  end

  def find_schedule({:error, %HTTPoison.Error{reason: reason}}, _team) do
    {:resp_error, reason}
  end
end
