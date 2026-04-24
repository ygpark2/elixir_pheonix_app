# Company Console Facade Policy

## Decision
`AinComBooking.CompanyConsole` stays as a compatibility facade, not the preferred API for new company-console work.

New code should call the narrow workflow/domain module that owns the behavior:
- `AinComBooking.CompanyConsole.Inventory` for company services and resources.
- `AinComBooking.CompanyConsole.BookingPages` for booking page CRUD, public URLs, timezone helpers, and published page lookup.
- `AinComBooking.CompanyConsole.Bookings` for company booking reads, updates, public booking creation, and booking error messages.
- `AinComBooking.CompanyConsole.SlotGeneration` for company slot CRUD, slot listing, capacity helpers, and generated slot flows.

## Allowed Facade Use
Keep `CompanyConsole` calls only where the call is intentionally cross-domain or compatibility-oriented:
- Existing tests or legacy callers that have not been migrated yet.
- Company ownership bootstrap such as `ensure_company!/1` and `get_company_for_user/1`, until that responsibility is moved to a smaller module.
- Dashboard aggregate functions that intentionally combine inventory, booking pages, bookings, and slots.
- Public compatibility wrappers that avoid breaking external or older internal callers.

## Migration Rules
- Do not add new `CompanyConsole.*` calls from LiveViews, components, controllers, or workflows when a narrow module already exposes the function.
- When touching a caller that already uses `CompanyConsole`, migrate nearby calls to the owning module if the change is low risk.
- Keep orchestration in web workflow modules such as `CompanyInventoryWorkflow` and `CompanyInventorySlotWorkflow`; keep persistence and validation in domain modules.
- Do not move generated/static asset or UI formatting concerns into domain modules.

## Current Web-Layer Pattern
`CompanyInventoryLive` should remain a thin LiveView shell:
- Inventory CRUD and booking-page workflows route through `CompanyInventoryWorkflow`.
- Manual slot creation, automatic slot generation, and inventory calendar navigation route through `CompanyInventorySlotWorkflow`.
- Target-specific service/resource branching stays in `CompanyInventoryTarget`.
