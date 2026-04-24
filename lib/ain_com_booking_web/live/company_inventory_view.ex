defmodule AinComBookingWeb.CompanyInventoryView do
  @moduledoc false

  alias AinComBooking.Catalog.CompanyResource

  def inventory_type_from_uri(uri) when is_binary(uri) do
    if String.contains?(uri, "/company/console/resources") do
      :resource
    else
      :service
    end
  end

  def inventory_type_from_uri(_uri), do: :service

  def service_inventory?(:service), do: true
  def service_inventory?(_type), do: false

  def resource_inventory?(:resource), do: true
  def resource_inventory?(_type), do: false

  def infer_inventory_type(%CompanyResource{}), do: :resource
  def infer_inventory_type(_inventory), do: :service

  def inventory_form_as(:service), do: :service
  def inventory_form_as(:resource), do: :resource

  def inventory_form_param(:service), do: "service"
  def inventory_form_param(:resource), do: "resource"

  def inventory_slug(:service), do: "service"
  def inventory_slug(:resource), do: "resource"

  def inventory_title(:service), do: "Service"
  def inventory_title(:resource), do: "Resource"

  def inventory_section(:service), do: :services
  def inventory_section(:resource), do: :resources

  def inventory_new_path(:service), do: "/company/console/services/new"
  def inventory_new_path(:resource), do: "/company/console/resources/new"

  def inventory_index_path(:service), do: "/company/console/services"
  def inventory_index_path(:resource), do: "/company/console/resources"

  def inventory_show_path(:service, id), do: "/company/console/services/#{id}"
  def inventory_show_path(:resource, id), do: "/company/console/resources/#{id}"

  def inventory_edit_path(:service, id), do: "/company/console/services/#{id}/edit"
  def inventory_edit_path(:resource, id), do: "/company/console/resources/#{id}/edit"

  def inventory_delete_path(:service, id), do: "/company/console/services/#{id}/delete"
  def inventory_delete_path(:resource, id), do: "/company/console/resources/#{id}/delete"

  def inventory_cancel_path(type, nil), do: inventory_index_path(type)
  def inventory_cancel_path(type, inventory), do: inventory_show_path(type, inventory.id)

  def inventory_form_id(:service), do: "company-service-form"
  def inventory_form_id(:resource), do: "company-resource-form"

  def booking_page_form_id(:service), do: "company-service-booking-page-form"
  def booking_page_form_id(:resource), do: "company-resource-booking-page-form"

  def auto_slot_modal_id(:service), do: "service-auto-slot-modal"
  def auto_slot_modal_id(:resource), do: "resource-auto-slot-modal"

  def auto_slot_form_id(:service), do: "service-auto-slot-form"
  def auto_slot_form_id(:resource), do: "resource-auto-slot-form"

  def manual_slot_modal_id(:service), do: "service-manual-slot-modal"
  def manual_slot_modal_id(:resource), do: "resource-manual-slot-modal"

  def manual_slot_form_id(:service), do: "service-manual-slot-form"
  def manual_slot_form_id(:resource), do: "resource-manual-slot-form"

  def manual_slot_date_input_id(:service), do: "service-manual-slot-date"
  def manual_slot_date_input_id(:resource), do: "resource-manual-slot-date"

  def manual_slot_capacity_input_id(:service), do: "service-manual-slot-max-bookings"
  def manual_slot_capacity_input_id(:resource), do: "resource-manual-slot-max-bookings"

  def manual_slot_drag_grid_id(:service), do: "service-manual-slot-drag-grid"
  def manual_slot_drag_grid_id(:resource), do: "resource-manual-slot-drag-grid"

  def bookings_modal_id(:service), do: "service-bookings-modal"
  def bookings_modal_id(:resource), do: "resource-bookings-modal"

  def inventory_page_title(:service), do: "Company Services"
  def inventory_page_title(:resource), do: "Company Resources"

  def inventory_create_page_title(:service), do: "Create Company Service"
  def inventory_create_page_title(:resource), do: "Create Company Resource"

  def inventory_item_page_title(_type, :show, inventory), do: inventory.name
  def inventory_item_page_title(type, :edit, inventory), do: "Edit #{inventory_title(type)} #{inventory.name}"
  def inventory_item_page_title(type, :delete, inventory), do: "Delete #{inventory_title(type)} #{inventory.name}"

  def inventory_page_label(:index), do: "Read"
  def inventory_page_label(:new), do: "Create"
  def inventory_page_label(:show), do: "Read"
  def inventory_page_label(:edit), do: "Update"
  def inventory_page_label(:delete), do: "Delete"

  def inventory_page_subtitle(:service),
    do:
      "Company services are your primary offerings. Configure manual and automatic slots directly from each service detail page."

  def inventory_page_subtitle(:resource),
    do:
      "Resources are your bookable inventory. Configure manual and automatic slots directly from each resource detail page."

  def inventory_new_label(:service), do: "New Service"
  def inventory_new_label(:resource), do: "New Resource"

  def inventory_submit_label(:service, :new), do: "Create Service"
  def inventory_submit_label(:resource, :new), do: "Create Resource"
  def inventory_submit_label(_type, _action), do: "Save Changes"

  def inventory_empty_state(:service),
    do: "No company services yet. Create the first one and start opening slots for bookings."

  def inventory_empty_state(:resource),
    do: "No company resources yet. Add one so customers can book rooms, equipment, or desks."

  def inventory_booking_page_description(:service),
    do: "Publish customer-facing booking URLs for this service and manage page-level scheduling rules."

  def inventory_booking_page_description(:resource),
    do: "Publish customer-facing booking URLs for this resource and manage page-level scheduling rules."

  def inventory_booking_page_empty_state(:service),
    do: "No booking pages yet. Create one below to publish a shareable URL for this service."

  def inventory_booking_page_empty_state(:resource),
    do: "No booking pages yet. Create one below to publish a shareable URL for this resource."

  def inventory_slot_calendar_title(:service), do: "Service Slot Calendar"
  def inventory_slot_calendar_title(:resource), do: "Resource Slot Calendar"

  def inventory_snapshot_title(:service), do: "Service Snapshot"
  def inventory_snapshot_title(:resource), do: "Resource Snapshot"

  def inventory_delete_heading(:service), do: "Delete Service"
  def inventory_delete_heading(:resource), do: "Delete Resource"

  def inventory_delete_description(:service),
    do: "This also removes any slots and booking pages linked to this service."

  def inventory_delete_description(:resource),
    do: "This also removes any company slots and booking pages linked to this resource."

  def inventory_delete_button_label(:service), do: "Delete Service"
  def inventory_delete_button_label(:resource), do: "Delete Resource"

  def inventory_not_found_message(:service), do: "서비스를 찾을 수 없습니다."
  def inventory_not_found_message(:resource), do: "리소스를 찾을 수 없습니다."

  def inventory_missing_message(:service), do: "That company service was not found."
  def inventory_missing_message(:resource), do: "That company resource was not found."

  def inventory_created_message(:service), do: "Company service created."
  def inventory_created_message(:resource), do: "Company resource created."

  def inventory_updated_message(:service), do: "Company service updated."
  def inventory_updated_message(:resource), do: "Company resource updated."

  def inventory_deleted_message(:service), do: "Company service deleted."
  def inventory_deleted_message(:resource), do: "Company resource deleted."

  def inventory_delete_error_message(:service), do: "Company service could not be deleted."
  def inventory_delete_error_message(:resource), do: "Company resource could not be deleted."
end
