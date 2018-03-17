defmodule Scoreboard.Scraper do
  @moduledoc "Scrapes data for a given team & purpose."

  @type result :: {:found, [String.t]} |
                  {:not_found, nil} |
                  {:resp_error, any}

  @type response :: HTTPoison.Response.t |
                    HTTPoison.AsyncResponse.t |
                    HTTPoison.Error.t

  @type game :: tuple

end