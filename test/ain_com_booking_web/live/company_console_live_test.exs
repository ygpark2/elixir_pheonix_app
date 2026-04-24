defmodule AinComBookingWeb.CompanyConsoleLiveTest do
  use AinComBookingWeb.ConnCase, async: false

  import AinComBooking.AccountsFixtures
  import Phoenix.LiveViewTest

  alias AinComBooking.Bookings.CompanyBooking
  alias AinComBooking.Bookings.CompanySlot
  alias AinComBooking.CompanyConsole
  alias AinComBooking.Repo

  describe "company console" do
    test "company users can manage inventory and publish booking pages", %{conn: conn} do
      company_user = user_fixture(%{name: "Company Owner", role: :company})
      conn = log_in_user(conn, company_user)

      {:ok, _dashboard, dashboard_html} = live(conn, ~p"/company/console")
      assert dashboard_html =~ "Company Dashboard"
      assert dashboard_html =~ "Recent Customer Bookings"
      assert dashboard_html =~ "Last 7 Days Revenue"

      {:ok, service_lv, _html} = live(conn, ~p"/company/console/services")

      service_lv
      |> element(~s(a[href="/company/console/services/new"]))
      |> render_click()

      assert_patch(service_lv, ~p"/company/console/services/new")

      service_lv
      |> form("#company-service-form",
        service: %{
          name: "Executive Demo",
          description_text: "Enterprise walkthrough",
          duration: "45",
          price: "150.00",
          currency: "USD",
          is_active: "true",
          is_public: "true"
        }
      )
      |> render_submit()

      service = Repo.get_by!(AinComBooking.Catalog.CompanyService, name: "Executive Demo")
      assert render(service_lv) =~ "Executive Demo"

      {:ok, resource_lv, _html} = live(conn, ~p"/company/console/resources")

      resource_lv
      |> element(~s(a[href="/company/console/resources/new"]))
      |> render_click()

      assert_patch(resource_lv, ~p"/company/console/resources/new")

      resource_lv
      |> form("#company-resource-form",
        resource: %{
          name: "Board Room A",
          type: "room",
          location: "Seoul HQ",
          description: "Large conference room",
          price: "25.00",
          currency: "KRW"
        }
      )
      |> render_submit()

      resource = Repo.get_by!(AinComBooking.Catalog.CompanyResource, name: "Board Room A")

      assert_patch(resource_lv, ~p"/company/console/resources/#{resource.id}")
      assert render(resource_lv) =~ "Resource Slot Calendar"

      start_time = DateTime.utc_now() |> DateTime.add(24 * 60 * 60, :second) |> DateTime.truncate(:second)
      end_time = DateTime.add(start_time, 30 * 60, :second)

      {:ok, slot} =
        CompanyConsole.create_company_slot(company_user, %{
          "start_time" => start_time,
          "end_time" => end_time,
          "status" => "available",
          "max_bookings" => "1",
          "service_id" => service.id,
          "resource_id" => resource.id
        })

      {:ok, _page} =
        CompanyConsole.create_booking_page_for_resource(company_user, resource.id, %{
          "title" => "Board Room Reservations",
          "slug" => "board-room-a",
          "description" => "Reserve the room online.",
          "button_label" => "Reserve now",
          "theme" => "brand",
          "is_published" => "true"
        })

      {:ok, public_lv, public_html} = live(conn, ~p"/book/board-room-a")
      assert public_html =~ "Board Room Reservations"
      assert public_html =~ "Board Room A"

      public_lv
      |> form("#public-company-booking-form",
        booking: %{
          customer_name: "Customer One",
          email: "customer@example.com",
          phone: "010-9999-9999"
        }
      )
      |> render_submit()

      assert render(public_lv) =~ "Your booking is confirmed."
      assert Repo.get!(CompanySlot, slot.id).status == :booked

      {:ok, resource_show_lv, _resource_html} = live(conn, ~p"/company/console/resources/#{resource.id}")
      assert render(resource_show_lv) =~ "1 booking"

      {:ok, _refreshed_dashboard, refreshed_dashboard_html} = live(conn, ~p"/company/console")
      assert refreshed_dashboard_html =~ "Customer One"
      assert refreshed_dashboard_html =~ "Board Room A"
      assert refreshed_dashboard_html =~ "/company/console/resources/#{resource.id}"
    end

    test "company pages can auto-generate availability windows without pre-created slots", %{conn: conn} do
      company_user = user_fixture(%{name: "Auto Company", role: :company})
      conn = log_in_user(conn, company_user)
      company = CompanyConsole.ensure_company!(company_user)
      Repo.update!(Ecto.Changeset.change(company, timezone: "Asia/Seoul"))

      {:ok, resource} =
        CompanyConsole.create_company_resource(company_user, %{
          "name" => "Auto Board Room",
          "type" => "room",
          "location" => "Gangnam",
          "description" => "Auto generated schedule",
          "price" => "50.00",
          "currency" => "KRW"
        })

      tomorrow = Date.add(local_date("Asia/Seoul"), 1)

      {:ok, page} =
        CompanyConsole.create_booking_page_for_resource(company_user, resource.id, %{
          "title" => "Auto Board Room",
          "slug" => "auto-board-room",
          "description" => "Automatically generated slots",
          "button_label" => "Reserve",
          "theme" => "brand",
          "is_published" => "true",
          "auto_slots_enabled" => "true",
          "schedule_start_date" => tomorrow,
          "schedule_end_date" => tomorrow,
          "work_start_time" => ~T[09:00:00],
          "work_end_time" => ~T[12:00:00],
          "slot_minutes" => "60",
          "break_minutes" => "10",
          "available_weekdays" => weekday_name(tomorrow),
          "excluded_dates" => "",
          "default_max_bookings" => "2"
        })

      {:ok, public_lv, public_html} = live(conn, ~p"/book/#{page.slug}")
      assert public_html =~ "Auto Board Room"
      assert public_html =~ "Asia/Seoul"
      assert public_html =~ "2 left"

      public_lv
      |> form("#public-company-booking-form",
        booking: %{
          customer_name: "Auto Customer",
          email: "auto@example.com",
          phone: "010-0000-9999"
        }
      )
      |> render_submit()

      assert render(public_lv) =~ "Your booking is confirmed."
      assert render(public_lv) =~ "1 left"

      {:ok, _dashboard, dashboard_html} = live(conn, ~p"/company/console")
      assert dashboard_html =~ "Auto Customer"
      assert dashboard_html =~ "Auto Board Room"
    end

    test "service detail manual slot modal creates a slot and updates calendar immediately", %{conn: conn} do
      company_user = user_fixture(%{name: "Service Slot Owner", role: :company})
      conn = log_in_user(conn, company_user)

      {:ok, service} =
        CompanyConsole.create_company_service(company_user, %{
          "name" => "Manual Slot Service",
          "description_text" => "Service detail slot test",
          "duration" => 45,
          "price" => "90.00",
          "currency" => "KRW",
          "is_active" => true,
          "is_public" => true
        })

      {:ok, lv, html} = live(conn, ~p"/company/console/services/#{service.id}")
      assert html =~ "Service Slot Calendar"

      lv
      |> element(~s(button[phx-click="open_manual_slot_modal"]))
      |> render_click()

      assert has_element?(lv, "#service-manual-slot-form")

      selected_date = Date.utc_today()

      render_hook(lv, "manual_drag_select", %{"start_index" => "40", "end_index" => "43"})
      render_hook(lv, "manual_drag_select", %{"start_index" => "44", "end_index" => "47"})

      start_time_a = DateTime.new!(selected_date, Time.new!(10, 0, 0), "Etc/UTC")
      end_time_a = DateTime.new!(selected_date, Time.new!(10, 45, 0), "Etc/UTC")
      start_time_b = DateTime.new!(selected_date, Time.new!(11, 0, 0), "Etc/UTC")
      end_time_b = DateTime.new!(selected_date, Time.new!(11, 45, 0), "Etc/UTC")

      lv
      |> form("#service-manual-slot-form",
        manual_slot: %{
          selected_date: Date.to_iso8601(selected_date),
          max_bookings: "3"
        }
      )
      |> render_submit()

      assert render(lv) =~ "수동 slot 2개 생성"

      created_slot_a = Repo.get_by!(CompanySlot, service_id: service.id, start_time: start_time_a, end_time: end_time_a)
      created_slot_b = Repo.get_by!(CompanySlot, service_id: service.id, start_time: start_time_b, end_time: end_time_b)

      assert created_slot_a.max_bookings == 3
      assert created_slot_b.max_bookings == 3

      expected_slot_line_a =
        "#{Calendar.strftime(start_time_a, "%Y-%m-%d %H:%M UTC")} to #{Calendar.strftime(end_time_a, "%Y-%m-%d %H:%M UTC")}"

      expected_slot_line_b =
        "#{Calendar.strftime(start_time_b, "%Y-%m-%d %H:%M UTC")} to #{Calendar.strftime(end_time_b, "%Y-%m-%d %H:%M UTC")}"

      rendered = render(lv)
      assert rendered =~ expected_slot_line_a
      assert rendered =~ expected_slot_line_b
    end

    test "service detail page creates and updates booking pages from the UI", %{conn: conn} do
      company_user = user_fixture(%{name: "Service Booking Page Owner", role: :company})
      conn = log_in_user(conn, company_user)

      {:ok, service} =
        CompanyConsole.create_company_service(company_user, %{
          "name" => "Strategy Session",
          "description_text" => "Service booking page test",
          "duration" => 60,
          "price" => "120.00",
          "currency" => "USD",
          "is_active" => true,
          "is_public" => true
        })

      {:ok, lv, _html} = live(conn, ~p"/company/console/services/#{service.id}")

      lv
      |> form("#company-service-booking-page-form",
        booking_page: %{
          title: "Strategy Session Booking",
          slug: "strategy-session-booking",
          button_label: "Reserve now",
          theme: "brand",
          is_published: "true",
          auto_slots_enabled: "false",
          description: "Book a strategy session.",
          available_weekdays: ["mon", "tue"],
          excluded_dates: "",
          default_max_bookings: ""
        }
      )
      |> render_submit()

      assert render(lv) =~ "Strategy Session Booking"
      assert render(lv) =~ "/book/strategy-session-booking"

      page = Repo.get_by!(AinComBooking.CompanyConsole.BookingPage, slug: "strategy-session-booking")

      lv
      |> element(~s(button[phx-click="edit_booking_page"][phx-value-page_id="#{page.id}"]))
      |> render_click()

      lv
      |> form("#company-service-booking-page-form",
        booking_page: %{
          title: "Strategy Session Booking Updated",
          slug: "strategy-session-booking",
          button_label: "Reserve now",
          theme: "brand",
          is_published: "true",
          auto_slots_enabled: "false",
          description: "Book a strategy session.",
          available_weekdays: ["mon", "tue"],
          excluded_dates: "",
          default_max_bookings: ""
        }
      )
      |> render_submit()

      assert render(lv) =~ "Strategy Session Booking Updated"
    end

    test "resource detail auto slot modal creates slots and shows them on calendar", %{conn: conn} do
      company_user = user_fixture(%{name: "Resource Slot Owner", role: :company})
      conn = log_in_user(conn, company_user)

      {:ok, resource} =
        CompanyConsole.create_company_resource(company_user, %{
          "name" => "Auto Slot Room",
          "type" => "room",
          "location" => "Gangnam",
          "description" => "Resource detail slot test",
          "price" => "70.00",
          "currency" => "KRW"
        })

      {:ok, lv, html} = live(conn, ~p"/company/console/resources/#{resource.id}")
      assert html =~ "Resource Slot Calendar"

      lv
      |> element(~s(button[phx-click="open_auto_slot_modal"]))
      |> render_click()

      assert has_element?(lv, "#resource-auto-slot-form")
      refute has_element?(lv, "#auto-excluded-date-1")

      lv
      |> element(~s(button[phx-click="add_auto_excluded_date"]))
      |> render_click()

      assert has_element?(lv, "#auto-excluded-date-1")

      tomorrow = Date.add(Date.utc_today(), 1)
      weekday = weekday_name(tomorrow)

      lv
      |> form("#resource-auto-slot-form",
        auto_slot: %{
          auto_slots_enabled: "true",
          schedule_start_date: Date.to_iso8601(tomorrow),
          schedule_end_date: Date.to_iso8601(tomorrow),
          work_start_time: "09:00",
          work_end_time: "10:00",
          slot_minutes: "30",
          break_minutes: "0",
          lunch_start_time: "",
          lunch_end_time: "",
          available_weekdays: [weekday],
          excluded_dates: [""],
          default_max_bookings: "2"
        }
      )
      |> render_submit()

      rendered = render(lv)
      assert rendered =~ "자동 slot 2개 생성"

      created_slots =
        company_user
        |> CompanyConsole.list_company_slots()
        |> Enum.filter(&(&1.resource_id == resource.id))

      assert length(created_slots) == 2
      assert rendered =~ "Max 2 bookings"
    end

    test "resource detail page creates booking pages from the UI", %{conn: conn} do
      company_user = user_fixture(%{name: "Resource Booking Page Owner", role: :company})
      conn = log_in_user(conn, company_user)

      {:ok, resource} =
        CompanyConsole.create_company_resource(company_user, %{
          "name" => "Studio A",
          "type" => "studio",
          "location" => "Seoul",
          "description" => "Resource booking page test",
          "price" => "80.00",
          "currency" => "KRW"
        })

      {:ok, lv, _html} = live(conn, ~p"/company/console/resources/#{resource.id}")

      lv
      |> form("#company-resource-booking-page-form",
        booking_page: %{
          title: "Studio A Booking",
          slug: "studio-a-booking",
          button_label: "Reserve now",
          theme: "brand",
          is_published: "true",
          auto_slots_enabled: "false",
          description: "Book Studio A.",
          available_weekdays: ["mon", "tue"],
          excluded_dates: "",
          default_max_bookings: ""
        }
      )
      |> render_submit()

      assert render(lv) =~ "Studio A Booking"
      assert render(lv) =~ "/book/studio-a-booking"
    end

    test "service index booked modal supports edit and cancel", %{conn: conn} do
      company_user = user_fixture(%{name: "Service Booking Owner", role: :company})
      conn = log_in_user(conn, company_user)

      {:ok, service} =
        CompanyConsole.create_company_service(company_user, %{
          "name" => "Booked Service",
          "description_text" => "Service bookings modal test",
          "duration" => 30,
          "price" => "55.00",
          "currency" => "KRW",
          "is_active" => true,
          "is_public" => true
        })

      start_time = future_datetime_at_minute(3)
      end_time = DateTime.add(start_time, 30 * 60, :second)

      {:ok, slot} =
        CompanyConsole.create_company_slot(company_user, %{
          "start_time" => start_time,
          "end_time" => end_time,
          "status" => "available",
          "source_type" => "manual",
          "service_id" => service.id
        })

      booking =
        %CompanyBooking{}
        |> CompanyBooking.changeset(%{
          "customer_name" => "Booking Customer",
          "email" => "booking@example.com",
          "phone" => "010-1111-2222",
          "status" => "confirmed",
          "slot_id" => slot.id,
          "service_id" => service.id,
          "total_price" => "55.00",
          "currency" => "KRW"
        })
        |> Repo.insert!()

      {:ok, lv, _html} = live(conn, ~p"/company/console/services")

      lv
      |> element(~s(button[phx-click="open_service_bookings_modal"][phx-value-service_id="#{service.id}"]))
      |> render_click()

      assert has_element?(lv, "#service-bookings-modal")
      assert render(lv) =~ "Booking Customer"

      lv
      |> element(~s(button[phx-click="edit_booking"][phx-value-booking_id="#{booking.id}"]))
      |> render_click()

      lv
      |> form("#service-booking-edit-form-#{booking.id}",
        booking: %{
          customer_name: "Booking Customer Updated",
          email: "booking-updated@example.com",
          phone: "010-3333-4444",
          status: "noshow"
        }
      )
      |> render_submit()

      updated_booking = Repo.get!(CompanyBooking, booking.id)
      assert updated_booking.customer_name == "Booking Customer Updated"
      assert updated_booking.status == "noshow"

      lv
      |> element(~s(button[phx-click="cancel_booking"][phx-value-booking_id="#{booking.id}"]))
      |> render_click()

      cancelled_booking = Repo.get!(CompanyBooking, booking.id)
      assert cancelled_booking.status == "cancelled"
      assert render(lv) =~ "예약을 취소했습니다."
    end

    test "resource index booked modal supports edit and cancel", %{conn: conn} do
      company_user = user_fixture(%{name: "Resource Booking Owner", role: :company})
      conn = log_in_user(conn, company_user)

      {:ok, resource} =
        CompanyConsole.create_company_resource(company_user, %{
          "name" => "Booked Resource",
          "type" => "room",
          "location" => "Gangnam",
          "description" => "Resource bookings modal test",
          "price" => "80.00",
          "currency" => "KRW"
        })

      start_time = future_datetime_at_minute(4)
      end_time = DateTime.add(start_time, 60 * 60, :second)

      {:ok, slot} =
        CompanyConsole.create_company_slot(company_user, %{
          "start_time" => start_time,
          "end_time" => end_time,
          "status" => "available",
          "source_type" => "manual",
          "resource_id" => resource.id
        })

      booking =
        %CompanyBooking{}
        |> CompanyBooking.changeset(%{
          "customer_name" => "Resource Customer",
          "email" => "resource@example.com",
          "phone" => "010-5555-6666",
          "status" => "confirmed",
          "slot_id" => slot.id,
          "resource_id" => resource.id,
          "total_price" => "80.00",
          "currency" => "KRW"
        })
        |> Repo.insert!()

      {:ok, lv, _html} = live(conn, ~p"/company/console/resources")

      lv
      |> element(~s(button[phx-click="open_resource_bookings_modal"][phx-value-resource_id="#{resource.id}"]))
      |> render_click()

      assert has_element?(lv, "#resource-bookings-modal")
      assert render(lv) =~ "Resource Customer"

      lv
      |> element(~s(button[phx-click="edit_booking"][phx-value-booking_id="#{booking.id}"]))
      |> render_click()

      lv
      |> form("#resource-booking-edit-form-#{booking.id}",
        booking: %{
          customer_name: "Resource Customer Updated",
          email: "resource-updated@example.com",
          phone: "010-7777-8888",
          status: "noshow"
        }
      )
      |> render_submit()

      updated_booking = Repo.get!(CompanyBooking, booking.id)
      assert updated_booking.customer_name == "Resource Customer Updated"
      assert updated_booking.status == "noshow"

      lv
      |> element(~s(button[phx-click="cancel_booking"][phx-value-booking_id="#{booking.id}"]))
      |> render_click()

      cancelled_booking = Repo.get!(CompanyBooking, booking.id)
      assert cancelled_booking.status == "cancelled"
      assert render(lv) =~ "예약을 취소했습니다."
    end

    test "non-company users cannot access the company console", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, redirect} = live(conn, ~p"/company/console")
      assert {:redirect, %{to: to}} = redirect
      assert to == ~p"/"
    end
  end

  defp future_datetime_at_minute(days_ahead) when is_integer(days_ahead) and days_ahead > 0 do
    future = DateTime.add(DateTime.utc_now(), days_ahead * 24 * 60 * 60, :second)
    date = DateTime.to_date(future)
    time = DateTime.to_time(future)
    {:ok, normalized_time} = Time.new(time.hour, time.minute, 0)
    date |> NaiveDateTime.new!(normalized_time) |> DateTime.from_naive!("Etc/UTC")
  end

  defp weekday_name(date) do
    case Date.day_of_week(date) do
      1 -> "mon"
      2 -> "tue"
      3 -> "wed"
      4 -> "thu"
      5 -> "fri"
      6 -> "sat"
      7 -> "sun"
    end
  end

  defp local_date(timezone) do
    offset_seconds =
      case timezone do
        "Asia/Seoul" -> 9 * 60 * 60
        _ -> 0
      end

    DateTime.utc_now()
    |> DateTime.add(offset_seconds, :second)
    |> DateTime.to_date()
  end
end
