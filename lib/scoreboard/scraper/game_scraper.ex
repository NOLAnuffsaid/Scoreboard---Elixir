defmodule Scoreboard.Scraper.GameScraper do
  @moduledoc "Retrieves scores for the given teams or cities"

  alias Scoreboard.Scraper
  alias Scoreboard.Calls

  @doc """
  Make async calls for each url given
  """
  @spec find_all_games([{atom, Scraper.response}]) :: [Scraper.game]
  def find_all_games(pages) do
    pages
    |> Enum.map(fn (page) -> Task.async(fn -> GameScraper.get_games(page) end)  end)
    |> Enum.map(&(Task.await / 1))
  end

  @doc "Returns next game data for given schedule page."
  @spec get_games({atom, Scraper.response}) :: {Scraper.game, Scraper.game}
  def get_games({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body
    |> get_schedule_table()
    |> get_game_rows()
    |> find_next_and_last_game()
  end

  @doc "Returns the next game or makes tail recursive call."
  @spec find_next_and_last_game([Floki.html_tree]) :: {Scraper.game, Scraper.game}
  def find_next_and_last_game(rows) do
    has_final_score? =
      fn
        (game) ->
          game
          |> Tuple.to_list()
          |> Enum.any?(&(Regex.match?(~r/\w+\s\d+-\d+/, &1)))
      end

    games = rows
            |> Enum.map(&build_game_tuple/1)
            |> Enum.group_by(
                 fn (game) ->
                   cond do
                     has_final_score?.(game) -> :played
                     true -> :unplayed
                   end
                 end)


    {get_last_played_game(games), get_next_game(games)}
  end

  @spec build_game_tuple(String.t) :: Scraper.game
  def build_game_tuple(game) do
    game
    |> Floki.text(sep: ", ")
    |> String.split(", ")
    |> List.to_tuple()
  end

  @doc "Extract the schedule table from the page"
  @spec get_schedule_table(HTTPoison.Base.body) :: [Floki.html_tree]
  def get_schedule_table(body) do
    body
    |> Floki.find("table.data")
    |> Enum.filter(&is_schedule_table?/1)
  end

  @doc "Returns the table row for the next game within the given schedule page."
  @spec get_game_rows([Floki.html_tree]) :: [Floki.html_tree]
  def get_game_rows([table]) do
    all_games = table
                |> Floki.find("tr")
                |> filter_rows()
                |> Enum.map(&(Floki.text(&1, sep: ", ") |> String.downcase()))

    filtered_games = Enum.filter(all_games, &is_valid_month?/1)

    if(Enum.empty?(filtered_games), do: all_games, else: filtered_games)
  end

  @spec is_schedule_table?(Floki.html_tree) :: boolean
  defp is_schedule_table?(table) do
    table
    |> Floki.find("tr.title")
    |> Floki.text()
    |> String.downcase()
    |> String.contains?("schedule")
  end

  @spec filter_rows([Floki.html_tree]) :: [Floki.html_tree]
  defp filter_rows(rows) do
    rows
    |> Floki.filter_out("tr.label")
    |> Floki.filter_out("tr.title")
    |> Floki.filter_out("tr.subtitle")
  end

  @spec is_valid_month?(String.t) :: boolean
  defp is_valid_month?(game) do
    current_month = Timex.now().month
    this_month = Timex.month_shortname(current_month) |> String.downcase()
    next_month = Timex.month_shortname(current_month + 1) |> String.downcase()
    prev_month = Timex.month_shortname(current_month - 1) |> String.downcase()

    String.starts_with?(game, prev_month) ||
    String.starts_with?(game, this_month) ||
    String.starts_with?(game, next_month)
  end

  @spec get_last_played_game(%{atom => [Scraper.game]}) :: Scraper.game
  defp get_last_played_game(%{:played => played_games}) do
    List.last(played_games)
  end

  @spec get_next_game(%{atom => [Scraper.game]}) :: Scraper.game
  defp get_next_game(%{:unplayed => unplayed_games}) do
    IO.inspect unplayed_games
    unplayed_games
    |> Enum.filter(
      fn
        (game) ->
          not(game
              |> Tuple.to_list()
              |> Enum.any?(fn (field) -> Enum.any?(["postponed", "bye"], &(&1 == field)) end))
      end)
    |> List.first()
  end

  @spec is_before_today?(String.t) :: boolean
  defp is_before_today?(input) do
    [month, str_day] = String.split(input)
    {day, _} = Integer.parse(str_day)
    lowercase_month = String.downcase(month)

    %DateTime{day: d, month: m} = Timex.now()
    lowercase_m = m |> Timex.month_shortname() |> String.downcase()

    cond do
      lowercase_month == lowercase_m && day < d -> true
      Timex.month_to_num(month) < m -> true
      true -> false
    end
  end

end
