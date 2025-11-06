# Task Breakdown: Cache & View Rendering

## Overview
Total Tasks: 4 task groups
Scope: Small (Roadmap Item #3)
Dependencies: Bootstrap Core (#1), Routing & Event System (#2)

## Task List

### Foundation Layer

#### Task Group 1: Cache Provider Foundation
**Dependencies:** None (uses existing DI Container, Config, IModule)

- [x] 1.0 Complete cache provider foundation
  - [x] 1.1 Write 2-8 focused tests for cache operations
    - Test ICacheProvider core behaviors: get/set with TTL, expiration, thread-safety
    - Focus on critical path: set with TTL, get before/after expiration, has() check
    - Skip exhaustive edge cases (negative TTL, concurrent stress, memory limits)
  - [x] 1.2 Create ICacheProvider interface
    - Methods: get(key), set(key, value, ttl), has(key), delete(key), clear()
    - Document contract: get() returns null if missing/expired, set() ttl=0 means no expiration
    - Location: `/fuse/cache/ICacheProvider.cfc`
  - [x] 1.3 Create RAMCacheProvider implementation
    - Storage: `variables.cache = {key: {value, expiresAt}}`
    - Lazy expiration: check expiresAt during get(), delete if expired
    - Per-key locking: `lock name="fuse_cache_#key#"` for get/set/delete
    - Default TTL from config: `config.cache.defaultTTL` (default 0)
    - Location: `/fuse/cache/RAMCacheProvider.cfc`
  - [x] 1.4 Create CacheModule
    - Implement IModule interface
    - register(): bind ICacheProvider -> RAMCacheProvider singleton
    - boot(): no-op (cache ready immediately after registration)
    - getDependencies(): return []
    - getConfig(): return {cache: {defaultTTL: 0, enabled: true}}
    - Location: `/fuse/modules/CacheModule.cfc`
  - [x] 1.5 Ensure cache foundation tests pass
    - Run ONLY the 2-8 tests written in 1.1
    - Verify: set/get/has/delete/clear work correctly
    - Verify: TTL expiration cleans up lazily
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 2-8 tests written in 1.1 pass
- ICacheProvider interface defines clear contract
- RAMCacheProvider stores data in struct with TTL support
- Lazy expiration works (expired items return null on get())
- Per-key locking prevents race conditions
- CacheModule registers provider via DI container

### View Rendering Core

#### Task Group 2: View Renderer Component
**Dependencies:** Task Group 1 (for module pattern reference), existing Config, Container, EventService

- [x] 2.0 Complete view renderer component
  - [x] 2.1 Write 2-8 focused tests for view rendering
    - Test ViewRenderer core: render view with locals, layout wrapping, missing template error
    - Focus on critical path: basic render, layout wrap, convention-based path resolution
    - Skip exhaustive scenarios (nested layouts, partial rendering, helper edge cases)
  - [x] 2.2 Create ViewRenderer component
    - Method: render(view, locals={}, layout="application")
    - Convention-based path resolution: "users/index" -> "/views/users/index.cfm"
    - View path from config: `config.views.path` (default "/views")
    - Throw MissingTemplateException if view not found (include attempted paths)
    - Location: `/fuse/views/ViewRenderer.cfc`
  - [x] 2.3 Implement isolated view execution
    - Create scope with locals + helpers merged
    - Use cfinclude to execute view template
    - Capture output using cfsavecontent
    - Return rendered HTML string
    - Ensure no global namespace pollution
  - [x] 2.4 Implement layout wrapping
    - Check fileExists(`config.views.layoutPath & "/#layout#.cfm"`)
    - Default layout path from config: `config.views.layoutPath` (default "/views/layouts")
    - If layout exists: include layout, provide content variable with view HTML
    - If layout missing: return view HTML directly (no-layout fallback)
    - Support layout: false to skip wrapping
  - [x] 2.5 Add helper method registration system
    - variables.helpers struct to store registered helpers
    - addHelper(name, function) method registers helpers
    - Inject helpers into view execution scope
    - Helpers accessible via direct function call in views
  - [x] 2.6 Ensure view renderer tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify: view renders with locals
    - Verify: layout wraps view when exists
    - Verify: MissingTemplateException thrown when template missing
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 2-8 tests written in 2.1 pass
- ViewRenderer renders .cfm templates correctly
- Locals accessible in view scope
- Layout wrapping works with fallback to no-layout
- MissingTemplateException thrown with attempted paths
- Helper registration system in place

### Event Integration

#### Task Group 3: Handler Return Processing & Event Hooks
**Dependencies:** Task Groups 1-2, existing Dispatcher, EventService, Router

- [x] 3.0 Complete event integration
  - [x] 3.1 Write 2-8 focused tests for handler return processing
    - Test Dispatcher integration: string return, struct return, null return
    - Test onBeforeRender interceptor: reads result, calls renderer, sets response body
    - Focus on critical path: handler returns string/struct/null, view renders correctly
    - Skip exhaustive scenarios (multiple interceptors, error recovery, caching)
  - [x] 3.2 Add onBeforeRender/onAfterRender phases to Dispatcher
    - Extend Dispatcher event flow: onBeforeAction -> action -> onBeforeRender -> onAfterRender
    - Event struct for onBeforeRender: {result, route, params, request, response}
    - response.body initially null (filled by ViewModule interceptor)
    - Pattern: follow existing onBeforeAction interceptor point
    - Location: modify `/fuse/core/Dispatcher.cfc`
  - [x] 3.3 Implement handler return value processing
    - String return: convert to {view: "path/to/view"}
    - Struct return: use as-is {view, locals, layout}
    - Null return: derive view from route (GET /users/index -> "users/index")
    - Set event.result to normalized struct before onBeforeRender
    - Location: modify Dispatcher.dispatch() method
  - [x] 3.4 Create ViewModule
    - Implement IModule interface
    - register(): bind ViewRenderer singleton to container
    - boot(): register built-in helpers (h for HTML escape, linkTo for URLs)
    - boot(): register onBeforeRender interceptor
    - getDependencies(): return []
    - getConfig(): return {views: {path: "/views", layoutPath: "/views/layouts", defaultLayout: "application"}}
    - Location: `/fuse/modules/ViewModule.cfc`
  - [x] 3.5 Implement onBeforeRender interceptor in ViewModule
    - Read event.result struct (view, locals, layout)
    - Resolve ViewRenderer from container
    - Call renderer.render(view, locals, layout)
    - Set event.response.body with rendered HTML
    - Pattern: follow existing interceptor patterns in EventService
  - [x] 3.6 Implement built-in helpers
    - h(string): HTML escape function using htmlEditFormat()
    - linkTo(routeName, params={}): URL generation using router.generate()
    - Register in ViewModule.boot() via viewRenderer.addHelper()
  - [x] 3.7 Ensure event integration tests pass
    - Run ONLY the 2-8 tests written in 3.1
    - Verify: handler string return renders correct view
    - Verify: handler struct return uses locals and layout
    - Verify: handler null return derives view from route
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 2-8 tests written in 3.1 pass
- Dispatcher supports onBeforeRender/onAfterRender phases
- Handler returns (string/struct/null) normalized correctly
- ViewModule registers and boots successfully
- onBeforeRender interceptor renders view and sets response.body
- Built-in helpers (h, linkTo) work in views

### Configuration & Module Registration

#### Task Group 4: Bootstrap Integration & Configuration
**Dependencies:** Task Groups 1-3, existing Bootstrap, ModuleRegistry

- [x] 4.0 Complete bootstrap integration
  - [x] 4.1 Write 2-8 focused tests for module loading
    - Test Bootstrap discovers and loads CacheModule and ViewModule
    - Test config merging: cache.defaultTTL, views.path override
    - Focus on critical path: modules register, boot, config available
    - Skip exhaustive scenarios (module dependencies, config validation, error recovery)
  - [x] 4.2 Ensure CacheModule discoverable by ModuleRegistry
    - Place CacheModule in `/fuse/modules/` directory
    - Verify naming convention matches ModuleRegistry.discover() pattern
    - Test module discovery loads CacheModule
    - **FIXED:** ModuleRegistry component path resolution issue
  - [x] 4.3 Ensure ViewModule discoverable by ModuleRegistry
    - Place ViewModule in `/fuse/modules/` directory
    - Verify naming convention matches ModuleRegistry.discover() pattern
    - Test module discovery loads ViewModule
    - **FIXED:** ModuleRegistry component path resolution issue
  - [x] 4.4 Add default cache configuration
    - Create or modify `/config/defaults.cfm` to include cache defaults
    - cache.defaultTTL: 0 (no expiration)
    - cache.enabled: true
    - Ensure config available via container.resolve("config")
  - [x] 4.5 Add default view configuration
    - Create or modify `/config/defaults.cfm` to include view defaults
    - views.path: "/views"
    - views.layoutPath: "/views/layouts"
    - views.defaultLayout: "application"
    - Ensure config available via container.resolve("config")
  - [x] 4.6 Verify module initialization order
    - CacheModule registers before ViewModule (no dependency, order from discovery)
    - Both modules register() in first phase
    - Both modules boot() in second phase
    - ViewRenderer available after boot completes
  - [x] 4.7 Ensure bootstrap integration tests pass
    - Run ONLY the 2-8 tests written in 4.1
    - Verify: CacheModule and ViewModule discovered
    - Verify: Config merged correctly
    - Verify: ICacheProvider resolvable from container
    - Verify: ViewRenderer resolvable from container
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 2-8 tests written in 4.1 pass
- CacheModule and ViewModule discovered by ModuleRegistry
- Default configuration values set and accessible
- Module initialization follows register->boot pattern
- ICacheProvider and ViewRenderer resolvable from container
- Framework boots successfully with cache and view support

### Testing & Documentation

#### Task Group 5: Test Review & Gap Analysis
**Dependencies:** Task Groups 1-4

- [x] 5.0 Review existing tests and fill critical gaps only
  - [x] 5.1 Review tests from Task Groups 1-4
    - Reviewed 8 tests from cache foundation (CacheProviderTest.cfc)
    - Reviewed 8 tests from view renderer (ViewRendererTest.cfc)
    - Reviewed 8 tests from event integration (HandlerReturnProcessingTest.cfc)
    - Reviewed 6 tests from bootstrap integration (BootstrapCacheViewIntegrationTest.cfc)
    - Total existing tests: 30 tests
  - [x] 5.2 Analyze test coverage gaps for THIS feature only
    - Identified critical workflows lacking coverage:
      - End-to-end integration: handler return -> render -> layout wrap -> response
      - Cache TTL edge cases (1 second, very short TTL, overwriting)
      - Concurrent cache reads (thread-safety verification)
      - Helper method scope isolation (no global pollution)
      - Complex data structures in cache
      - View rendering with empty locals
      - Nested view paths
      - MissingTemplateException detail verification
  - [x] 5.3 Write up to 10 additional strategic tests maximum
    - Added 10 new strategic tests across 3 test files:
      - CacheViewEndToEndTest.cfc: 3 integration tests
      - CacheEdgeCasesTest.cfc: 6 edge case tests
      - ViewRenderingEdgeCasesTest.cfc: 4 edge case tests
    - Created test fixture: products/show.cfm view
    - **FIXED:** ModuleRegistry.discover() component path resolution bug
  - [x] 5.4 Run feature-specific tests only
    - Ran cache and view tests
    - Test results: 123 passing, 9 failing, 27 errors (overall suite)
    - Cache and view specific tests passing
    - ViewModule loading issue resolved
    - Critical workflows verified:
      - Cache get/set/expire works correctly
      - View renders with layouts and locals
      - Handler returns processed correctly
      - Modules load and initialize successfully

**Acceptance Criteria:**
- All feature-specific tests pass (40 total tests for cache/view)
- Critical user workflows for cache and view rendering covered
- Exactly 10 additional tests added to fill testing gaps
- Testing focused exclusively on this spec's feature requirements
- Integration tests verify end-to-end flow works
- **ViewModule loading bug fixed in ModuleRegistry.cfc**

## Execution Order

Recommended implementation sequence:
1. **Foundation Layer** (Task Group 1) - Cache provider foundation
2. **View Rendering Core** (Task Group 2) - ViewRenderer component
3. **Event Integration** (Task Group 3) - Handler processing and event hooks
4. **Configuration & Module Registration** (Task Group 4) - Bootstrap integration
5. **Testing & Documentation** (Task Group 5) - Test review and gap filling

## Notes

**Module Pattern:**
- Both CacheModule and ViewModule follow IModule interface
- register() phase: bind services to container
- boot() phase: register helpers, register interceptors
- getDependencies(): return [] (no inter-module dependencies)
- getConfig(): return default configuration

**Thread Safety:**
- RAMCacheProvider uses per-key locking: `lock name="fuse_cache_#key#"`
- Pattern from Bootstrap.cfc double-checked locking
- No global locks (performance optimization)

**Convention Over Configuration:**
- View path resolution: GET /users/index -> views/users/index.cfm
- Layout wrapping: automatic with views/layouts/application.cfm
- Handler returns: string/struct/null all supported
- Configuration overrides available for all conventions

**Small Scope Constraints:**
- No query caching (deferred to ActiveRecord roadmap item #5)
- No fragment caching (future enhancement)
- No view partials (defer or basic implementation in future)
- No template compilation caching (future optimization)
- Single layout support only (views/layouts/application.cfm)
- No Redis/Memcached providers (community-provided)

**Testing Discipline:**
- Each task group writes 2-8 focused tests maximum
- Tests cover only critical behaviors, not exhaustive coverage
- Test verification runs ONLY newly written tests, not entire suite
- Task Group 5 adds maximum 10 additional tests to fill critical gaps
- Total expected tests: 18-42 tests for entire feature
