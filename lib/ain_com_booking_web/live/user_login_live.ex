defmodule AinComBookingWeb.UserLoginLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="ant-card ant-card-bordered">
      <div class="ant-card-body">
        <div class="ant-typography" style="text-align:center; margin-bottom: 8px;">
          <h2 class="ant-typography" style="margin:0; font-weight:600;">Welcome back</h2>
          <div class="ant-typography" style="color:#667085;">
            Don’t have an account?
            <a class="ant-typography" href={~p"/users/register"}>Sign up</a>
          </div>
        </div>

        <form id="login_form" action={~p"/users/log_in"} method="post" class="ant-form ant-form-vertical" phx-update="ignore">
          <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />

          <!-- Email -->
          <div class="ant-form-item">
            <label class="ant-form-item-required ant-form-item-label"><span>Email</span></label>
            <div class="ant-form-item-control-input">
              <div class="ant-form-item-control-input-content">
                <input class="ant-input" type="email" name="user[email]" value={@form[:email].value} required />
              </div>
            </div>
          </div>

          <!-- Password -->
          <div class="ant-form-item">
            <label class="ant-form-item-required ant-form-item-label"><span>Password</span></label>
            <div class="ant-form-item-control-input">
              <div class="ant-form-item-control-input-content">
                <input class="ant-input" type="password" name="user[password]" required />
              </div>
            </div>
          </div>

          <!-- Remember + Forgot -->
          <div class="ant-form-item">
            <div class="ant-space" style="display:flex; justify-content:space-between; align-items:center;">
              <label class="ant-checkbox-wrapper" style="display:flex; align-items:center; gap:8px;">
                <input type="checkbox" name="user[remember_me]" value="true" />
                <span>Keep me logged in</span>
              </label>
              <a class="ant-typography" href={~p"/users/reset_password"}>Forgot password?</a>
            </div>
          </div>

          <!-- Submit -->
          <div class="ant-form-item">
            <button class="ant-btn ant-btn-primary ant-btn-lg" type="submit" style="width:100%;">
              <span>Sign in</span>
            </button>
          </div>
        </form>

        <!-- Social row (optional) -->
        <div class="ant-divider" role="separator"><span class="ant-divider-inner-text">Or continue with</span></div>
        <div class="ant-space" style="display:grid; grid-template-columns:repeat(3,1fr); gap:8px;">
          <button type="button" class="ant-btn" style="width:100%;">Google</button>
          <button type="button" class="ant-btn" style="width:100%;">GitHub</button>
          <button type="button" class="ant-btn" style="width:100%;">SAML</button>
        </div>
      </div>
    </div>

        <!--
    <div class="mx-auto max-w-sm p-4">
      <.header class="text-center">
        Log in to account
        <:subtitle>
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Logging in..." class="w-full">
            Log in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    -->
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    {:ok,
     socket
     |> assign(page_title: "Log in")
     |> assign(layout_variant: :auth)
     |> assign(body_class: "bg-gray-50")
     |> assign(form: form), temporary_assigns: [form: form]}

    # {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
