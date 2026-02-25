# MIGRATIONS KNOWLEDGE BASE

**Generated:** 2026-01-05T17:25:45Z
**Files:** 17 migrations
**Focus:** Multi-tenant booking system schema evolution

## OVERVIEW
Database schema evolution for multi-tenant booking system with UUID primary keys and dual company/user resource models.

## STRUCTURE
```
priv/repo/migrations/
├── 20250723055740_create_users_auth_tables.exs    # User authentication
├── 20250731052000_create_booking_rules.exs        # Global booking rules
├── 20250731052006_create_companies.exs            # Company entities
├── 2025073105200[8-9]_create_units.exs            # Measurement units
├── 2025073105201[1-5]_create_user_*.exs           # User resources/services/bookings
├── 2025073105202[0-3]_create_company_*.exs         # Company resources/services/bookings
├── 20250731052030_create_day_offs.exs              # Time off management
├── 20250731052031_create_working_hours.exs         # Schedule templates
├── 20250731052032_create_break_times.exs           # Break periods
└── 20250731052040_create_devices.exs               # Device auth tokens
```

## WHERE TO LOOK
| Schema Element | Migration | Key Features |
|----------------|-----------|--------------|
| User auth | create_users_auth_tables | Guardian JWT tokens + citext emails |
| Multi-tenancy | create_companies | Users own companies (FK constraint) |
| Dual model | create_user_services | User-level booking resources |
| Dual model | create_company_services | Company-level booking resources |
| Time slots | create_*_slots | UTC datetime with resource/service FKs |
| Bookings | create_*_bookings | Customer data + slot + optional user_id |
| Scheduling | create_working_hours | Polymorphic owner_type + weekday patterns |

## CONVENTIONS
**Database Schema Standards:**
- ALL tables use `binary_id` primary keys with `gen_random_uuid()`
- Foreign keys always specify `type: :binary_id` and cascade delete
- Timestamps automatically added with `timestamps()`
- Citext extension for case-insensitive emails
- UTC datetime for all time-based fields
- Indexes on foreign keys and query patterns
- Korean comments in some migrations (🔗 relationships)

## ANTI-PATTERNS (MIGRATIONS)
**Migration Issues Found:**
- create_company_resources.exs: FK references wrong table (`users` instead of `companies`)
- create_user_services.exs: FK references wrong table (`companies` instead of `users`)
- Inconsistent foreign key reference patterns across user vs company tables
- Missing unique constraints where needed (e.g., company login, user email already handled)