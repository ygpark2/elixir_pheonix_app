# lib/ain_com_booking_api/auth_pipeline.ex
defmodule AinComBookingApi.AuthPipeline do
  @moduledoc false
  use Guardian.Plug.Pipeline,
    otp_app: :ain_com_booking,
    module: AinComBookingApi.Guardian,
    error_handler: AinComBookingApi.AuthErrorHandler

  # Authorization: Bearer <jwt>
  plug(Guardian.Plug.VerifyHeader,
    realm: "Bearer",
    header_name: "authorization",
    # 저장될 키 이름
    key: :auth
  )

  # 유효한 JWT인지 확인
  plug(Guardian.Plug.EnsureAuthenticated, key: :auth)
  # 토큰에서 사용자 정보를 로드
  plug(Guardian.Plug.LoadResource, key: :auth)
end
