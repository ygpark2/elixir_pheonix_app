defmodule AinComBookingApi.Devices do
  @moduledoc false
  import Ecto.Query

  alias AinComBooking.Repo
  alias AinComBookingApi.Devices.Device

  @token_bytes 32
  @default_ttl_days 90

  def generate_raw_and_hash do
    raw = @token_bytes |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
    hashed = hash(raw)
    {raw, hashed}
  end

  def hash(raw) when is_binary(raw) do
    :sha256 |> :crypto.hash(raw) |> Base.encode16(case: :lower)
  end

  def get_by_raw_token(raw) do
    Repo.get_by(Device, token_hash: hash(raw))
  end

  def get_by_raw_token_ok(raw) do
    case get_by_raw_token(raw) do
      nil -> :error
      device -> {:ok, device}
    end
  end

  def create_device(attrs) do
    %Device{} |> Device.changeset(attrs) |> Repo.insert()
  end

  def create_or_get_device(%{id: user_id}, fingerprint, info \\ %{}) do
    case find_by_user_and_fingerprint(user_id, fingerprint) do
      nil ->
        {raw, token_hash} = generate_raw_and_hash()
        now = DateTime.utc_now()
        expires_at = DateTime.add(now, @default_ttl_days * 24 * 3600, :second)

        attrs = Map.merge(info, %{user_id: user_id, token_hash: token_hash, fingerprint: fingerprint, expires_at: expires_at})

        with {:ok, device} <- create_device(attrs) do
          {:created, raw, device}
        end

      %Device{} = device ->
        {:reused, nil, device}
    end
  end

  def find_by_user_and_fingerprint(user_id, fingerprint) when is_binary(fingerprint) do
    Repo.get_by(Device, user_id: user_id, fingerprint: fingerprint)
  end

  def touch_seen(%Device{} = device, ip \\ nil, ua \\ nil) do
    device
    |> Ecto.Changeset.change(%{
      last_seen_at: DateTime.utc_now(),
      ip: ip || device.ip,
      user_agent: ua || device.user_agent
    })
    |> Repo.update()
  end

  def revoke(%Device{} = device) do
    device
    |> Ecto.Changeset.change(%{revoked_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def rotate_if_expiring(%Device{} = device, threshold_days \\ 7) do
    with %DateTime{} = exp <- device.expires_at,
         true <- Date.diff(exp, Date.utc_today()) <= threshold_days do
      rotate(device)
    else
      _ -> {:skip, device}
    end
  end

  def rotate(%Device{} = device) do
    {raw, token_hash} = generate_raw_and_hash()
    now = DateTime.utc_now()
    new_exp = DateTime.add(now, @default_ttl_days * 24 * 3600, :second)

    {:ok, device} =
      device
      |> Ecto.Changeset.change(%{token_hash: token_hash, expires_at: new_exp})
      |> Repo.update()

    {:ok, raw, device}
  end

  def valid?(%Device{} = device) do
    cond do
      device.revoked_at ->
        {:error, :revoked}

      device.expires_at && DateTime.before?(device.expires_at, DateTime.utc_now()) ->
        {:error, :expired}

      true ->
        :ok
    end
  end
end
