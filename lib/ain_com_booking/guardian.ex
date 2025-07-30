defmodule AinComBooking.Guardian do
  @moduledoc false
  use Guardian, otp_app: :ain_com_booking

  alias AinComBooking.Accounts

  # user를 토큰으로 인코딩할 때 식별자로 사용할 값을 반환합니다.
  @impl Guardian
  def subject_for_token(%Accounts.User{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  # 토큰을 디코딩한 후 "sub" 클레임을 이용해 실제 리소스를 로드합니다.
  @impl Guardian
  def resource_from_claims(%{"sub" => id}) do
    user = Accounts.get_user!(id)
    {:ok, user}
  rescue
    Ecto.NoResultsError -> {:error, :resource_not_found}
  end
end
