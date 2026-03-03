defmodule AinComBookingWeb.CompanyConsoleLiveTest do
  use AinComBookingWeb.ConnCase, async: false

  import AinComBooking.AccountsFixtures
  import Phoenix.LiveViewTest

  alias AinComBooking.Bookings.CompanySlot
  alias AinComBooking.CompanyConsole
  alias AinComBooking.CompanyConsole.BookingPage
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
      assert render(resource_lv) =~ "Create Booking Page"

      {:ok, slot_lv, _html} = live(conn, ~p"/company/console/slots")

      slot_lv
      |> element(~s(a[href="/company/console/slots/new"]))
      |> render_click()

      start_time = DateTime.utc_now() |> DateTime.add(24 * 60 * 60, :second) |> DateTime.truncate(:second)
      end_time = DateTime.add(start_time, 30 * 60, :second)

      slot_lv
      |> form("#company-slot-form",
        slot: %{
          start_time: datetime_local_value(start_time),
          end_time: datetime_local_value(end_time),
          status: "available",
          max_bookings: "1",
          service_id: service.id,
          resource_id: resource.id
        }
      )
      |> render_submit()

      slot = Repo.get_by!(CompanySlot, resource_id: resource.id)
      assert_patch(slot_lv, ~p"/company/console/slots/#{slot.id}")

      {:ok, page_lv, _html} = live(conn, "/company/console/resources/#{resource.id}/pages/new")

      assert has_element?(page_lv, ~s(input[type="date"][name="booking_page[schedule_start_date]"]))
      assert has_element?(page_lv, ~s(input[type="date"][name="booking_page[schedule_end_date]"]))
      assert has_element?(page_lv, ~s(select[name="booking_page[work_start_time]"]))
      assert has_element?(page_lv, ~s(select[name="booking_page[work_end_time]"]))
      assert has_element?(page_lv, ~s(select[name="booking_page[slot_minutes]"]))
      assert has_element?(page_lv, ~s(select[name="booking_page[break_minutes]"]))
      assert has_element?(page_lv, ~s(select[name="booking_page[lunch_start_time]"]))
      assert has_element?(page_lv, ~s(select[name="booking_page[lunch_end_time]"]))
      assert has_element?(page_lv, ~s(input[type="checkbox"][name="booking_page[available_weekdays][]"][value="mon"]))
      refute has_element?(page_lv, ~s(input[type="text"][name="booking_page[available_weekdays]"]))
      assert has_element?(page_lv, ~s(input[type="date"][name="booking_page[excluded_dates][]"]))
      refute has_element?(page_lv, ~s(textarea[name="booking_page[excluded_dates]"]))

      page_lv
      |> form("#company-booking-page-form",
        booking_page: %{
          title: "Board Room Reservations",
          slug: "board-room-a",
          description: "Reserve the room online.",
          button_label: "Reserve now",
          theme: "brand",
          is_published: "true"
        }
      )
      |> render_submit()

      page = Repo.get_by!(BookingPage, slug: "board-room-a")

      assert_patch(page_lv, "/company/console/resources/#{resource.id}/pages/#{page.id}")
      assert render(page_lv) =~ "/book/board-room-a"

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

      {:ok, _refreshed_dashboard, refreshed_dashboard_html} = live(conn, ~p"/company/console")
      assert refreshed_dashboard_html =~ "Customer One"
      assert refreshed_dashboard_html =~ "Board Room A"
      assert refreshed_dashboard_html =~ "/company/console/slots/#{slot.id}"
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

    test "non-company users cannot access the company console", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, redirect} = live(conn, ~p"/company/console")
      assert {:redirect, %{to: to}} = redirect
      assert to == ~p"/"
    end
  end

  defp datetime_local_value(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%dT%H:%M")
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
