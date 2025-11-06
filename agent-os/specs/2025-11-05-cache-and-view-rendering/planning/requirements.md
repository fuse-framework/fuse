# Spec Requirements: Cache & View Rendering

## Initial Description

Roadmap item #3 (S - Small scope):
Cache & View Rendering — Pluggable cache manager with ICacheProvider interface, RAM cache provider implementation, view renderer with layout wrapping, helper method system for views

## Product Context

**Mission Alignment:**
- Batteries-included tooling (built-in cache, no external deps)
- Rails-inspired conventions (layout wrapping, helper methods)
- Modern developer experience (convention-over-configuration)

**Roadmap Position:**
- Follows: Bootstrap Core & DI Container (#1), Routing & Event System (#2)
- Enables: Query Builder (#4) cache integration, ActiveRecord (#5) query caching
- Scope: Small - foundational cache interface + basic RAM provider + view rendering core

**Existing Components:**
- DI Container (`fuse/core/Container.cfc`) - for cache provider injection
- Event System (`fuse/core/EventService.cfc`) - for render interceptor points
- Module System (`fuse/core/IModule.cfc`) - for cache/view as modules
- Router (`fuse/core/Router.cfc`) - provides route to handler mapping

## Requirements Discussion

### Architecture Decisions

**Q1:** Cache architecture - pluggable interface with RAM provider or hardcoded memory cache?

**Answer:** Pluggable interface (ICacheProvider) with built-in RAM provider. Enables Redis/Memcached later without core changes. Follows DX mission (flexibility) and module pattern (everything-is-a-module).

**Q2:** View rendering - integrated with handler response or separate renderer component?

**Answer:** Separate renderer component (ViewRenderer) integrated via event system. Handler returns view data, EventService calls ViewRenderer during onBeforeRender. Clean separation, testable components.

**Q3:** Helper methods - global functions or scoped to view execution?

**Answer:** Scoped to view execution via isolated context. Prevents global namespace pollution, enables module-provided helpers, better testing. Rails uses view context pattern.

### Cache Implementation Details

**Q4:** RAM cache - struct-based storage or custom data structure?

**Answer:** Struct-based with metadata wrapper. Each entry: `{value, expiresAt}`. Simple, performant, native CFML. Lock per-key for granular concurrency.

**Q5:** Cache expiration - active timer sweep or lazy cleanup on access?

**Answer (Recommendation):** Lazy cleanup on-access. Rails pattern, simpler implementation, no timer threads. Check expiration during get(), delete if expired, return null. Aligns with small scope constraint.

**Q6:** Cache provider binding - DI container binding or hardcoded RAM provider?

**Answer:** DI container binding `ICacheProvider -> RAMCacheProvider` in Bootstrap. Enables override via config/modules. Follows built-in DI pattern.

### View Rendering Details

**Q7:** View file format - .cfm templates only or support .cfc component views?

**Answer (Recommendation):** .cfm only. Rails uses .erb (templates not classes). Clear separation: .cfc = code, .cfm = templates. Simpler renderer, aligns with small scope. Defer .cfc views to future.

**Q8:** Layout system - automatic application.cfm wrapper or manual layout specification?

**Answer (Recommendation):** Convention-based with fallback. Check for `views/layouts/application.cfm`, wrap if exists. If missing, render view standalone. Handler can override via return struct. Better DX - works immediately, opt-in layout.

**Q9:** View location - convention-based path from route or explicit path specification?

**Answer:** Support both. Convention: GET /users/index -> views/users/index.cfm. Explicit: handler returns view path. Flexibility for non-RESTful routes.

**Q10:** Missing templates - throw exception or return error struct?

**Answer (Recommendation):** Throw MissingTemplateException. Rails raises ActionView::MissingTemplate. Missing template = programming error. Fail fast during development. Include attempted paths in error message.

**Q11:** Handler return format - strict struct {view, locals} or flexible formats?

**Answer (Recommendation):** Allow both string and struct.
- String: `return "users/index"` (convention, simple)
- Struct: `return {view: "users/index", locals: {...}, layout: "admin"}` (explicit control)
- No return: convention-based view from route path
Rails pattern, balances convention-over-configuration with power.

### Scope Boundaries

**Q12:** What's explicitly out of scope for this roadmap item?

**Answer:**
- Query caching (deferred to ActiveRecord #5)
- Fragment caching (future enhancement)
- View helpers beyond basics (defer to helper module)
- Template compilation/caching (future optimization)
- Asset pipeline integration (separate roadmap item)
- Custom cache providers (Redis/Memcached - community)
- View partials (defer or include as basic feature)
- View layouts beyond single application.cfm
- Cache statistics/monitoring (future enhancement)

### Integration Points

**Q13:** How does cache integrate with existing components?

**Answer:**
- DI Container: Bind ICacheProvider -> RAMCacheProvider
- Module System: Cache as module implementing IModule interface
- Event System: Cache events (onCacheMiss, onCacheHit) for monitoring
- Config: Cache configuration (defaultTTL, maxSize) from config

**Q14:** How does view rendering integrate with existing components?

**Answer:**
- Event System: Render during onBeforeRender interceptor point
- Router: View path convention from matched route name
- Dispatcher: Handler return value processed by ViewRenderer
- DI Container: ViewRenderer as singleton service

### Technical Details

**Q15:** Cache provider interface methods?

**Answer:**
```
interface ICacheProvider {
  any get(string key)
  void set(string key, any value, numeric ttl)
  boolean has(string key)
  void delete(string key)
  void clear()
}
```

**Q16:** View renderer interface methods?

**Answer:**
```
component ViewRenderer {
  string render(string view, struct locals, string layout)
  string renderPartial(string partial, struct locals)
  void addHelper(string name, any helper)
}
```

**Q17:** Helper method registration - how do modules provide helpers?

**Answer:**
Module's boot() method calls `viewRenderer.addHelper("linkTo", linkToFunction)`. Helpers available in view context via `helpers.linkTo()` or direct function call if injected into view scope.

## Existing Code to Reference

**Similar Features Identified:**
- Bootstrap & DI Container: `/fuse/core/Bootstrap.cfc`, `/fuse/core/Container.cfc` - module registration, interface binding patterns
- Event System: `/fuse/core/EventService.cfc` - interceptor point pattern for onBeforeRender
- Module System: `/fuse/core/IModule.cfc` - interface pattern for ICacheProvider
- Router: `/fuse/core/Router.cfc` - route to view path convention

**Components to Potentially Reuse:**
- Container: Interface binding for ICacheProvider
- EventService: Interceptor registration for render events
- ModuleRegistry: Module lifecycle (register/boot) for cache/view modules
- Framework: Application scope caching pattern for ViewRenderer singleton

**Backend Patterns to Reference:**
- Thread-safe locking: Bootstrap.cfc application scope singleton pattern
- Module loading: ModuleRegistry dependency resolution
- Service registration: Container binding patterns

## Visual Assets

No visual assets provided (cache/view rendering is backend infrastructure).

## Requirements Summary

### Functional Requirements

**Cache Manager:**
- ICacheProvider interface defining contract (get/set/has/delete/clear)
- RAMCacheProvider implementation with struct storage
- TTL support with expiration timestamps
- Lazy cleanup on access (check expiration during get())
- Thread-safe operations (per-key locking)
- DI container binding (interface -> implementation)
- Module integration (cache as IModule)

**View Renderer:**
- Render .cfm templates with isolated execution context
- Layout wrapping (convention: views/layouts/application.cfm)
- No-layout fallback if application.cfm missing
- Handler return flexibility (string view path OR struct {view, locals, layout})
- Convention-based view paths from route (GET /users/index -> views/users/index.cfm)
- Missing template error handling (throw MissingTemplateException)
- Helper method system (scoped to view context)
- Module-provided helper registration
- EventService integration (onBeforeRender interceptor)

**Helper Methods:**
- Helper registration via viewRenderer.addHelper()
- Scoped execution context (not global namespace)
- Module-provided helpers (e.g., linkTo, formFor)
- Basic helpers included (url generation, HTML escaping)

### Reusability Opportunities

**Existing Patterns:**
- Container interface binding for ICacheProvider
- EventService interceptor pattern for render events
- Bootstrap application scope singleton for ViewRenderer
- ModuleRegistry lifecycle for cache/view as modules
- Thread-safe locking from Bootstrap.cfc

**Similar Features:**
- Event interceptor registration (EventService.announce)
- Service injection via DI container
- Module boot() method for initialization

### Scope Boundaries

**In Scope:**
- ICacheProvider interface definition
- RAMCacheProvider basic implementation
- ViewRenderer core component
- Layout wrapping (single application.cfm)
- Helper method registration system
- Basic HTML helpers (escape, linkTo)
- Event integration (onBeforeRender)
- Missing template error handling
- Convention-based view paths
- Flexible handler returns (string/struct)

**Out of Scope:**
- Query caching (deferred to ActiveRecord #5)
- Fragment caching (future)
- View partials (defer or basic implementation)
- Template compilation caching (future optimization)
- Custom cache providers (Redis/Memcached - community)
- Multiple layouts (single application.cfm only)
- Asset pipeline integration (separate item)
- Cache statistics/monitoring (future)
- Advanced helpers (form builders - defer)
- View component architecture (.cfc views - future)

### Technical Considerations

**Cache Architecture:**
- Struct storage: `{key: {value, expiresAt}}`
- Per-key locking for concurrency
- Lazy expiration check during get()
- Optional max size limit (LRU eviction - future)
- DI binding in Bootstrap.boot()

**View Rendering Architecture:**
- ViewRenderer singleton via DI container
- Isolated template execution (no global pollution)
- Helper method injection into view context
- Layout detection (file exists check)
- Path resolution (convention + explicit)
- Error handling (MissingTemplateException with attempted paths)

**Integration Points:**
- DI Container: Bind ICacheProvider, register ViewRenderer
- Event System: Render during onBeforeRender
- Router: Convention-based view path from route name
- Dispatcher: Process handler return value
- Config: Cache configuration (defaultTTL, maxSize)

**Module Pattern:**
- Cache as module: CacheModule implements IModule
- View as module: ViewModule implements IModule
- register() method: Bind providers to DI
- boot() method: Initialize services, register helpers
- getInterceptors() method: Return render interceptors

### Confirmation Question Answers

**Q1: RAM cache TTL - Sweep expired on timer or on-access?**
- **Answer:** On-access (lazy cleanup)
- **Implementation:** Check expiration during get(), delete if expired, return null

**Q2: View extension - .cfm only or support .cfc components?**
- **Answer:** .cfm only
- **Implementation:** View files use .cfm extension, template-only approach

**Q3: Layout default - Require application.cfm or no-layout fallback?**
- **Answer:** No-layout fallback
- **Implementation:** Check for views/layouts/application.cfm, wrap if exists, render standalone if missing

**Q4: Missing template - Throw error or return error struct?**
- **Answer:** Throw MissingTemplateException
- **Implementation:** Throw exception with attempted paths in error message

**Q5: Handler return - Enforce {view, locals} struct or allow string?**
- **Answer:** Allow both string and struct
- **Implementation:**
  - String: `return "users/index"` (convention)
  - Struct: `return {view: "users/index", locals: {...}, layout: "admin"}` (explicit)
  - No return: convention-based from route path

### Reference Framework Patterns

**Rails Patterns:**
- ActionView::MissingTemplate exception (throw on missing template)
- Layout fallback (no layout if not specified)
- ActiveSupport::Cache::MemoryStore (lazy expiration)
- View context pattern (scoped helpers)
- Flexible render (string or hash arguments)

**Fuse Existing Patterns:**
- Interface-based architecture (IModule, ICacheProvider)
- Module lifecycle (register/boot)
- Event interceptor points (onBeforeRender)
- DI container binding (interface -> implementation)
- Application scope singleton with thread-safe locking
- Convention-over-configuration (route -> view path)

## Technical Specifications

### ICacheProvider Interface

```cfc
interface ICacheProvider {
  /**
   * Get cached value by key
   * @key Cache key
   * @return Cached value or null if not found/expired
   */
  public any function get(required string key);

  /**
   * Set cached value with TTL
   * @key Cache key
   * @value Value to cache
   * @ttl Time-to-live in seconds (0 = no expiration)
   */
  public void function set(required string key, required any value, numeric ttl = 0);

  /**
   * Check if key exists and not expired
   * @key Cache key
   * @return Boolean indicating existence
   */
  public boolean function has(required string key);

  /**
   * Delete cached value by key
   * @key Cache key
   */
  public void function delete(required string key);

  /**
   * Clear all cached values
   */
  public void function clear();
}
```

### RAMCacheProvider Implementation

**Storage Structure:**
```cfc
variables.cache = {
  "key1": {
    value: "cached data",
    expiresAt: dateAdd("s", 60, now()) // or null for no expiration
  }
}
```

**Concurrency:**
- Per-key lock names: `"fuse_cache_{key}"`
- Lock during get/set/delete operations
- Read lock for has(), write lock for set/delete

**Expiration:**
- Lazy cleanup during get()
- If expiresAt != null AND expiresAt < now(), delete entry, return null
- No timer-based sweep

### ViewRenderer Component

**Core Methods:**
```cfc
component ViewRenderer {
  property name="config" inject="Config";
  property name="eventService" inject="EventService";

  public string function render(
    required string view,
    struct locals = {},
    string layout = "application"
  ) {
    // 1. Resolve view path
    // 2. Check template exists (throw if missing)
    // 3. Render view with helpers + locals
    // 4. Wrap in layout if exists
    // 5. Return HTML string
  }

  public void function addHelper(required string name, required any helper) {
    variables.helpers[name] = helper;
  }
}
```

**View Path Resolution:**
- Convention: `views/{handler}/{action}.cfm`
- Explicit: handler return string or struct.view
- Layout: `views/layouts/{layout}.cfm`

**Template Execution:**
- Create isolated scope with helpers + locals
- Include template via cfinclude
- Capture output
- Return rendered HTML

**Layout Wrapping:**
- Check fileExists(`views/layouts/application.cfm`)
- If exists: include layout, inject view content at yield point
- If missing: return view HTML directly
- Handler override: `layout: false` skips wrapping

### Module Integration

**CacheModule:**
```cfc
component implements="IModule" {
  public void function register(required Container container) {
    container.bind("ICacheProvider", "RAMCacheProvider", "singleton");
  }

  public void function boot(required Container container) {
    // Cache ready for use
  }
}
```

**ViewModule:**
```cfc
component implements="IModule" {
  public void function register(required Container container) {
    container.singleton("ViewRenderer", "fuse.views.ViewRenderer");
  }

  public void function boot(required Container container) {
    var renderer = container.resolve("ViewRenderer");
    renderer.addHelper("linkTo", linkToHelper);
    renderer.addHelper("h", htmlEscapeHelper);
  }

  public array function getInterceptors() {
    return [
      {event: "onBeforeRender", handler: "ViewModule.renderView"}
    ];
  }
}
```

### Handler Return Processing

**Dispatcher Integration:**
```cfc
// Handler returns:
// 1. String: view path
var result = "users/index";

// 2. Struct: explicit control
var result = {
  view: "users/index",
  locals: {user: user},
  layout: "admin"
};

// 3. Null: convention from route
var result = null; // GET /users/index -> views/users/index.cfm

// Dispatcher processes:
if (isNull(result)) {
  result = routeToViewPath(route);
} else if (isSimpleValue(result)) {
  result = {view: result};
}

// EventService.announce("onBeforeRender", {result: result})
// ViewModule.renderView() intercepts, calls ViewRenderer.render()
```

## Ready for Specification

All requirements gathered comprehensively:
- Cache architecture decisions finalized
- View rendering conventions established
- Integration patterns defined
- Scope boundaries clear
- Confirmation questions answered with recommendations
- Reference patterns documented
- Technical approach outlined

Spec ready for formal specification writing.
