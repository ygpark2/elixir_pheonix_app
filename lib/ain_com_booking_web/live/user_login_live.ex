defmodule AinComBookingWeb.UserLoginLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="relative mx-auto w-full max-w-md overflow-hidden rounded-3xl border border-gray-200 bg-white shadow-theme-lg">
      <div class="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-brand-500 via-blue-light-500 to-success-500"></div>
      <div class="px-6 py-8 sm:px-8">
        <div class="mb-7 text-center">
          <p class="inline-flex items-center gap-2 rounded-full border border-brand-100 bg-brand-25 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-brand-700">
            Secure Access
          </p>
          <h1 class="mt-4 text-3xl font-semibold text-gray-900">Log in</h1>
          <p class="mt-2 text-sm text-gray-600">
            Welcome back
          </p>
          <p class="mt-1 text-sm text-gray-600">
            Don’t have an account?
            <a href={~p"/users/register"} class="font-semibold text-brand-600 hover:text-brand-700 hover:underline">
              Sign up
            </a>
          </p>
        </div>

        <form id="login_form" action={~p"/users/log_in"} method="post" class="space-y-5" phx-update="ignore">
          <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />

          <div>
            <label for="login-email" class="mb-1.5 block text-sm font-semibold text-gray-800">Email</label>
            <input
              id="login-email"
              class="block w-full rounded-xl border border-gray-300 bg-white px-3.5 py-2.5 text-gray-900 shadow-theme-xs outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-500/15"
              type="email"
              name="user[email]"
              value={@form[:email].value || ""}
              autocomplete="email"
              required
            />
          </div>

          <div>
            <label for="login-password" class="mb-1.5 block text-sm font-semibold text-gray-800">Password</label>
            <input
              id="login-password"
              class="block w-full rounded-xl border border-gray-300 bg-white px-3.5 py-2.5 text-gray-900 shadow-theme-xs outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-500/15"
              type="password"
              name="user[password]"
              autocomplete="current-password"
              required
            />
          </div>

          <div class="flex items-center justify-between gap-3">
            <label class="inline-flex items-center gap-2 text-sm text-gray-600">
              <input
                type="checkbox"
                name="user[remember_me]"
                value="true"
                class="h-4 w-4 rounded border-gray-300 text-brand-600 focus:ring-brand-500/40"
              />
              <span>Keep me logged in</span>
            </label>
            <a href={~p"/users/reset_password"} class="text-sm font-semibold text-brand-600 hover:text-brand-700 hover:underline">
              Forgot password?
            </a>
          </div>

          <button
            class="w-full rounded-xl bg-gray-900 px-4 py-3 text-sm font-semibold text-white shadow-theme-sm transition hover:bg-brand-700 focus:outline-none focus:ring-4 focus:ring-brand-500/30"
            type="submit"
          >
            Sign in
          </button>
        </form>

        <div class="mt-7">
          <div class="relative">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-gray-200"></div>
            </div>
            <div class="relative flex justify-center text-xs uppercase">
              <span class="bg-white px-2 text-gray-400">Or continue with</span>
            </div>
          </div>
          <div class="mt-4 grid grid-cols-3 gap-2">
            <button type="button" class="rounded-lg border border-gray-200 bg-gray-50 px-2 py-2 text-xs font-medium text-gray-700 transition hover:bg-gray-100">
              Google
            </button>
            <button type="button" class="rounded-lg border border-gray-200 bg-gray-50 px-2 py-2 text-xs font-medium text-gray-700 transition hover:bg-gray-100">
              GitHub
            </button>
            <button type="button" class="rounded-lg border border-gray-200 bg-gray-50 px-2 py-2 text-xs font-medium text-gray-700 transition hover:bg-gray-100">
              SAML
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    {:ok,
     socket
     |> assign(page_title: "Log in")
     |> assign(layout_variant: :auth)
     |> assign(body_class: "bg-gradient-to-br from-blue-light-25 via-gray-25 to-brand-50")
     |> assign(form: form), temporary_assigns: [form: form]}
  end
end
