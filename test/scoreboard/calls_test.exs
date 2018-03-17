defmodule Scoreboard.CallsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Scoreboard.Scraper.ScheduleScraper
  alias Scoreboard.Scraper.GameScraper
  alias Scoreboard.Calls

  describe "Calls" do
    test_cases = [
      {
        "los angeles",
        [
          nfl: {:found, ["/nfl/teams/schedule/LAC/los-angeles-chargers", "/nfl/teams/schedule/LAR/los-angeles-rams"]},
          nba: {:found, ["/nba/teams/schedule/LAC/los-angeles-clippers", "/nba/teams/schedule/LAL/los-angeles-lakers"]},
          nhl: {:found, ["/nhl/teams/schedule/LA/los-angeles-kings"]},
          mlb: {:found, ["/mlb/teams/schedule/LAA/los-angeles-angels", "/mlb/teams/schedule/LAD/los-angeles-dodgers"]}
        ]
      },
      {
        "saints",
        [
          nfl: {:found, ["/nfl/teams/schedule/NO/new-orleans-saints"]},
          nba: {:not_found, nil},
          nhl: {:not_found, nil},
          mlb: {:not_found, nil}
        ]
      },
      {
        "xyz",
        [
          nfl: {:not_found, nil},
          nba: {:not_found, nil},
          nhl: {:not_found, nil},
          mlb: {:not_found, nil}
        ]
      }
    ]

    for {input, result} <- test_cases do
      @input input
      @result result

      test "get_games/1 with #{@input} as input" do
        use_cassette "team/#{@input}" do
          assert(Calls.find_all_schedule_urls(@input) == @result)
        end
      end
    end

    @pro_leagues [:nfl, :nba, :nhl, :mlb]

    for league <- @pro_leagues do
      @league league

      test "get_teams_page/1 with #{@league} as param" do
        use_cassette "#{@league}/teams" do
          {status, %HTTPoison.Response{request_url: url}} = Calls.get_teams_page(@league)

          assert(status == :ok)
          assert(url == result_url(@league))
        end
      end
    end

  end

  defp result_url(league) do
    "https://www.cbssports.com/#{league}/teams"
  end

end
