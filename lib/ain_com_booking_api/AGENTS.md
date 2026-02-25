# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-05T17:30:00Z
**Commit:** N/A
**Domain:** lib/ain_com_booking_api

## OVERVIEW
REST API layer providing JSON endpoints with dual-token authentication (JWT + device tokens).

## STRUCTURE
```
lib/ain_com_booking_api/
├── controllers/                 # API endpoint handlers
│   ├── auth_controller.ex       # User signup/login with token generation
│   └── company/                 # Company-scoped resources
│       └── user/                # User-scoped resources
├── plugs/                       # Request processing pipeline
│   └── device_token_auth.ex     # Device token validation plug
├── devices/                     # Device management system
│   ├── device.ex                # Device schema
│   └── devices.ex               # Device lifecycle operations
├── errors/                      # Error handling utilities
├── auth_pipeline.ex             # Guardian JWT pipeline
├── common_parameters.ex         # Shared Swagger definitions
└── guardian.ex                  # Guardian configuration
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Authentication flow | auth_controller.ex | Dual-token: JWT + device tokens |
| Device management | devices.ex | 90-day TTL, rotation, revocation |
| API security | auth_pipeline.ex + device_token_auth.ex | Bearer JWT + X-Device-Token header |
| Error responses | errors.ex | Localized validation errors |
| Swagger docs | All controllers | PhoenixSwagger integration |

## CONVENTIONS
**API Security:**
- Dual authentication: `Authorization: Bearer <jwt>` + `X-Device-Token: <token>`
- Device tokens: SHA256 hashed, 32-byte random, 90-day expiry
- Automatic device token rotation within 7 days of expiry
- Fingerprints: SHA256 hash of user-agent + IP address

**Controller Patterns:**
- All endpoints use PhoenixSwagger for API documentation
- Standardized error responses with localized messages
- JSON responses only, no HTML templates
- Guardian.Plug.current_resource(conn, key: :auth) for user context

**Request Validation:**
- Ecto changesets for input validation
- Required Authorization and X-Device-Token headers via CommonParameters
- Automatic 422 responses for validation failures

## ANTI-PATTERNS (THIS DOMAIN)
- DO NOT skip device token validation on protected endpoints
- DO NOT return raw device tokens in error messages
- DO NOT mix authentication patterns (some endpoints use JWT only, others dual)
- DO NOT use session-based authentication - this API is stateless
- DO NOT expose device fingerprinting logic to clients