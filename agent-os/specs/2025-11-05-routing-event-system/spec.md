# Specification: Routing & Event System

## Goal
Build Rails-inspired routing system with pattern matching, RESTful resource routes, named route helpers, and event service with interceptor points for request lifecycle management.

## User Stories
- As a developer, I want to define routes in `/config/routes.cfm` using an intuitive DSL so that I can map URLs to handler actions
- As a developer, I want RESTful resource routes auto-generated so that I can build CRUD interfaces with minimal configuration
- As a developer, I want named route helpers like `urlFor()` so that I can generate URLs without hardcoding paths

## Specific Requirements

**Route Definition DSL**
- Create `Router.cfc` component providing fluent API for route registration
- Support HTTP verb methods: `get()`, `post()`, `put()`, `patch()`, `delete()`
- Route signature: `router.get(pattern, handler, options)` where pattern is URL string, handler is "HandlerName.actionMethod", options is struct with optional `name` key
- Load `/config/routes.cfm` during bootstrap initialization, passing router instance to file scope
- Store routes in ordered struct maintaining registration order for matching precedence
- Register router as singleton in DI container for access by framework components

**Pattern Matching Engine**
- Static segments: exact match `/about`, `/users/new`
- Named parameters: `:id` style extracts value `/users/:id` matches `/users/123` extracting `{id: 123}`
- Wildcard segments: `*path` captures remaining path `/files/*path` matches `/files/docs/readme.pdf` extracting `{path: "docs/readme.pdf"}`
- Compile patterns to regex on registration for efficient matching
- Match routes in registration order, return first match
- Extract parameters into struct passed to handler
- Return 404 if no route matches request path and method

**RESTful Resource Routes**
- Single method `resource(name, options)` generates 7 standard routes
- Generated routes: `GET /{name}` → `index`, `GET /{name}/new` → `new`, `POST /{name}` → `create`, `GET /{name}/:id` → `show`, `GET /{name}/:id/edit` → `edit`, `PUT/PATCH /{name}/:id` → `update`, `DELETE /{name}/:id` → `destroy`
- Handler name derived from resource name with proper casing
- Auto-generate route names: `{name}_index`, `{name}_new`, `{name}_create`, `{name}_show`, `{name}_edit`, `{name}_update`, `{name}_destroy`
- Options struct supports `only` and `except` arrays to limit routes generated
- Internally calls verb methods (`get()`, `post()`, etc.) to maintain consistency

**Named Routes and URL Generation**
- Auto-assign names to resource routes following pattern `{resource}_{action}`
- Support explicit naming via options: `router.get("/about", "Pages.about", {name: "about_page"})`
- Store bidirectional mapping: route name → pattern, pattern → route metadata
- Implement `urlFor(name, params)` helper method that returns URL string
- Replace pattern placeholders with param values: `urlFor("users_show", {id: 123})` returns `/users/123`
- Make `urlFor()` available in request scope for handlers and views to access
- Throw descriptive error if named route not found or required param missing

**Handler Conventions and Loading**
- Handlers located at `/app/handlers/{HandlerName}.cfc`
- Handler naming matches route declaration (singular or plural, developer choice)
- Actions are public methods matching action names: `index()`, `show()`, `create()`, etc.
- Transient scope: instantiate fresh handler per request via DI container
- Auto-wire dependencies via constructor injection (matching DI container pattern)
- Pass route params as method arguments or via request context struct
- Return value handling: struct for JSON responses, string for view names, void for default view
- Handlers have access to `request`, `response`, and `urlFor()` helper

**Event Service Architecture**
- Create `EventService.cfc` singleton managing interceptor registration and execution
- Six interceptor points: `onBeforeRequest` (before routing), `onAfterRouting` (route matched), `onBeforeHandler` (before action), `onAfterHandler` (after action), `onBeforeRender` (before view), `onAfterRender` (after view)
- Interceptors receive `event` struct containing: `request` (CGI/form/url data), `response` (status/headers/body), `route` (matched route metadata), `params` (extracted route params), `handler` (handler instance after instantiation), `result` (handler return value after execution)
- Support multiple interceptors per point, execute in registration order
- Observer pattern: modules register interceptors via `IModule.register()` method
- Interceptor signature: `function interceptorMethod(required struct event)` returning void or modified event struct
- Short-circuit support: interceptor can set `event.abort = true` to halt request processing

