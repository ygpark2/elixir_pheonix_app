# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-05T17:25:45Z
**Commit:** N/A
**Branch:** main

## OVERVIEW
Core domain contexts implementing multi-tenant booking system with company and user resources.

## STRUCTURE
```
lib/ain_com_booking/
├── accounts/          # User authentication and management
├── bookings/          # Booking slots and reservations  
├── catalog/           # Companies, services, resources, units
├── scheduling/        # Working hours, breaks, time management
├── rules/             # Business rules and constraints
└── telemetry_ui/      # Metrics dashboard configuration
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| User authentication | accounts.ex | Guardian JWT + email confirmation flow |
| Booking management | bookings/ | Slot generation with 30min intervals, 10min gaps |
| Company resources | catalog/ | Multi-level: company → units → services/resources |
| Time scheduling | scheduling/ | Working hours, day off, break time management |
| Business rules | rules/ | Max count constraints per target type |

## CONVENTIONS
**Domain-Specific Patterns:**
- Dual entity system: Company* and User* variants for slots/bookings/services/resources
- Slot generation: 30-minute duration with 10-minute gaps configurable
- Multi-level ownership: company → unit → service/resource hierarchy
- Target types: :company, :unit, :service, :user enums for rule application
- Timezone handling: Asia/Seoul default, show_in_client_timezone option

## ANTI-PATTERNS (THIS PROJECT)
**Forbidden Domain Patterns:**
- DO NOT mix company and user booking contexts - maintain separate schemas
- DO NOT skip slot generation validation - always check working hours and holidays
- DO NOT ignore timezone conversions - client timezone support required
- DO NOT bypass booking rule enforcement - max_count constraints must apply
- DO NOT create slots outside configured timeframe boundaries