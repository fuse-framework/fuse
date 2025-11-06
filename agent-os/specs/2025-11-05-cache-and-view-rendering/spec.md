# Specification: Cache & View Rendering

## Goal
Implement pluggable cache manager with RAM provider and view rendering system that supports layout wrapping, helper methods, and convention-based view resolution to enable framework-wide caching and streamlined template rendering.

## User Stories
- As a developer, I want a simple cache interface so I can cache data without external dependencies
- As a developer, I want convention-based view rendering so handlers can return data and views are automatically resolved and wrapped in layouts

## Specific Requirements

**ICacheProvider Interface**
- Define interface contract with get(), set(), has(), delete(), clear() methods
- get() returns cached value or null if not found/expired
- set() accepts key, value, and TTL (seconds, 0 = no expiration)
- has() checks existence without returning value
- delete() removes single entry, clear() removes all entries
- Interface bound to implementation via DI container for pluggability

**RAMCacheProvider Implementation**
- Struct-based storage: `{key: {value, expiresAt}}` where expiresAt is date or null
- Lazy expiration cleanup during get() - check expiresAt < now(), delete if expired, return null
- Per-key thread-safe locking using `lock name="fuse_cache_{key}"` pattern
- No timer-based sweep to maintain small scope
- Default TTL configurable via Config (e.g., config.cache.defaultTTL)

**ViewRenderer Component**
- render() method accepts view path, locals struct, and optional layout name
- Convention-based view path resolution: GET /users/index -> views/users/index.cfm
- Layout wrapping with application.cfm default: check fileExists(views/layouts/application.cfm), wrap if exists
- No-layout fallback: render standalone if application.cfm missing
- Throw MissingTemplateException with attempted paths if view not found
- Isolated view execution context with helper methods and locals injected into scope

**Handler Return Value Processing**
- Support string return: `return "users/index"` (convention, implicit locals)
- Support struct return: `return {view: "users/index", locals: {user: user}, layout: "admin"}` (explicit control)
- Support null/void return: convention-based view from route name (GET /users/index -> views/users/index.cfm)
- layout: false in struct skips layout wrapping
- Dispatcher processes return value before onBeforeRender interceptor

**Helper Method System**
- addHelper() method on ViewRenderer registers helper functions by name
- Helpers scoped to view execution context (not global namespace pollution)
- Modules register helpers during boot() phase via viewRenderer.addHelper()
- Built-in helpers: h() for HTML escaping, linkTo() for route-based URL generation
- Helpers accessible in views via direct function call (injected into include context)

**Module Integration**
- CacheModule implements IModule, registers ICacheProvider -> RAMCacheProvider binding in register()
- ViewModule implements IModule, registers ViewRenderer singleton in register()
- ViewModule boot() method registers built-in helpers (h, linkTo)
- EventService integration: onBeforeRender interceptor point triggers view rendering
- ViewModule provides interceptor that reads event.result, calls ViewRenderer, sets event.response.body

**Event System Integration**
- Dispatcher adds onBeforeRender and onAfterRender phases (not yet implemented, will be added)
- onBeforeRender: event struct contains {result, route, params, request}
- ViewModule interceptor reads event.result, determines view path, calls ViewRenderer.render()
- Rendered HTML stored in event.response.body
- onAfterRender: post-rendering hook for fragment caching (future)

**Configuration Support**
- config.cache.defaultTTL: default TTL in seconds (0 = no expiration)
- config.cache.enabled: enable/disable caching globally (default true)
- config.views.path: base path for views (default: "/views")
- config.views.layoutPath: layout subdirectory (default: "/views/layouts")
- config.views.defaultLayout: default layout name (default: "application")

## Visual Design
No visual assets provided (backend infrastructure feature).

## Existing Code to Leverage

**Container Interface Binding Pattern**
- Use Container.singleton() to bind ICacheProvider -> RAMCacheProvider
- Pattern from Bootstrap.cfc: `container.singleton("eventService", function(c) { return new fuse.core.EventService(); })`
- Enables override via config or custom modules
- Property injection via `property name="cache" inject="ICacheProvider"`

**EventService Interceptor Registration**
- Use EventService.registerInterceptor(point, listener) from ViewModule.boot()
- Pattern: `eventService.registerInterceptor("onBeforeRender", function(event) { /* render logic */ })`
- Access event.result for handler return, event.route for path conventions
- Set event.response.body with rendered HTML

**Bootstrap Thread-Safe Singleton Pattern**
- Use double-checked locking for ViewRenderer initialization if needed
- Pattern from Bootstrap.initFramework(): check without lock, then lock and check again
- Lock name: `"fuse_cache_init"` or `"fuse_view_renderer_init"`

**ModuleRegistry Two-Phase Initialization**
- CacheModule and ViewModule follow IModule interface contract
- register() phase: bind services to container (no resolution)
- boot() phase: resolve dependencies, register helpers, register interceptors
- getDependencies() returns [] (no inter-module dependencies)
- getConfig() returns cache/view configuration structs

**Router Convention Patterns**
- Reuse Router.deriveHandlerName() logic for view path derivation
- GET /blog_posts/index -> views/blog_posts/index.cfm (underscore preserved)
- Named routes accessible via router.getNamedRoute(name) for linkTo helper

## Out of Scope
- Query caching integration (deferred to ActiveRecord roadmap item #5)
- Fragment caching (future enhancement beyond basic cache provider)
- View partials rendering (defer or implement as basic feature in future)
- Template compilation caching (performance optimization for future)
- Custom cache providers (Redis, Memcached - community-provided)
- Multiple layout support (only application.cfm, defer nested layouts)
- Asset pipeline integration (separate roadmap item)
- Cache statistics and monitoring (future enhancement)
- Advanced form helpers (defer to separate form builder module)
- View component architecture (.cfc views - future, only .cfm templates now)
