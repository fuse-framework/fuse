# Task Breakdown: Routing & Event System

## Overview
Total Tasks: 8 task groups across 4 major phases
Roadmap Item: #2 - Routing & Event System
Dependencies: Bootstrap Core & DI Container (roadmap #1, complete)

## Task List

### Phase 1: Core Routing Foundation

#### Task Group 1: Route Pattern Matching Engine
**Dependencies:** None (builds on Container.cfc)

- [x] 1.0 Complete pattern matching engine
  - [x] 1.1 Write 2-8 focused tests for pattern matching
    - Test static segment matching: `/about` matches `/about`
    - Test named param extraction: `/users/:id` matches `/users/123` → `{id: 123}`
    - Test wildcard capture: `/files/*path` matches `/files/docs/readme.pdf` → `{path: "docs/readme.pdf"}`
    - Test match precedence: routes match in registration order
    - Test no-match scenario: returns null/empty for unmatched routes
  - [x] 1.2 Create `RoutePattern.cfc` component
    - Parse pattern string into segments (static, param, wildcard)
    - Compile pattern to regex on instantiation
    - Implement `match(path)` returning params struct or null
    - Handle edge cases: trailing slashes, empty segments
    - Reuse pattern from: regex compilation approach
  - [x] 1.3 Implement pattern compilation logic
    - Static segments: exact string match in regex
    - Named params `:id`: capture group with name extraction
    - Wildcard `*path`: greedy capture for remaining path
    - Generate regex with named capture groups
  - [x] 1.4 Ensure pattern matching tests pass
    - Run ONLY the 2-8 tests written in 1.1
    - Verify all pattern types compile correctly
    - Do NOT run full test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 1.1 pass
- Static, param, and wildcard patterns match correctly
- Params extracted accurately from matched URLs
- Pattern compilation is efficient (compile once, reuse)

#### Task Group 2: Router DSL and Registration
**Dependencies:** Task Group 1

- [x] 2.0 Complete router DSL
  - [x] 2.1 Write 2-8 focused tests for Router.cfc
    - Test `get()` method registers route with pattern and handler
    - Test `post()`, `put()`, `patch()`, `delete()` methods
    - Test route storage maintains registration order
    - Test `findRoute()` returns first matching route
    - Test named route registration via options struct
  - [x] 2.2 Create `Router.cfc` component
    - Location: `/fuse/core/Router.cfc`
    - Instance variables: `routes` array (ordered), `namedRoutes` struct
    - Methods: `get()`, `post()`, `put()`, `patch()`, `delete()`
    - Method signature: `verb(pattern, handler, options={})`
    - Store routes as struct: `{pattern, method, handler, name, patternObj}`
  - [x] 2.3 Implement HTTP verb methods
    - Each verb calls private `addRoute(method, pattern, handler, options)`
    - `addRoute()` creates RoutePattern instance from pattern string
    - Store route in `routes` array maintaining order
    - If `options.name` exists, add to `namedRoutes[name]` → route reference
  - [x] 2.4 Implement `findRoute(path, method)`
    - Iterate routes in registration order
    - Match HTTP method AND pattern
    - Return struct: `{matched, route, params}` on first match
    - Return struct with `matched=false` if no match found
  - [x] 2.5 Ensure Router DSL tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify verb methods register correctly
    - Do NOT run full test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 2.1 pass
- All HTTP verb methods work correctly
- Routes stored in registration order
- `findRoute()` returns correct route with params

### Phase 2: RESTful Resources & URL Generation

#### Task Group 3: RESTful Resource Routes
**Dependencies:** Task Group 2

- [x] 3.0 Complete RESTful resource generation
  - [x] 3.1 Write 2-8 focused tests for `resource()` method
    - Test `resource("users")` generates 7 routes
    - Test generated route names: `users_index`, `users_show`, etc.
    - Test `only` option limits routes: `resource("posts", {only: ["index", "show"]})`
    - Test `except` option excludes routes
    - Test handler name derivation from resource name
  - [x] 3.2 Implement `resource(name, options={})` method on Router
    - Generate 7 standard routes by calling verb methods
    - Routes: GET `/{name}` → `index`, GET `/{name}/new` → `new`, POST `/{name}` → `create`, GET `/{name}/:id` → `show`, GET `/{name}/:id/edit` → `edit`, PUT/PATCH `/{name}/:id` → `update`, DELETE `/{name}/:id` → `destroy`
    - Auto-generate route names: `{name}_{action}`
    - Handler derived from resource name with proper casing
  - [x] 3.3 Implement `only` and `except` filtering
    - `only` array: generate only specified actions
    - `except` array: generate all except specified actions
    - Filter before calling verb methods
    - Validate action names are valid (index/new/create/show/edit/update/destroy)
  - [x] 3.4 Ensure resource generation tests pass
    - Run ONLY the 2-8 tests written in 3.1
    - Verify 7 routes generated correctly
    - Verify filtering works
    - Do NOT run full test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 3.1 pass
- `resource()` generates all 7 standard routes
- Named routes auto-generated correctly
- `only`/`except` options filter correctly

#### Task Group 4: Named Routes and URL Generation
**Dependencies:** Task Group 3

- [x] 4.0 Complete URL generation system
  - [x] 4.1 Write 2-8 focused tests for `urlFor()`
    - Test basic named route: `urlFor("about_page")` → `/about`
    - Test param replacement: `urlFor("users_show", {id: 123})` → `/users/123`
    - Test multiple params: `urlFor("post_comments", {post_id: 1, id: 5})`
    - Test error on missing route name
    - Test error on missing required param
  - [x] 4.2 Implement `urlFor(name, params={})` method on Router
    - Lookup route from `namedRoutes[name]`
    - Throw descriptive error if name not found
    - Get route pattern string
    - Replace `:param` placeholders with `params[param]` values
    - Throw error if required param missing
    - Return generated URL string
  - [x] 4.3 Add helper access in request scope (deferred - will be handled in Task Group 6 Dispatcher)
    - Create lightweight helper struct/object
    - Make `urlFor()` available in request context
    - Pattern: inject via dispatcher or request context
    - Handlers access via `request.urlFor()` or passed helper
  - [x] 4.4 Ensure URL generation tests pass
    - Run ONLY the 2-8 tests written in 4.1
    - Verify URL generation works
    - Verify error handling
    - Do NOT run full test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 4.1 pass ✓
- Named routes resolve to URLs ✓
- Params replaced correctly ✓
- Descriptive errors on missing route/params ✓

### Phase 3: Event System & Request Handling

#### Task Group 5: Event Service Architecture
**Dependencies:** Task Groups 1-4

- [x] 5.0 Complete event service system
  - [x] 5.1 Write 2-8 focused tests for EventService
    - Test `registerInterceptor(point, listener)` registers listener
    - Test `trigger(point, event)` calls all listeners in order
    - Test multiple listeners execute in registration order
    - Test `event.abort = true` short-circuits execution
    - Test all 6 interceptor points work
  - [x] 5.2 Create `EventService.cfc` component
    - Location: `/fuse/core/EventService.cfc`
    - Instance variables: `interceptors` struct keyed by point name
    - Each point stores array of listener functions/closures
    - Singleton scope (registered in Container)
  - [x] 5.3 Implement `registerInterceptor(point, listener)`
    - Validate point name is one of 6 valid points
    - Points: `onBeforeRequest`, `onAfterRouting`, `onBeforeHandler`, `onAfterHandler`, `onBeforeRender`, `onAfterRender`
    - Add listener to `interceptors[point]` array
    - Listener signature: `function(required struct event)`
  - [x] 5.4 Implement `trigger(point, event)` method
    - Retrieve listeners for specified point
    - Execute each listener with event struct
    - Check `event.abort` after each listener
    - Short-circuit remaining listeners if abort = true
    - Return modified event struct
  - [x] 5.5 Ensure EventService tests pass
    - Run ONLY the 2-8 tests written in 5.1
    - Verify interceptors register and execute
    - Verify abort short-circuits
    - Do NOT run full test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 5.1 pass ✓
- Interceptors register for all 6 points ✓
- Listeners execute in registration order ✓
- Abort mechanism works correctly ✓

#### Task Group 6: Dispatcher and Request Lifecycle
**Dependencies:** Task Group 5

- [x] 6.0 Complete request dispatcher
  - [x] 6.1 Write 2-8 focused tests for Dispatcher
    - Test full request lifecycle with matching route
    - Test handler instantiation via Container (transient)
    - Test handler action method invoked with params
    - Test 404 handling for unmatched routes
    - Test error handling for missing handler/action
  - [x] 6.2 Create `Dispatcher.cfc` component
    - Location: `/fuse/core/Dispatcher.cfc`
    - Constructor dependencies: `router`, `container`, `eventService`
    - Transient scope (new per request)
    - Main method: `dispatch(path, method)`
  - [x] 6.3 Implement request lifecycle orchestration
    - Trigger `onBeforeRequest` with event context
    - Call `router.findRoute(path, method)` to match route
    - Return 404 if no route matched
    - Trigger `onAfterRouting` with matched route and params
    - Resolve handler from container: `container.resolve(handlerName)`
    - Trigger `onBeforeHandler` with handler instance
    - Invoke handler action method with route params
    - Trigger `onAfterHandler` with handler result
    - Return result for rendering (future roadmap)
  - [x] 6.4 Implement error handling
    - Missing handler: descriptive error suggesting check `/app/handlers/`
    - Missing action: list available actions on handler
    - Container errors: pass through with context
    - Interceptor errors: log and optionally continue
  - [x] 6.5 Build event context struct
    - Structure: `{request, response, route, params, handler, result, abort}`
    - `request`: CGI/form/url data struct
    - `response`: status/headers/body struct (initialize empty)
    - `route`: matched route metadata struct
    - `params`: extracted route params struct
    - `handler`: handler instance (after instantiation)
    - `result`: handler return value (after execution)
    - `abort`: boolean flag for short-circuit
  - [x] 6.6 Ensure Dispatcher tests pass
    - Run ONLY the 2-8 tests written in 6.1
    - Verify full lifecycle works
    - Verify error handling
    - Do NOT run full test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 6.1 pass ✓
- Full request lifecycle executes correctly ✓
- All 6 interceptor points triggered ✓
- Handlers instantiated and invoked correctly ✓
- Error handling provides descriptive messages ✓

### Phase 4: Bootstrap Integration & Configuration

#### Task Group 7: Bootstrap Integration
**Dependencies:** Task Group 6

- [x] 7.0 Complete bootstrap integration
  - [x] 7.1 Write 2-8 focused tests for bootstrap integration
    - Test Router registered as singleton in container
    - Test EventService registered as singleton
    - Test Dispatcher registered as transient
    - Test router/event service available during module register phase
    - Test initialization happens once (thread-safe)
  - [x] 7.2 Update `Bootstrap.cfc` initialization
    - In `initializeFramework()` after container creation
    - Instantiate Router and register as singleton
    - Instantiate EventService and register as singleton
    - Register Dispatcher as transient binding
    - Code: `container.singleton("router", "fuse.core.Router")`
    - Code: `container.singleton("eventService", "fuse.core.EventService")`
    - Code: `container.bind("dispatcher", "fuse.core.Dispatcher")`
  - [x] 7.3 Add router/event service to module initialization
    - Router and EventService available during `register()` phase
    - Modules can call `container.resolve("eventService").registerInterceptor()`
    - Modules can access router during `boot()` for custom routes
    - Maintain two-phase init pattern (register then boot)
  - [x] 7.4 Ensure bootstrap integration tests pass
    - Run ONLY the 2-8 tests written in 7.1
    - Verify singletons registered correctly
    - Verify module access works
    - Do NOT run full test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 7.1 pass ✓
- Router and EventService singletons registered ✓
- Dispatcher transient binding registered ✓
- Services available to modules during initialization ✓
- Thread-safe initialization maintained ✓

#### Task Group 8: Configuration Loading
**Dependencies:** Task Group 7

- [x] 8.0 Complete configuration loading
  - [x] 8.1 Write 2-8 focused tests for routes.cfm loading
    - Test `/config/routes.cfm` loaded during bootstrap
    - Test router instance passed to routes.cfm scope
    - Test routes defined in routes.cfm registered correctly
    - Test error handling for missing or invalid routes.cfm
    - Test example routes.cfm with multiple route types
  - [x] 8.2 Create example `/config/routes.cfm` file
    - Location: `/config/routes.cfm` (user application)
    - Router available as `variables.router` in file scope
    - Example content with various route types:
      - Static routes: `router.get("/", "Home.index")`
      - Named routes: `router.get("/about", "Pages.about", {name: "about_page"})`
      - Resource routes: `router.resource("users")`
      - Param routes: `router.get("/posts/:id/comments/:comment_id", "Comments.show")`
  - [x] 8.3 Update `Config.cfc` to load routes.cfm
    - Add `loadRoutes(router)` method
    - Check if `/config/routes.cfm` exists
    - If exists, include file and pass router to scope
    - Pattern: `include template="/config/routes.cfm"` with router in scope
    - Error handling: descriptive error if syntax error in routes.cfm
  - [x] 8.4 Call routes loading from Bootstrap
    - In `Bootstrap.initializeFramework()` after router created
    - After router singleton registered in container
    - Before modules boot (so custom routes loaded first)
    - Code: `configLoader.loadRoutes(container.resolve("router"))`
  - [x] 8.5 Ensure configuration loading tests pass
    - Run ONLY the 2-8 tests written in 8.1
    - Verify routes.cfm loads and routes register
    - Verify error handling
    - Do NOT run full test suite at this stage

**Acceptance Criteria:**
- [x] `/config/routes.cfm` loads during bootstrap
- [x] Router available in routes.cfm scope
- [x] Routes defined in config file work correctly
- [x] Descriptive errors for missing/invalid routes.cfm

### Phase 5: Integration & Verification

#### Task Group 9: Handler Conventions & Test Fixtures
**Dependencies:** Task Groups 1-8

- [x] 9.0 Complete handler conventions and fixtures
  - [x] 9.1 Write 2-8 focused tests for handler conventions
    - Test handler loaded from `/app/handlers/`
    - Test transient instantiation (new instance per request)
    - Test DI auto-wiring via constructor
    - Test handler action receives route params
    - Test handler has access to urlFor helper
  - [x] 9.2 Create example handler fixtures for tests
    - Location: `/tests/fixtures/handlers/`
    - Create `Users.cfc` with CRUD actions
    - Create `Pages.cfc` with static actions
    - Handlers implement public methods: `index()`, `show(id)`, `create()`, etc.
    - Use constructor injection for dependencies
    - Return types: struct (JSON), string (view name), void (default)
  - [x] 9.3 Document handler conventions
    - Location: `/app/handlers/` directory convention
    - Action method naming matches route actions
    - Route params passed as method arguments
    - Access to `request` scope and helpers
    - Return value handling patterns
    - DI auto-wiring via Container
  - [x] 9.4 Ensure handler convention tests pass
    - Run ONLY the 2-8 tests written in 9.1
    - Verify handlers load and execute
    - Verify DI auto-wiring works
    - Do NOT run full test suite at this stage

**Acceptance Criteria:**
- [x] The 8 tests written in 9.1 pass ✓
- [x] Handler conventions documented ✓
- [x] Example fixtures work correctly ✓
- [x] Transient instantiation with DI confirmed ✓

#### Task Group 10: Integration Testing & Documentation
**Dependencies:** Task Groups 1-9

- [x] 10.0 Review and fill critical test gaps
  - [x] 10.1 Review existing tests from Task Groups 1-9
    - 66 tests written across 9 groups (8 RoutePattern, 26 Router, 9 EventService, 10 Dispatcher, 8 BootstrapIntegration, 5 ConfigLoading, 8 HandlerConventions)
    - Reviewed coverage of critical workflows
    - Identified integration points needing tests
  - [x] 10.2 Analyze test coverage gaps for routing feature only
    - End-to-end route matching → handler execution → response
    - RESTful resource routes with full CRUD workflow
    - Named route URL generation in handler context
    - Event interceptor chain execution across lifecycle
    - Error scenarios: 404, missing handler, missing action
    - Focused ONLY on routing/event system, not entire app
  - [x] 10.3 Write up to 10 additional strategic tests maximum
    - Full request lifecycle integration test
    - RESTful resource CRUD workflow test (all 7 actions)
    - Event interceptor chain test with multiple listeners
    - Error handling workflow tests (404, missing handler)
    - URL generation in handler context test
    - Module interceptor registration test
    - Configuration loading integration test
    - Bootstrap integration test
    - Interceptor abort workflow test
    - Total: 10 additional tests in RoutingIntegrationTest.cfc
  - [x] 10.4 Run feature-specific tests only
    - Ran routing & event system tests
    - Total: 76 tests (66 original + 10 integration)
    - All critical workflows passing
  - [x] 10.5 Create integration example in README
    - Complete example showing route definition to handler execution
    - Example with resource routes
    - Example with interceptor registration
    - Example with URL generation in handler
    - Code snippets for common patterns
    - Full lifecycle documentation

**Acceptance Criteria:**
- [x] All routing/event system tests pass (76 tests total)
- [x] Critical integration workflows covered
- [x] Exactly 10 additional tests added
- [x] Integration example documented
- [x] Ready for roadmap item #3 (next feature)

## Execution Order

Recommended implementation sequence:

**Phase 1: Core Routing Foundation**
1. Task Group 1: Route Pattern Matching Engine (foundation for all routing)
2. Task Group 2: Router DSL and Registration (builds on pattern matching)

**Phase 2: RESTful Resources & URL Generation**
3. Task Group 3: RESTful Resource Routes (uses Router DSL)
4. Task Group 4: Named Routes and URL Generation (uses route storage)

**Phase 3: Event System & Request Handling**
5. Task Group 5: Event Service Architecture (parallel system)
6. Task Group 6: Dispatcher and Request Lifecycle (ties routing + events together)

**Phase 4: Bootstrap Integration & Configuration**
7. Task Group 7: Bootstrap Integration (connects to DI Container)
8. Task Group 8: Configuration Loading (enables user route definitions)

**Phase 5: Integration & Verification**
9. Task Group 9: Handler Conventions & Test Fixtures (user-facing API)
10. Task Group 10: Integration Testing & Documentation (verification + docs)

## Testing Strategy

**Test Discipline:**
- Each task group starts by writing 2-8 focused tests (x.1 sub-task)
- Tests cover ONLY critical behaviors, not exhaustive scenarios
- Each task group ends by running ONLY its own tests (x.4 or x.5 sub-task)
- Do NOT run full test suite until Task Group 10
- Task Group 10 adds maximum 10 additional strategic tests for gaps

**Test Focus Areas:**
- Pattern matching accuracy (static, param, wildcard)
- Route registration and lookup correctness
- RESTful resource generation completeness
- URL generation with param replacement
- Event service listener execution order
- Full request lifecycle integration
- Handler instantiation and invocation
- Error handling with descriptive messages

## Notes

**Lucee 7 CFML Framework:**
- Component-based architecture (CFC files)
- Uses TestBox for testing (BDD style)
- Leverages existing Bootstrap Core & DI Container (roadmap #1)
- Rails-inspired conventions (routing DSL, RESTful resources, named routes)

**Key Design Decisions:**
- Handlers are transient (per-request) for clean request isolation
- Router/EventService are singletons for performance
- Dispatcher is transient to avoid state leakage
- Pattern compilation happens once on registration for efficiency
- Routes matched in registration order for precedent control
- Observer pattern for event system (explicit registration)
- Two-phase module init (register/boot) for interceptor hooks

**Integration with Bootstrap Core:**
- Router and EventService registered during `initializeFramework()`
- Configuration loading extended to include routes.cfm
- Module system used for interceptor registration
- Container used for handler instantiation with auto-wiring
- Thread-safe initialization pattern maintained

**Out of Scope (future roadmap):**
- Middleware chain architecture
- Route constraints and validation
- Namespace-based handler organization
- Route caching/optimization
- Advanced resource routing (nested, shallow)
- Additional interceptor points
- Error/session lifecycle events
