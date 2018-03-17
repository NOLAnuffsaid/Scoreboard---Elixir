defmodule Scoreboard.Scraper.ScheduleScraperTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Scoreboard.Scraper.ScheduleScraper

  describe "ScheduleScraper" do
    test_cases = [{"one team", "saints", {:found, ["/nfl/teams/schedule/NO/new-orleans-saints"]}},
      {"multiple teams", "los angeles", {:found, ["/nfl/teams/schedule/LAC/los-angeles-chargers", "/nfl/teams/schedule/LAR/los-angeles-rams"]}},
      {"unknown team", "xyz", {:not_found, nil}}]

    for {scenario, team, result} <- test_cases do
      @scenario scenario
      @team team
      @result result

      test "find_schedule/2 #{@scenario}" do
        use_cassette "nfl/teams" do
          page = HTTPoison.get("https://www.cbssports.com/nfl/teams")
          assert(ScheduleScraper.find_schedule(page, @team) == @result)
        end
      end
    end
  end

end
