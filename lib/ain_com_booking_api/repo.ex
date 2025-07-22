defmodule AinComBookingApi.Repo do
  use Ecto.Repo,
    adapter: Ecto.Adapters.Postgres,
    otp_app: :ain_com

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, Application.get_env(:ain_com, __MODULE__)[:url])}
  end
end
