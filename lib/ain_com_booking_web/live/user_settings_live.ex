defmodule AinComBookingWeb.UserSettingsLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  alias AinComBooking.Accounts

  def render(assigns) do
    ~H"""
    <style id="settings-feed-layout-style">
      body > main[role="main"].p-6 {
        padding: 0;
      }

      body > main[role="main"].p-6 > .mb-4:empty {
        display: none;
        margin: 0;
      }

      .user-menu {
        display: none;
      }
    </style>

    <div class="min-h-screen bg-[#f7f9f9] font-outfit text-slate-900">
      <div id="settings-feed-layout" class="mx-auto grid max-w-7xl items-stretch gap-0 lg:grid-cols-[220px_minmax(0,1fr)_320px]">
        <aside class="hidden h-full border-r border-slate-200 bg-slate-50 lg:block">
          <div class="flex h-full flex-col px-4 py-4">
            <div class="space-y-4">
              <div class="rounded-3xl border border-slate-200 bg-white px-4 py-5 shadow-sm">
                <div class="text-xs font-semibold uppercase tracking-[0.22em] text-brand-600">Account</div>
                <div class="mt-3 text-2xl font-semibold tracking-tight text-slate-950">Settings</div>
                <p class="mt-2 text-sm leading-6 text-slate-500">
                  Manage profile visibility, email updates, and password changes in the same centered rail as the feed.
                </p>
              </div>

              <nav class="space-y-2 rounded-3xl border border-slate-200 bg-white p-3 shadow-sm">
                <.link
                  navigate={~p"/feed"}
                  class="flex items-center gap-3 rounded-2xl px-4 py-3 text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                >
                  <.icon name="hero-home-solid" class="h-5 w-5" />
                  <span class="text-sm font-semibold">Back To Feed</span>
                </.link>
                <.link
                  navigate={~p"/profiles/#{@current_user.id}"}
                  class="flex items-center gap-3 rounded-2xl px-4 py-3 text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                >
                  <.icon name="hero-user-circle" class="h-5 w-5" />
                  <span class="text-sm font-semibold">My Profile</span>
                </.link>
              </nav>
            </div>

            <div class="mt-auto rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
              <div class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Signed In</div>
              <div class="mt-2 text-sm font-semibold text-slate-950"><%= @current_user.name || "User" %></div>
              <div class="mt-1 break-all text-xs text-slate-400"><%= @current_email %></div>
            </div>
          </div>
        </aside>

        <main class="min-w-0 border-x border-slate-200 bg-white">
          <div class="sticky top-0 z-10 border-b border-slate-200 bg-white/90 backdrop-blur">
            <div class="px-6 py-4">
              <p class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Account Settings</p>
              <h1 class="mt-2 text-2xl font-semibold tracking-tight text-slate-950">Manage your account</h1>
              <p class="mt-2 text-sm leading-6 text-slate-500">
                Update profile information, change your email address, and rotate your password.
              </p>
            </div>
          </div>

          <section class="border-b border-slate-200 px-6 py-6">
            <div class="mb-5">
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">Profile</h2>
              <p class="mt-1 text-sm text-slate-500">This controls how you appear in booking and social flows.</p>
            </div>

            <.simple_form
              for={@profile_form}
              id="profile_form"
              phx-submit="update_profile"
              phx-change="validate_profile"
            >
              <.input
                name="profile_email"
                type="email"
                label="Email"
                value={@current_email}
                disabled
              />
              <.input field={@profile_form[:name]} type="text" label="Name" required />
              <.input field={@profile_form[:phone]} type="text" label="Phone" required />
              <.input field={@profile_form[:address]} type="text" label="Address" required />
              <.input
                field={@profile_form[:feed_visibility]}
                type="select"
                label="Feed visibility"
                options={feed_visibility_options()}
              />
              <:actions>
                <.button phx-disable-with="Saving...">Update Profile</.button>
              </:actions>
            </.simple_form>
          </section>

          <section class="border-b border-slate-200 px-6 py-6">
            <div class="mb-5">
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">Email</h2>
              <p class="mt-1 text-sm text-slate-500">Changing your email requires the current password.</p>
            </div>

            <.simple_form
              for={@email_form}
              id="email_form"
              phx-submit="update_email"
              phx-change="validate_email"
            >
              <.input field={@email_form[:email]} type="email" label="Email" required />
              <.input
                field={@email_form[:current_password]}
                name="current_password"
                id="current_password_for_email"
                type="password"
                label="Current password"
                value={@email_form_current_password}
                required
              />
              <:actions>
                <.button phx-disable-with="Changing...">Change Email</.button>
              </:actions>
            </.simple_form>
          </section>

          <section class="px-6 py-6">
            <div class="mb-5">
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">Password</h2>
              <p class="mt-1 text-sm text-slate-500">Use a new password to keep your account secure.</p>
            </div>

            <.simple_form
              for={@password_form}
              id="password_form"
              action={~p"/users/log_in?_action=password_updated"}
              method="post"
              phx-change="validate_password"
              phx-submit="update_password"
              phx-trigger-action={@trigger_submit}
            >
              <input
                name={@password_form[:email].name}
                type="hidden"
                id="hidden_user_email"
                value={@current_email}
              />
              <.input field={@password_form[:password]} type="password" label="New password" required />
              <.input
                field={@password_form[:password_confirmation]}
                type="password"
                label="Confirm new password"
              />
              <.input
                field={@password_form[:current_password]}
                name="current_password"
                type="password"
                label="Current password"
                id="current_password_for_password"
                value={@current_password}
                required
              />
              <:actions>
                <.button phx-disable-with="Changing...">Change Password</.button>
              </:actions>
            </.simple_form>
          </section>
        </main>

        <aside class="hidden h-full border-l border-slate-200 bg-slate-50 lg:block">
          <div class="h-full px-4 py-4">
            <div class="space-y-4">
              <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
                <h2 class="text-lg font-semibold tracking-tight text-slate-950">Visibility Guide</h2>
                <div class="mt-4 space-y-2">
                  <div class="rounded-2xl bg-slate-50 px-3 py-3 text-sm text-slate-600">
                    `Public`: anyone in-app can see your shared booking posts.
                  </div>
                  <div class="rounded-2xl bg-slate-50 px-3 py-3 text-sm text-slate-600">
                    `Followers only`: your followers unlock additional availability.
                  </div>
                  <div class="rounded-2xl bg-slate-50 px-3 py-3 text-sm text-slate-600">
                    `Link only` and `Private`: hidden from the main social timeline.
                  </div>
                </div>
              </div>

              <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
                <h2 class="text-lg font-semibold tracking-tight text-slate-950">Security Tips</h2>
                <ul class="mt-4 space-y-2 text-sm leading-6 text-slate-500">
                  <li class="rounded-2xl bg-slate-50 px-3 py-3">Use a unique password with at least 12 characters.</li>
                  <li class="rounded-2xl bg-slate-50 px-3 py-3">Confirm email changes from the inbox of the new address.</li>
                  <li class="rounded-2xl bg-slate-50 px-3 py-3">Keep your public profile details accurate before sharing availability.</li>
                </ul>
              </div>
            </div>
          </div>
        </aside>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    profile_changeset = Accounts.change_user_profile(user)
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(page_title: "User Settings")
      |> assign(layout_variant: :auth)
      |> assign(body_class: "bg-gray-50")
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    profile_form =
      socket.assigns.current_user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", %{"user" => user_params}, socket) do
    case Accounts.update_user_profile(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        profile_form =
          user
          |> Accounts.change_user_profile()
          |> to_form()

        socket =
          socket
          |> assign(:current_user, user)
          |> assign(:profile_form, profile_form)
          |> put_flash(:info, "Profile updated successfully.")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(changeset))}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  defp feed_visibility_options do
    [
      {"Public", :public},
      {"Followers only", :followers},
      {"Link only", :link},
      {"Private", :private}
    ]
  end
end