**Route Matching and Dispatch**
- Create `Dispatcher.cfc` component orchestrating request handling
- Match incoming request path and HTTP method against registered routes
- Extract route parameters from URL based on pattern placeholders
- Resolve handler from DI container using transient scope (new instance per request)
- Invoke handler action method with route params as arguments
- Handle missing handlers with descriptive error (suggest checking handler location)
- Handle missing actions with descriptive error (list available actions on handler)
- Return handler result to rendering pipeline

**Integration with Bootstrap Core**
- Bootstrap initialization calls router setup after DI container ready
- Router registered as singleton binding: `container.singleton("router", "fuse.core.Router")`
- EventService registered as singleton: `container.singleton("eventService", "fuse.core.EventService")`
- Dispatcher registered as transient: `container.bind("dispatcher", "fuse.core.Dispatcher")`
- Modules register interceptors during `register()` phase via event service
- Configuration loading pattern: `configLoader.load()` extended to load routes.cfm
- Thread-safe initialization: router setup happens once during bootstrap lock

**Request Lifecycle Flow**
- Application.cfc onRequest() calls dispatcher with request path and method
- Dispatcher triggers `onBeforeRequest` interceptors with event context
- Dispatcher matches route using router pattern matching engine
- Dispatcher triggers `onAfterRouting` with matched route and params
- Dispatcher resolves handler from container (transient, auto-wired)
- Dispatcher triggers `onBeforeHandler` with handler instance in event
- Dispatcher invokes handler action method with route params
- Dispatcher triggers `onAfterHandler` with handler result in event
- Rendering pipeline (future roadmap) triggers `onBeforeRender` and `onAfterRender`
- Response sent to client

## Existing Code to Leverage

**Container.cfc - DI Container**
- Transient binding support via `bind()` for per-request handler instantiation
- Singleton binding via `singleton()` for router and event service
- Constructor auto-wiring via `resolveConstructorDependencies()` for handler dependencies
- Property injection support for handlers needing framework services
- Use `resolve()` method in dispatcher to instantiate handlers

**Bootstrap.cfc - Initialization Pattern**
- Two-phase initialization (register then boot) applies to routing setup
- Thread-safe double-checked locking for router singleton initialization
- `initializeFramework()` private method extended to setup router and event service
- Configuration loading pattern reused for routes.cfm file loading
- Module initialization pattern: router/dispatcher/event service registered during bootstrap

**ModuleRegistry.cfc - Module System**
- `IModule.register()` method used by modules to register interceptors with event service
- Two-phase init (register/boot) ensures event service available during module registration
- Module dependency resolution ensures interceptors registered in correct order
- Leverage existing module discovery and loading for interceptor registration

**IModule.cfc Interface**
- `register(container)` method: modules call `container.resolve("eventService").registerInterceptor()`
- `boot(container)` method: modules can resolve router for adding custom routes
- Existing interface supports interceptor registration without modification
- Module config merged into app config applies to route-specific settings

**Config.cfc - Configuration Loading**
- Extend to load `/config/routes.cfm` file during bootstrap
- Pass router instance to routes.cfm for DSL access
- Environment-aware loading: routes can vary by environment if needed
- Error handling pattern: descriptive errors if routes.cfm syntax invalid

## Out of Scope
- Middleware chain architecture (separate roadmap item)
- Route constraints (regex validation, domain matching, HTTP method filters beyond basic verb support)
- Namespace-based handler organization (`/app/handlers/admin/`, `/app/handlers/api/`)
- Route parameter type validation and coercion (`:id` must be numeric)
- Route caching and compilation optimization for production
- Advanced resource routing (nested resources, shallow routes, member/collection routes)
- Custom interceptor points beyond the six specified
- Error handling interceptors (`afterError`, `onException`)
- Session lifecycle events (`onSessionStart`, `onSessionEnd`)
- API versioning routes (`/api/v1/`, `/api/v2/`)
- Route prefixing and grouping with shared configuration
- Route subdomain matching
- Route format extensions (`.json`, `.xml` suffixes)
- CSRF protection integration (separate roadmap item)
- Rate limiting per route (separate roadmap item)
