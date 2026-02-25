# WEB INTERFACE KNOWLEDGE BASE

**Generated:** 2026-01-05T17:30:00Z
**Scope:** lib/ain_com_booking_web - LiveView-based web interface with authentication and admin components

## OVERVIEW
Phoenix LiveView web interface with session-based authentication, real-time UI components, and admin dashboard for booking management.

## STRUCTURE
```
lib/ain_com_booking_web/
├── router.ex                    # Web router with browser, auth, and LiveView routes
├── endpoint.ex                  # Phoenix endpoint configuration and plugs
├── session.ex                   # Session management and plug configuration
├── controllers/                 # Traditional Phoenix controllers (minimal)
├── live/                       # LiveView components and pages
├── components/                  # Reusable UI components and layouts
├── components/layouts/           # Page layout templates
├── home/                       # Home page controllers and templates
├── admin/                      # Admin interface components
├── errors/                     # Error page components
└── user_auth.ex                # Authentication pipelines and helpers
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Web routing | router.ex | Browser pipelines, auth scopes, LiveView routes |
| Session management | session.ex | Plug.Session config and key settings |
| Authentication flows | user_auth.ex | Session auth, redirect helpers, user mounting |
| LiveView pages | live/ | User registration, login, settings, admin dashboard |
| UI components | components/core_components.ex | Reusable components, modals, forms |
| Page layouts | components/layouts/ | Root layout, app layout, flash messages |
| Admin interface | admin/ | Admin dashboard components and live views |
| Error pages | errors/ | 404, 500 error page components |

## CONVENTIONS
**LiveView Architecture:**
- Session-based authentication with CSRF protection
- Flash messages for user feedback with automatic clearing
- Live navigation for seamless page transitions
- Form components with validation and error handling

**Component Organization:**
- Core components in `core_components.ex` with `.modal`, `.simple_form`, `.table` helpers
- Layout components separate from page-specific components
- Modal patterns for confirmations and forms

**Authentication:**
- Session-based (not JWT) for web interface
- Redirect flows for unauthenticated users
- User mounting in conn for LiveView access
- Email confirmation workflows with token validation

**Admin Interface:**
- Separate admin namespace with live views
- Role-based access control (admin-only routes)
- Dashboard components for system management

## ANTI-PATTERNS (THIS DOMAIN)
**LiveView Development:**
- DO NOT use JWT tokens for LiveView authentication (use sessions)
- DO NOT bypass CSRF protection in web forms
- DO NOT mix Phoenix Controller patterns with LiveView unnecessarily

**Component Design:**
- DO NOT create overly complex LiveView components (break into smaller pieces)
- DO NOT ignore flash message lifecycle management
- DO NOT use stateful components when stateless alternatives exist

**Security:**
- DO NOT expose admin routes without proper authorization
- DO NOT skip session validation in sensitive operations
- DO NOT use client-side routing for authenticated flows

## NOTES
- LiveView integration includes automatic CSRF protection
- Session configuration uses secure cookie settings
- Component library uses Tailwind CSS for styling
- Admin interface requires elevated permissions
- Error pages are custom LiveView components for consistency