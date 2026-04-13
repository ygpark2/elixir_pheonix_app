defmodule AinComBookingWeb.SocialFeedLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  alias AinComBooking.Accounts
  alias AinComBooking.Social
  alias Phoenix.LiveView.JS

  @time_zone_options [
    {"Asia/Seoul", "Asia/Seoul"},
    {"Asia/Tokyo", "Asia/Tokyo"},
    {"UTC", "UTC"},
    {"+09:00", "+09:00"}
  ]

  def render(assigns) do
    ~H"""
    <style id="feed-user-menu-style">
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
      <div class="mx-auto grid max-w-7xl items-stretch gap-0 lg:grid-cols-[220px_minmax(0,1fr)_320px]">
        <aside class="hidden h-full border-r border-slate-200 bg-slate-50 lg:block">
          <div class="flex h-full flex-col px-4 py-4">
            <div class="space-y-4">
              <div class="rounded-3xl border border-slate-200 bg-white px-4 py-5 shadow-sm">
                <div class="text-xs font-semibold uppercase tracking-[0.22em] text-brand-600">Booking Social</div>
                <div class="mt-3 text-2xl font-semibold tracking-tight text-slate-950"><%= scope_name(@scope) %></div>
                <p class="mt-2 text-sm leading-6 text-slate-500">
                  <%= scope_description(@scope) %>
                </p>
              </div>

              <nav class="space-y-2 rounded-3xl border border-slate-200 bg-white p-3 shadow-sm">
                <.link
                  :for={item <- nav_items()}
                  patch={scope_path(item.scope)}
                  class={nav_item_class(@scope, item.scope)}
                >
                  <.icon name={item.icon} class="h-5 w-5" />
                  <span class="text-sm font-semibold"><%= item.label %></span>
                </.link>

                <div class="mx-1 border-t border-slate-200 pt-2">
                  <.link
                    navigate={~p"/services"}
                    class="flex items-center gap-3 rounded-2xl px-4 py-3 text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                  >
                    <.icon name="hero-briefcase" class="h-5 w-5" />
                    <span class="text-sm font-semibold">Services</span>
                  </.link>
                  <.link
                    navigate={~p"/slots"}
                    class="flex items-center gap-3 rounded-2xl px-4 py-3 text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                  >
                    <.icon name="hero-calendar-days" class="h-5 w-5" />
                    <span class="text-sm font-semibold">Slots</span>
                  </.link>
                  <.link
                    navigate={~p"/resources"}
                    class="flex items-center gap-3 rounded-2xl px-4 py-3 text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                  >
                    <.icon name="hero-cube" class="h-5 w-5" />
                    <span class="text-sm font-semibold">Resources</span>
                  </.link>
                </div>
              </nav>

              <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
                <div class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Pulse</div>
                <dl class="mt-3 space-y-3">
                  <div class="flex items-center justify-between">
                    <dt class="text-sm text-slate-500">Visible shares</dt>
                    <dd class="text-sm font-semibold text-slate-900"><%= @stats.visible_shares %></dd>
                  </div>
                  <div class="flex items-center justify-between">
                    <dt class="text-sm text-slate-500">Open slots</dt>
                    <dd class="text-sm font-semibold text-slate-900"><%= @stats.bookable_slots %></dd>
                  </div>
                  <div class="flex items-center justify-between">
                    <dt class="text-sm text-slate-500">Followers only</dt>
                    <dd class="text-sm font-semibold text-slate-900"><%= @stats.followers_only_shares %></dd>
                  </div>
                </dl>
              </div>
            </div>

            <section id="feed-account-menu" class="mt-auto rounded-3xl border border-slate-200 bg-white p-3 shadow-sm">
              <div class="flex items-center gap-3 rounded-2xl px-2 py-2">
                <div class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-slate-950 text-sm font-semibold text-white">
                  <%= initials(@current_user.name) %>
                </div>

                <div class="min-w-0 flex-1">
                  <div class="truncate text-sm font-semibold text-slate-950"><%= @current_user.name || "User" %></div>
                  <div class="truncate text-xs text-slate-400"><%= @current_user.email %></div>
                </div>
              </div>

              <div class="mt-2 space-y-1">
                <.link
                  navigate={~p"/users/settings"}
                  class="flex items-center gap-3 rounded-2xl px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                >
                  <.icon name="hero-cog-6-tooth" class="h-5 w-5" />
                  <span>Settings</span>
                </.link>

                <.link
                  href={~p"/users/log_out"}
                  method="delete"
                  class="flex items-center gap-3 rounded-2xl px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                >
                  <.icon name="hero-arrow-left-on-rectangle" class="h-5 w-5" />
                  <span>Log out</span>
                </.link>
              </div>
            </section>
          </div>
        </aside>

        <main class="min-w-0 border-x border-slate-200 bg-white">
          <div class="sticky top-0 z-10 border-b border-slate-200 bg-white/90 backdrop-blur">
            <div class="flex items-center justify-between px-4 py-3">
              <div>
                <h1 class="text-xl font-semibold tracking-tight text-slate-950">Social Availability Feed</h1>
                <p class="mt-0.5 text-xs font-medium uppercase tracking-[0.18em] text-slate-400"><%= scope_name(@scope) %></p>
              </div>
              <button
                type="button"
                phx-click="open_post_modal"
                class="inline-flex items-center gap-2 rounded-full bg-slate-950 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800"
              >
                <.icon name="hero-pencil-square" class="h-4 w-4" />
                <span>Post</span>
              </button>
            </div>
          </div>

          <section :if={@scope == :bookings}>
            <p :if={@booking_activity == []} class="px-6 py-12 text-center text-sm text-slate-500">
              You have not booked any shared slots yet.
            </p>

            <article
              :for={booking <- @booking_activity}
              id={"booking-activity-#{booking.id}"}
              class="border-b border-slate-200 px-4 py-4 transition hover:bg-slate-50"
            >
              <div class="flex gap-3">
                <div class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-emerald-50 text-sm font-semibold text-emerald-700 ring-1 ring-emerald-100">
                  <.icon name="hero-check-circle-solid" class="h-5 w-5" />
                </div>

                <div class="min-w-0 flex-1">
                  <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
                    <span class="text-sm font-semibold text-slate-950"><%= booking.customer_name %></span>
                    <span class="text-sm text-slate-400">·</span>
                    <span class="text-sm text-slate-400"><%= relative_posted_at(booking.inserted_at) %></span>
                    <span class={["ml-auto rounded-full px-2.5 py-1 text-[11px] font-semibold", booking_status_class(booking.status)]}>
                      <%= booking_status_label(booking.status) %>
                    </span>
                  </div>

                  <div class="mt-2 space-y-3">
                    <div class="rounded-2xl border border-slate-200 bg-white px-4 py-3">
                      <div class="text-sm font-semibold text-slate-950"><%= booking_title(booking) %></div>
                      <p class="mt-1 text-sm leading-6 text-slate-600"><%= booking_slot_summary(booking) %></p>
                    </div>

                    <div class="flex flex-wrap items-center gap-3 text-xs font-medium text-slate-400">
                      <span class="inline-flex items-center gap-1">
                        <.icon name="hero-banknotes" class="h-4 w-4" />
                        <%= booking_price(booking) %>
                      </span>
                      <span class="inline-flex items-center gap-1">
                        <.icon name="hero-calendar-days" class="h-4 w-4" />
                        Booked from shared availability
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </article>
          </section>

          <section :if={@scope != :bookings}>
            <p :if={@entries == []} class="px-6 py-12 text-center text-sm text-slate-500">
              No shared booking posts yet.
            </p>

            <article
              :for={entry <- @entries}
              id={"feed-post-#{entry.post.id}"}
              class="border-b border-slate-200 px-4 py-4 transition hover:bg-slate-50"
            >
              <div class="flex gap-3">
                <div class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-brand-50 text-sm font-semibold text-brand-700 ring-1 ring-brand-100">
                  <%= initials(entry.post.user.name) %>
                </div>

                <div class="min-w-0 flex-1">
                  <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
                    <span class="text-sm font-semibold text-slate-950"><%= entry.post.user.name %></span>
                    <span class="text-sm text-slate-400">@bookable-share</span>
                    <span class="text-sm text-slate-400">·</span>
                    <span class="text-sm text-slate-400"><%= relative_posted_at(entry.post.inserted_at) %></span>
                    <span class={["ml-auto rounded-full px-2.5 py-1 text-[11px] font-semibold", visibility_badge_class(entry.post.visibility)]}>
                      <%= visibility_label(entry.post.visibility) %>
                    </span>
                  </div>

                  <div class="mt-1 space-y-3">
                    <p class="whitespace-pre-line text-[15px] leading-6 text-slate-800"><%= entry.post.body %></p>

                    <div class="overflow-hidden rounded-2xl border border-slate-200 bg-white">
                      <div class="border-b border-slate-200 bg-slate-50 px-4 py-3">
                        <div class="flex items-center justify-between gap-3">
                          <div class="text-sm font-semibold text-slate-900">This Week's Booking Window</div>
                          <span class="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700">
                            <%= entry.slot_count %> open
                          </span>
                        </div>
                        <p class="mt-2 text-sm leading-6 text-slate-600"><%= entry.post.booking_note %></p>
                      </div>

                      <div class="space-y-3 px-4 py-3">
                        <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400"><%= target_summary(entry.post) %></div>
                        <div class="rounded-2xl bg-slate-50 px-3 py-2 text-xs leading-5 text-brand-700">
                          <span class="font-semibold text-slate-500">Share link</span><br />
                          <%= share_path(entry.post.id) %>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div class="mt-3 flex flex-wrap items-center justify-between gap-3 text-sm">
                    <div class="flex flex-wrap items-center gap-2">
                      <.link
                        patch={modal_path(entry.post.id, @scope)}
                        class="inline-flex items-center gap-2 rounded-full px-3 py-2 font-medium text-slate-500 transition hover:bg-brand-50 hover:text-brand-700"
                      >
                        <.icon name="hero-calendar-days" class="h-4 w-4" />
                        <span>View Weekly Slots</span>
                      </.link>
                      <.link
                        navigate={share_path(entry.post.id)}
                        class="inline-flex items-center gap-2 rounded-full px-3 py-2 font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                      >
                        <.icon name="hero-arrow-top-right-on-square" class="h-4 w-4" />
                        <span>Open shareable page</span>
                      </.link>
                    </div>

                    <div class="flex items-center gap-4 text-xs font-medium text-slate-400">
                      <span class="inline-flex items-center gap-1">
                        <.icon name="hero-users" class="h-4 w-4" />
                        <%= visibility_label(entry.post.visibility) %>
                      </span>
                      <span class="inline-flex items-center gap-1">
                        <.icon name="hero-clock" class="h-4 w-4" />
                        7 day window
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </article>
          </section>

          <section id="feed-account-menu-mobile" class="border-t border-slate-200 px-4 py-4 lg:hidden">
            <div class="rounded-3xl border border-slate-200 bg-slate-50 p-3">
              <div class="flex items-center gap-3 rounded-2xl bg-white px-3 py-3 ring-1 ring-slate-200">
                <div class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-slate-950 text-sm font-semibold text-white">
                  <%= initials(@current_user.name) %>
                </div>

                <div class="min-w-0 flex-1">
                  <div class="truncate text-sm font-semibold text-slate-950"><%= @current_user.name || "User" %></div>
                  <div class="truncate text-xs text-slate-400"><%= @current_user.email %></div>
                </div>
              </div>

              <div class="mt-3 grid gap-2 sm:grid-cols-2">
                <.link
                  navigate={~p"/users/settings"}
                  class="inline-flex items-center justify-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-100"
                >
                  <.icon name="hero-cog-6-tooth" class="h-4 w-4" />
                  <span>Settings</span>
                </.link>

                <.link
                  href={~p"/users/log_out"}
                  method="delete"
                  class="inline-flex items-center justify-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-100"
                >
                  <.icon name="hero-arrow-left-on-rectangle" class="h-4 w-4" />
                  <span>Log out</span>
                </.link>
              </div>
            </div>
          </section>
        </main>

        <aside class="hidden h-full border-l border-slate-200 bg-slate-50 lg:block">
          <div class="h-full px-4 py-4">
            <div class="space-y-4">
            <div :if={admin?(@current_user)} class="rounded-3xl border border-brand-200 bg-brand-25 p-4 shadow-sm">
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">Admin Access</h2>
              <p class="mt-2 text-sm leading-6 text-slate-600">
                Open the platform dashboard to review users, follows, and system activity.
              </p>

              <.link
                href={~p"/admin"}
                class="mt-4 inline-flex items-center gap-2 rounded-full bg-slate-950 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800"
              >
                <.icon name="hero-shield-check" class="h-4 w-4" />
                <span>Open Admin Dashboard</span>
              </.link>
            </div>

            <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">Suggested Accounts</h2>
              <p class="mt-2 text-sm leading-6 text-slate-500">
                Follow people here and their shared availability immediately appears in your social booking flow.
              </p>

              <p :if={@suggested_users == []} class="mt-4 text-sm text-slate-500">
                No suggestions right now.
              </p>

              <div :if={@suggested_users != []} class="mt-4 space-y-3">
                <div :for={user <- @suggested_users} class="rounded-2xl bg-slate-50 px-3 py-3">
                  <div class="flex items-start gap-3">
                    <.link navigate={profile_path(user.id)} class="flex min-w-0 flex-1 items-start gap-3 rounded-2xl pr-2 transition hover:bg-white/80">
                      <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-brand-50 text-xs font-semibold text-brand-700 ring-1 ring-brand-100">
                        <%= initials(user.name) %>
                      </div>

                      <div class="min-w-0 flex-1">
                        <div class="truncate text-sm font-semibold text-slate-900"><%= user.name %></div>
                        <div class="mt-1 text-xs text-slate-500"><%= suggested_user_subtitle(user) %></div>

                        <div class="mt-2 flex items-center gap-3 text-xs font-medium text-slate-400">
                          <span class="inline-flex items-center gap-1">
                            <.icon name="hero-rectangle-stack" class="h-4 w-4" />
                            <%= user.public_share_count %> public shares
                          </span>
                          <span class="inline-flex items-center gap-1">
                            <.icon name="hero-user-group" class="h-4 w-4" />
                            <%= suggested_visibility_label(user.feed_visibility) %>
                          </span>
                        </div>
                      </div>
                    </.link>

                    <button
                      id={"toggle-follow-#{user.id}"}
                      type="button"
                      phx-click="toggle_follow_suggestion"
                      phx-value-user_id={user.id}
                      phx-disable-with="Updating..."
                      class={follow_button_class(user.following)}
                    >
                      <%= if user.following, do: "Following", else: "Follow" %>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">Posting guide</h2>
              <p class="mt-2 text-sm leading-6 text-slate-500">
                Keep the post short. Put booking details in the note. Use the modal for the actual weekly slot list.
              </p>
              <div class="mt-4 space-y-2">
                <div class="rounded-2xl bg-slate-50 px-3 py-3 text-sm text-slate-600">
                  `Public`: any visitor in-app or via your public share page.
                </div>
                <div class="rounded-2xl bg-slate-50 px-3 py-3 text-sm text-slate-600">
                  `Followers`: visible only to people following you in the feed.
                </div>
                <div class="rounded-2xl bg-slate-50 px-3 py-3 text-sm text-slate-600">
                  `Private`: kept off the shared public timeline.
                </div>
              </div>
            </div>

            <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">Your Share Targets</h2>

              <div class="mt-4">
                <div class="mb-2 text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Services</div>
                <p :if={@share_targets.services == []} class="text-sm text-slate-500">No services yet.</p>
                <ul :if={@share_targets.services != []} class="space-y-2">
                  <li :for={service <- @share_targets.services} class="rounded-2xl bg-slate-50 px-3 py-3">
                    <div class="flex items-center justify-between gap-3">
                      <span class="text-sm font-semibold text-slate-900"><%= service.name %></span>
                      <span class="text-xs font-semibold text-brand-700"><%= service.slot_count %> open</span>
                    </div>
                    <p :if={present?(service.description)} class="mt-1 text-xs leading-5 text-slate-500"><%= service.description %></p>
                  </li>
                </ul>
              </div>

              <div class="mt-4">
                <div class="mb-2 text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Resources</div>
                <p :if={@share_targets.resources == []} class="text-sm text-slate-500">No resources yet.</p>
                <ul :if={@share_targets.resources != []} class="space-y-2">
                  <li :for={resource <- @share_targets.resources} class="rounded-2xl bg-slate-50 px-3 py-3">
                    <div class="flex items-center justify-between gap-3">
                      <span class="text-sm font-semibold text-slate-900"><%= resource.name %></span>
                      <span class="text-xs font-semibold text-brand-700"><%= resource.slot_count %> open</span>
                    </div>
                    <p :if={present?(resource.description)} class="mt-1 text-xs leading-5 text-slate-500"><%= resource.description %></p>
                  </li>
                </ul>
              </div>
            </div>
            </div>
          </div>
        </aside>
      </div>

        <.modal
          :if={@show_post_modal}
          id="feed-post-modal"
          show={true}
          on_cancel={JS.push("close_post_modal")}
        >
          <div class="space-y-4">
            <div class="border-b border-slate-200 px-1 pb-4">
              <p class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Create Post</p>
              <h2 class="mt-2 pr-8 text-2xl font-semibold tracking-tight text-slate-950">Share Availability</h2>
              <p class="mt-2 text-sm leading-6 text-slate-600">
                Publish a booking window to your feed, followers, or private share list.
              </p>
            </div>

            <.simple_form
              for={@post_form}
              as={:post}
              id="share-post-form"
              phx-change="validate_post"
              phx-submit="save_post"
            >
              <div :if={!@has_share_targets} class="rounded-2xl border border-dashed border-warning-300 bg-warning-50 px-4 py-3 text-sm text-warning-900">
                Add at least one service or resource before posting a bookable share.
              </div>

              <div class="rounded-3xl border border-slate-200 bg-slate-50 px-4 py-4">
                <div class="flex gap-3">
                  <div class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-brand-50 text-sm font-semibold text-brand-700 ring-1 ring-brand-100">
                    <%= initials(@current_user.name) %>
                  </div>

                  <div class="min-w-0 flex-1">
                    <.input
                      field={@post_form[:body]}
                      type="textarea"
                      placeholder="What availability do you want to share?"
                      rows="3"
                      class="border-0 bg-transparent px-0 text-lg font-medium text-slate-900 placeholder:text-slate-400 focus:ring-0"
                    />

                    <div class="mt-3 border-t border-slate-200 pt-3">
                      <.input
                        field={@post_form[:booking_note]}
                        type="textarea"
                        placeholder="Add context for this time block: prep, meeting type, booking instructions."
                        rows="3"
                        class="border-0 bg-transparent px-0 text-sm text-slate-700 placeholder:text-slate-400 focus:ring-0"
                      />
                    </div>
                  </div>
                </div>

                 <div class="mt-4 grid gap-3 md:grid-cols-3">
                   <.input
                     field={@post_form[:visibility]}
                    type="select"
                    label="Audience"
                    options={@visibility_options}
                  />
                  <.input
                    field={@post_form[:service_id]}
                    type="select"
                    label="Service"
                    prompt="Choose"
                    options={@service_options}
                  />
                  <.input
                    field={@post_form[:resource_id]}
                    type="select"
                    label="Resource"
                     prompt="Choose"
                     options={@resource_options}
                   />
                 </div>

                 <div class="mt-4 rounded-2xl border border-slate-200 bg-white px-4 py-4">
                   <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Automatic Availability</div>
                   <p class="mt-2 text-sm leading-6 text-slate-500">
                     If you want this share to calculate slots automatically, configure the recurring rules below. Otherwise it will only expose exact manual slots.
                   </p>
                 </div>

                 <div class="mt-4 grid gap-3 md:grid-cols-2">
                   <.input field={@post_form[:auto_slots_enabled]} type="checkbox" label="Enable auto-generated slots" />
                   <.input field={@post_form[:timezone]} type="select" label="Timezone" options={@time_zone_options} />
                   <.input field={@post_form[:default_max_bookings]} type="number" label="Default max bookings" min="1" />
                   <.input field={@post_form[:slot_minutes]} type="number" label="Slot minutes" min="1" />
                   <.input field={@post_form[:schedule_start_date]} type="date" label="Schedule start date" />
                   <.input field={@post_form[:schedule_end_date]} type="date" label="Schedule end date" />
                   <.input field={@post_form[:work_start_time]} type="time" label="Work start time" />
                   <.input field={@post_form[:work_end_time]} type="time" label="Work end time" />
                   <.input field={@post_form[:break_minutes]} type="number" label="Break minutes" min="0" />
                   <.input field={@post_form[:lunch_start_time]} type="time" label="Lunch start (optional)" />
                   <.input field={@post_form[:lunch_end_time]} type="time" label="Lunch end (optional)" />
                 </div>

                 <div class="mt-3 grid gap-3">
                   <.input
                     field={@post_form[:available_weekdays]}
                     type="text"
                     label="Available weekdays"
                     placeholder="mon,tue,wed,thu,fri"
                   />
                   <.input
                     field={@post_form[:excluded_dates]}
                     type="textarea"
                     rows="2"
                     label="Excluded dates"
                     placeholder="2026-03-01, 2026-05-05"
                   />
                 </div>
               </div>

              <div class="mt-3 flex flex-wrap items-center justify-between gap-3">
                <div class="flex flex-wrap items-center gap-2 text-xs font-medium text-slate-500">
                  <span class="inline-flex items-center gap-1 rounded-full bg-slate-100 px-3 py-1.5">
                    <.icon name="hero-pencil-square" class="h-4 w-4 text-brand-600" />
                    <%= body_length(@post_form) %>/280
                  </span>
                  <span class="inline-flex items-center gap-1 rounded-full bg-slate-100 px-3 py-1.5">
                    <.icon name="hero-calendar-days" class="h-4 w-4 text-brand-600" />
                    Weekly modal booking
                  </span>
                </div>
                <.button type="submit" disabled={!@has_share_targets} phx-disable-with="Posting..." class="rounded-full bg-brand-600 px-5 hover:bg-brand-500">
                  Post
                </.button>
              </div>
            </.simple_form>
          </div>
        </.modal>

        <.modal
          :if={@selected_entry}
          id="booking-share-modal"
          show={true}
          on_cancel={JS.patch(scope_path(@scope))}
      >
        <div class="space-y-0">
          <div class="border-b border-slate-200 px-1 pb-4">
            <p class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Book From Share</p>
            <h2 class="mt-2 pr-8 text-2xl font-semibold tracking-tight text-slate-950"><%= @selected_entry.post.body %></h2>
            <p class="mt-2 text-sm leading-6 text-slate-600"><%= @selected_entry.post.booking_note %></p>
            <div class="mt-3 text-xs font-semibold uppercase tracking-[0.18em] text-slate-400"><%= target_summary(@selected_entry.post) %></div>
            <div class="mt-3 break-all rounded-2xl bg-slate-50 px-4 py-3 text-sm text-brand-700 ring-1 ring-slate-200">
              <%= share_path(@selected_entry.post.id) %>
            </div>
          </div>

          <div class="grid gap-0 pt-4 lg:grid-cols-[minmax(0,1.18fr)_minmax(0,0.82fr)]">
             <div class="space-y-3 pr-0 lg:pr-5">
               <div class="flex items-center justify-between gap-3">
                 <h3 class="text-sm font-semibold uppercase tracking-[0.18em] text-slate-400">Available Slots (7 Days)</h3>
                 <div class="flex items-center gap-2">
                   <span class="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.16em] text-slate-500">
                     <%= Social.post_timezone(@selected_entry.post) %>
                   </span>
                   <span class="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700">
                     <%= @selected_entry.slot_count %> open
                   </span>
                 </div>
               </div>

              <p :if={@selected_entry.weekly_slots == []} class="rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-sm text-slate-500">
                No open slots remain for the next week.
              </p>

              <div :if={@selected_entry.weekly_slots != []} class="space-y-2">
                <button
                  :for={slot <- @selected_entry.weekly_slots}
                  type="button"
                  phx-click="select_slot"
                  phx-value-slot_id={slot.id}
                  class={[
                    "w-full rounded-2xl border px-4 py-3 text-left transition",
                    @selected_slot_id == slot.id &&
                      "border-brand-400 bg-brand-25 ring-2 ring-brand-100",
                    @selected_slot_id != slot.id &&
                      "border-slate-200 bg-white hover:border-slate-300 hover:bg-slate-50"
                  ]}
                 >
                   <div class="flex flex-wrap items-center justify-between gap-3">
                     <div>
                       <div class="text-sm font-semibold text-slate-950"><%= format_slot_datetime(@selected_entry.post, slot.start_time, slot.end_time) %></div>
                       <div class="mt-1 text-xs text-slate-500"><%= slot_line_item(slot) %> · <%= slot_capacity(slot) %></div>
                     </div>
                     <div class="text-xs font-semibold text-brand-700"><%= slot_price(slot) %></div>
                   </div>
                </button>
              </div>
            </div>

            <div class="mt-5 border-t border-slate-200 pt-5 lg:mt-0 lg:border-t-0 lg:border-l lg:border-slate-200 lg:pl-5 lg:pt-0">
               <div class="rounded-3xl bg-slate-50 p-5 ring-1 ring-slate-200">
               <div>
                   <h3 class="text-sm font-semibold uppercase tracking-[0.18em] text-slate-400">Reserve Selected Slot</h3>
                   <p :if={!@selected_slot_id} class="mt-2 text-sm text-slate-500">Choose a slot from the left to book it.</p>
                   <p :if={@selected_slot_id} class="mt-2 text-sm leading-6 text-slate-600"><%= selected_slot_summary(@selected_entry.post, @selected_entry.weekly_slots, @selected_slot_id) %></p>
               </div>

                <.simple_form
                  for={@booking_form}
                  as={:booking}
                  id="booking-form"
                  phx-submit="book_slot"
                >
                  <.input field={@booking_form[:customer_name]} type="text" label="Name" />
                  <.input field={@booking_form[:email]} type="email" label="Email" />
                  <.input field={@booking_form[:phone]} type="text" label="Phone" />
                  <:actions>
                    <.button type="submit" disabled={is_nil(@selected_slot_id)} phx-disable-with="Booking..." class="w-full rounded-full bg-brand-600 hover:bg-brand-500">
                      Book This Time
                    </.button>
                  </:actions>
                </.simple_form>
              </div>
            </div>
          </div>
        </div>
      </.modal>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    socket =
      socket
      |> assign(:page_title, "Social Feed")
      |> assign(:hide_global_user_menu, true)
      |> assign(:visibility_options, Social.feed_visibility_options())
      |> assign(:time_zone_options, @time_zone_options)
      |> assign(:scope, :home)
      |> assign(:booking_activity, [])
      |> assign(:show_post_modal, false)
      |> assign(:selected_entry, nil)
      |> assign(:selected_slot_id, nil)
      |> assign(:post_form, empty_post_form(current_user))
      |> assign(:booking_form, booking_form(current_user))
      |> assign_sidebar()
      |> load_feed()

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    scope = parse_scope(Map.get(params, "scope"))

    socket =
      socket
      |> assign(:scope, scope)
      |> load_feed()

    case Map.get(params, "post_id") do
      nil ->
        {:noreply, clear_modal(socket)}

      post_id ->
        case find_entry(socket.assigns.entries, post_id) do
          nil ->
            {:noreply,
             socket
             |> put_flash(:error, "That shared booking post is not visible to you.")
             |> push_patch(to: scope_path(scope))}

          entry ->
            {:noreply, select_entry(socket, entry)}
        end
    end
  end

  def handle_event("validate_post", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Social.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :post_form, to_form(changeset, as: :post))}
  end

  def handle_event("open_post_modal", _params, socket) do
    {:noreply, assign(socket, :show_post_modal, true)}
  end

  def handle_event("close_post_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_post_modal, false)
     |> assign(:post_form, empty_post_form(socket.assigns.current_user))}
  end

  def handle_event("save_post", %{"post" => post_params}, socket) do
    case Social.create_post(socket.assigns.current_user, post_params) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Your availability post is live.")
         |> assign(:show_post_modal, false)
         |> assign_sidebar()
         |> assign(:post_form, empty_post_form(socket.assigns.current_user))
         |> load_feed()}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:show_post_modal, true)
         |> assign(:post_form, to_form(Map.put(changeset, :action, :insert), as: :post))}
    end
  end

  def handle_event("toggle_follow_suggestion", %{"user_id" => user_id}, socket) do
    current_user = socket.assigns.current_user

    if following_suggested_user?(socket.assigns.suggested_users, user_id) do
      :ok = Accounts.unfollow_user(current_user.id, user_id)
    else
      case Accounts.follow_user(current_user.id, user_id) do
        {:ok, _follow} -> :ok
        {:error, _changeset} -> :ok
      end
    end

    {:noreply,
     socket
     |> assign_sidebar()
     |> load_feed()}
  end

  def handle_event("select_slot", %{"slot_id" => slot_id}, socket) do
    {:noreply, assign(socket, :selected_slot_id, slot_id)}
  end

  def handle_event("book_slot", %{"booking" => booking_params}, socket) do
    cond do
      is_nil(socket.assigns.selected_entry) ->
        {:noreply, socket}

      is_nil(socket.assigns.selected_slot_id) ->
        {:noreply, put_flash(socket, :error, "Select a slot before booking.")}

      true ->
        attrs =
          booking_params
          |> Map.put("slot_id", socket.assigns.selected_slot_id)
          |> Map.put("user_id", socket.assigns.current_user.id)

        case Social.create_booking_from_post(socket.assigns.selected_entry.post, attrs) do
          {:ok, _booking} ->
            socket =
              socket
              |> put_flash(:info, "Booking confirmed.")
              |> assign(:booking_form, booking_form(socket.assigns.current_user))
              |> load_feed()

            {:noreply, refresh_modal(socket, socket.assigns.selected_entry.post.id)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :booking_form, to_form(Map.put(changeset, :action, :insert), as: :booking))}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, Social.booking_error_message(reason))}
        end
    end
  end

  defp load_feed(socket) do
    case socket.assigns.scope do
      :bookings ->
        booking_activity = Social.list_booking_activity(socket.assigns.current_user)

        assign(socket,
          entries: [],
          booking_activity: booking_activity,
          stats: stats([])
        )

      scope ->
        entries =
          socket.assigns.current_user
          |> Social.list_feed_posts(scope)
          |> Enum.map(&entry_for_post/1)

        assign(socket,
          entries: entries,
          booking_activity: [],
          stats: stats(entries)
        )
    end
  end

  defp entry_for_post(post) do
    weekly_slots = Social.list_weekly_slots_for_post(post)

    %{
      post: post,
      weekly_slots: weekly_slots,
      slot_count: length(weekly_slots)
    }
  end

  defp stats(entries) do
    %{
      visible_shares: length(entries),
      bookable_slots: Enum.reduce(entries, 0, fn entry, acc -> acc + entry.slot_count end),
      followers_only_shares: Enum.count(entries, fn entry -> entry.post.visibility == :followers end)
    }
  end

  defp find_entry(entries, post_id) do
    Enum.find(entries, fn entry -> entry.post.id == post_id end)
  end

  defp select_entry(socket, entry) do
    assign(socket,
      selected_entry: entry,
      selected_slot_id: default_slot_id(entry.weekly_slots),
      booking_form: booking_form(socket.assigns.current_user)
    )
  end

  defp refresh_modal(socket, post_id) do
    case find_entry(socket.assigns.entries, post_id) do
      nil -> clear_modal(socket)
      entry -> select_entry(socket, entry)
    end
  end

  defp clear_modal(socket) do
    assign(socket,
      selected_entry: nil,
      selected_slot_id: nil,
      booking_form: booking_form(socket.assigns.current_user)
    )
  end

  defp assign_sidebar(socket) do
    share_targets = Social.list_share_targets(socket.assigns.current_user)

    assign(socket,
      share_targets: share_targets,
      service_options: build_service_options(share_targets.services),
      resource_options: build_resource_options(share_targets.resources),
      has_share_targets: share_targets.services != [] or share_targets.resources != [],
      suggested_users: Social.list_suggested_users(socket.assigns.current_user)
    )
  end

  defp empty_post_form(current_user) do
    current_user
    |> Social.change_post(%{
      "body" => "",
      "booking_note" => "",
      "visibility" => default_visibility(current_user),
      "service_id" => "",
      "resource_id" => "",
      "auto_slots_enabled" => false,
      "timezone" => "Asia/Seoul",
      "slot_minutes" => 60,
      "break_minutes" => 10,
      "available_weekdays" => "mon,tue,wed,thu,fri",
      "excluded_dates" => ""
    })
    |> to_form(as: :post)
  end

  defp default_visibility(%{feed_visibility: visibility}) when visibility in [:public, :followers, :private] do
    Atom.to_string(visibility)
  end

  defp default_visibility(_user), do: "public"

  defp booking_form(current_user) do
    to_form(
      %{
        "customer_name" => current_user.name || "",
        "email" => current_user.email || "",
        "phone" => current_user.phone || ""
      },
      as: :booking
    )
  end

  defp build_service_options(services) do
    Enum.map(services, fn service ->
      {"#{service.name} (#{service.slot_count} open)", service.id}
    end)
  end

  defp build_resource_options(resources) do
    Enum.map(resources, fn resource ->
      {"#{resource.name} (#{resource.slot_count} open)", resource.id}
    end)
  end

  defp following_suggested_user?(suggested_users, user_id) do
    Enum.any?(suggested_users, fn user -> user.id == user_id and user.following end)
  end

  defp suggested_user_subtitle(user) do
    cond do
      user.following -> "Already in your network"
      user.public_share_count > 0 -> "Posting shared availability now"
      true -> "Public profile ready to follow"
    end
  end

  defp suggested_visibility_label(:public), do: "Public feed"
  defp suggested_visibility_label(:followers), do: "Followers unlock more"
  defp suggested_visibility_label(:link), do: "Link only"
  defp suggested_visibility_label(:private), do: "Private"

  defp follow_button_class(true) do
    "rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 transition hover:border-slate-300 hover:bg-slate-100"
  end

  defp follow_button_class(false) do
    "rounded-full bg-slate-950 px-3 py-1.5 text-xs font-semibold text-white transition hover:bg-slate-800"
  end

  defp admin?(user), do: Accounts.admin?(user)

  defp nav_items do
    [
      %{scope: :home, label: "Home", icon: "hero-home-solid"},
      %{scope: :following, label: "Following", icon: "hero-users-solid"},
      %{scope: :mine, label: "My Shares", icon: "hero-pencil-square"},
      %{scope: :bookings, label: "Bookings", icon: "hero-calendar-days-solid"}
    ]
  end

  defp nav_item_class(active_scope, item_scope) do
    base = "flex items-center gap-3 rounded-2xl px-4 py-3 transition"

    if active_scope == item_scope do
      "#{base} bg-slate-950 text-white"
    else
      "#{base} text-slate-500 hover:bg-slate-100 hover:text-slate-900"
    end
  end

  defp parse_scope("following"), do: :following
  defp parse_scope("mine"), do: :mine
  defp parse_scope("bookings"), do: :bookings
  defp parse_scope(_), do: :home

  defp scope_name(:home), do: "Home"
  defp scope_name(:following), do: "Following"
  defp scope_name(:mine), do: "My Shares"
  defp scope_name(:bookings), do: "Bookings"

  defp scope_description(:home), do: "A timeline for bookable shares, built like a social feed instead of a dashboard."
  defp scope_description(:following), do: "Only people you follow, so shared slots feel closer to an actual social graph."
  defp scope_description(:mine), do: "Your own availability posts, with share links ready to send out."
  defp scope_description(:bookings), do: "A compact record of the shared slots you already reserved."

  defp body_length(form) do
    form
    |> Access.get(:body)
    |> case do
      nil -> 0
      field -> field.value |> to_string() |> String.length()
    end
  end

  defp default_slot_id([slot | _]), do: slot.id
  defp default_slot_id([]), do: nil

  defp scope_path(:home), do: ~p"/feed"
  defp scope_path(scope), do: ~p"/feed?scope=#{Atom.to_string(scope)}"

  defp modal_path(post_id, :home), do: ~p"/feed/posts/#{post_id}"
  defp modal_path(post_id, scope), do: ~p"/feed/posts/#{post_id}?scope=#{Atom.to_string(scope)}"

  defp profile_path(user_id), do: ~p"/profiles/#{user_id}"
  defp share_path(post_id), do: ~p"/share/#{post_id}"

  defp target_summary(post) do
    labels = Enum.reject([post.service && "Service: #{post.service.name}", post.resource && "Resource: #{post.resource.name}"], &is_nil/1)

    Enum.join(labels, " | ")
  end

  defp slot_line_item(slot) do
    labels = Enum.reject([present_label("Service", slot.service_name), present_label("Resource", slot.resource_name)], &is_nil/1)

    Enum.join(labels, " | ")
  end

  defp slot_price(slot) do
    total =
      [slot.service_price, slot.resource_price]
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&Decimal.to_string(&1, :normal))
      |> Enum.map(&Decimal.new/1)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    "#{slot.currency || "KRW"} #{Decimal.to_string(total, :normal)}"
  end

  defp selected_slot_summary(post, slots, selected_slot_id) do
    case Enum.find(slots, fn slot -> slot.id == selected_slot_id end) do
      nil -> "Choose a slot to continue."
      slot -> "#{format_slot_datetime(post, slot.start_time, slot.end_time)} | #{slot_line_item(slot)}"
    end
  end

  defp format_slot_datetime(post, start_time, end_time) do
    start_local = Social.post_local_datetime(post, start_time)
    end_local = Social.post_local_datetime(post, end_time)
    start_label = Calendar.strftime(start_local, "%b %d, %a %H:%M")
    end_label = Calendar.strftime(end_local, "%H:%M")
    "#{start_label} - #{end_label} #{start_local.zone_abbr || start_local.time_zone}"
  end

  defp booking_title(booking) do
    labels = Enum.reject([present_label("Service", booking.service_name), present_label("Resource", booking.resource_name)], &is_nil/1)

    case labels do
      [] -> "Reserved shared slot"
      _ -> Enum.join(labels, " | ")
    end
  end

  defp booking_slot_summary(%{start_time: nil, end_time: nil}), do: "Reserved from a shared booking link."

  defp booking_slot_summary(booking) do
    start_label = Calendar.strftime(booking.start_time, "%b %d, %a %H:%M")
    end_label = Calendar.strftime(booking.end_time, "%H:%M")
    "#{start_label} - #{end_label}"
  end

  defp slot_capacity(%{remaining_capacity: nil}), do: "Unlimited"
  defp slot_capacity(%{remaining_capacity: remaining_capacity}), do: "#{remaining_capacity} left"

  defp booking_price(booking) do
    total = booking.total_price || Decimal.new(0)
    "#{booking.currency || "KRW"} #{Decimal.to_string(total, :normal)}"
  end

  defp booking_status_label("confirmed"), do: "Confirmed"
  defp booking_status_label("cancelled"), do: "Cancelled"
  defp booking_status_label("noshow"), do: "No-show"
  defp booking_status_label(status), do: status

  defp booking_status_class("confirmed"), do: "bg-success-50 text-success-700 ring-1 ring-success-200"
  defp booking_status_class("cancelled"), do: "bg-gray-100 text-gray-700 ring-1 ring-gray-200"
  defp booking_status_class("noshow"), do: "bg-warning-50 text-warning-700 ring-1 ring-warning-200"
  defp booking_status_class(_), do: "bg-blue-light-50 text-blue-light-700 ring-1 ring-blue-light-200"

  defp relative_posted_at(nil), do: "Just now"

  defp relative_posted_at(inserted_at) do
    seconds = DateTime.diff(DateTime.utc_now(), to_datetime(inserted_at), :second)

    cond do
      seconds < 60 -> "Just now"
      seconds < 3_600 -> "#{div(seconds, 60)}m ago"
      seconds < 86_400 -> "#{div(seconds, 3_600)}h ago"
      true -> "#{div(seconds, 86_400)}d ago"
    end
  end

  defp to_datetime(%DateTime{} = value), do: value
  defp to_datetime(%NaiveDateTime{} = value), do: DateTime.from_naive!(value, "Etc/UTC")

  defp initials(name) when is_binary(name) do
    name
    |> String.trim()
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
    |> case do
      "" -> "NA"
      value -> value
    end
  end

  defp initials(_), do: "NA"

  defp visibility_label(:public), do: "Public"
  defp visibility_label(:followers), do: "Followers"
  defp visibility_label(:private), do: "Private"

  defp visibility_badge_class(:public), do: "bg-success-50 text-success-700 ring-1 ring-success-200"
  defp visibility_badge_class(:followers), do: "bg-blue-light-50 text-blue-light-700 ring-1 ring-blue-light-200"
  defp visibility_badge_class(:private), do: "bg-gray-100 text-gray-700 ring-1 ring-gray-200"

  defp present?(value), do: value not in [nil, ""]
  defp present_label(_label, nil), do: nil
  defp present_label(_label, ""), do: nil
  defp present_label(label, value), do: "#{label}: #{value}"
end
