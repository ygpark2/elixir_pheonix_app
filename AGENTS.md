# ASSETS KNOWLEDGE BASE

**Generated:** 2026-01-05T17:32:00Z  
**Scope:** assets/ - Frontend asset pipeline with Tailwind CSS, ESBuild, and modern JavaScript tooling

## OVERVIEW
Modern frontend asset pipeline using Tailwind CSS v4 for styling, ESBuild for JavaScript bundling, and AlpineJS for reactive components. Integrates with Phoenix LiveView and includes Ant Design components for UI consistency.

## STRUCTURE
```
assets/
├── css/app.css                 # Main Tailwind entrypoint with custom utilities
├── js/app.js                   # JavaScript entrypoint with Phoenix LiveView + Alpine
├── tailwind.config.js          # Tailwind configuration with content paths and theme
├── package.json                # Node.js dependencies and build scripts
├── .eslintrc.json             # ESLint configuration for JavaScript linting
├── stylelint.config.js         # Stylelint configuration for CSS linting
└── prettier.config.js          # Prettier configuration for code formatting
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Tailwind entry point | css/app.css | Imports Tailwind with custom variants and utilities |
| JavaScript setup | js/app.js | Phoenix LiveView integration with AlpineJS |
| Tailwind config | tailwind.config.js | Content paths and brand color theme |
| Node dependencies | package.json | Phoenix LiveView, Ant Design, AlpineJS |
| Build configuration | config/config.exs | ESBuild and Tailwind Mix task configuration |
| Development watchers | config/dev.exs | Auto-reload with --watch flags |

## CONVENTIONS
**Asset Pipeline:**
- ESBuild bundles JS/JSX to `priv/static/assets/` with ES2017 target
- Tailwind processes CSS from `css/app.css` to `priv/static/assets/app.css`
- Content scanning includes JS files and Phoenix templates for CSS purging
- Development uses watchers with sourcemaps and auto-reload

**Styling Architecture:**
- Tailwind CSS v4 with custom brand color palette (25-950 scale)
- Utility classes for menu items, scrollbars, third-party integrations
- Dark mode support with custom variants and CSS variables
- Component-specific overrides for ApexCharts, Flatpickr, FullCalendar

**JavaScript Framework:**
- AlpineJS with persistence plugin for client-side state
- Phoenix LiveView hooks for flash messages and lifecycle management
- Ant Design components available via npm integration
- CSRF token handling for secure LiveView connections

## BUILD COMMANDS
**Development:**
```bash
make dependencies          # Install npm dependencies in assets/
npm install --prefix assets # Direct npm install
mix phx.server           # Starts ESBuild + Tailwind watchers
```

**Production:**
```bash
mix assets.deploy         # Build and digest assets (Tailwind + ESBuild)
npm ci --prefix assets    # Production dependency install
```

**Code Quality:**
```bash
make format              # Format with Prettier + Stylelint
make lint                # ESLint + Stylelint checks
make lint-scripts        # JavaScript linting only
make lint-styles         # CSS linting only
```

## ANTI-PATTERNS (THIS DOMAIN)
**Asset Management:**
- DO NOT commit node_modules/ (use npm ci for reproducible builds)
- DO NOT modify priv/static/assets/ directly (they're generated)
- DO NOT bypass Tailwind content configuration (causes CSS purging issues)

**Development Workflow:**
- DO NOT use `npm run build` directly (use Mix tasks for integration)
- DO NOT disable watchers in development (breaks LiveView reloading)
- DO NOT ignore Stylelint/ESLint errors (maintains code quality)

**Configuration:**
- DO NOT change ESBuild output paths without updating Mix configuration
- DO NOT modify Tailwind content array without testing CSS purging
- DO NOT upgrade Tailwind without checking v4 compatibility

## NOTES
- Node.js 20.5.0+ and npm 9.8.0+ required (see .tool-versions)
- ESBuild version 0.16.4 configured for JSX/React support
- Tailwind v4.0.9 with @tailwindcss/forms plugin
- Generated assets served from `/assets/` endpoint with cache headers
- LiveView integration includes automatic CSRF protection and socket management
- All assets fingerprinted for production caching via digest

---

# GRAPHQL INTERFACE KNOWLEDGE BASE

**Generated:** 2026-01-05T17:32:00Z  
**Scope:** lib/ain_com_booking_graphql - Absinthe GraphQL API domain with security middleware and observability

## OVERVIEW
Absinthe-powered GraphQL API with comprehensive security phases, error reporting, and New Relic telemetry integration for enterprise booking system.

## STRUCTURE
```
lib/ain_com_booking_graphql/
├── application/             # GraphQL types and field definitions
├── middleware/             # Custom middleware for logging and error reporting
├── plugs/                  # Context building plug for request handling
├── ain_com_graphql.ex      # Main configuration and pipeline setup
├── router.ex              # Plug router with GraphQL endpoint forwarding
└── schema.ex              # Root schema with queries, mutations, and plugins
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| GraphQL schema definition | schema.ex | Root schema with Dataloader and New Relic plugins |
| Type definitions | application/types.ex | Application-level types and queries |
| Security pipeline | ain_com_graphql.ex | AbsintheSecurity phases and custom middleware |
| Endpoint routing | router.ex | `/graphql` endpoint without GraphiQL |
| Context building | plugs/context.ex | Request context preparation |
| Error handling | middleware/error_reporting.ex | Sentry integration for GraphQL errors |

## CONVENTIONS
**Schema Organization:**
- Types organized by domain in separate modules (e.g., Application.Types)
- Queries imported via `import_fields(:domain_queries)` pattern
- Dataloader configured for :repo source with Ecto backend
- New Relic middleware automatically injected before all middleware

**Security Pipeline:**
- AbsintheSecurity phases for depth, aliases, directives limits
- Introspection and field suggestions controlled by environment variables
- Custom middleware for operation logging and error reporting
- Token limits configurable via application configuration

**Middleware Stack:**
- OperationNameLogger sets Logger metadata for tracing
- ErrorReporting captures GraphQL errors in Sentry
- Pipeline phases inserted strategically around Result phase

## ANTI-PATTERNS (THIS DOMAIN)
**Schema Design:**
- DO NOT leave empty mutation blocks (invalid in Absinthe)
- DO NOT serve GraphiQL in production API (use standalone clients)
- DO NOT bypass security phases for any queries/mutations

**Error Handling:**
- DO NOT let GraphQL errors propagate without Sentry reporting
- DO NOT skip operation name logging for debugging
- DO NOT disable New Relic telemetry middleware

**Security:**
- DO NOT expose introspection in production unless explicitly enabled
- DO NOT increase token limits without security review
- DO NOT skip context building plug for request metadata

## NOTES
- Endpoint: `POST /graphql` (no GraphiQL interface provided)
- All entities use UUID primary keys (binary_id)
- Authentication context currently empty (TODO: implement auth)
- Comprehensive telemetry in Telemetry UI with GraphQL/Absinthe metrics
- Security limits: max aliases 100, max depth 100, max directives 100
- Environment variables: GRAPHQL_ENABLE_INTROSPECTION, GRAPHQL_ENABLE_FIELD_SUGGESTIONS