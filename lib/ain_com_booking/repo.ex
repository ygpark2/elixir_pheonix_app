defmodule AinComBooking.Repo do
  use Ecto.Repo,
    adapter:
      Application.compile_env(
        :ain_com_booking,
        [AinComBooking.Repo, :adapter],
        Ecto.Adapters.Postgres
      ),
    otp_app: :ain_com_booking

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    config = Application.get_env(:ain_com_booking, __MODULE__)

    case Keyword.get(config, :url) do
      nil -> {:ok, opts}
      url -> {:ok, Keyword.put(opts, :url, url)}
    end
  end
end
