# Spec Requirements: Bootstrap Core & DI Container

## Initial Description
From roadmap item #1:

Bootstrap Core & DI Container — Application.cfc initialization with thread-safe locking, module loader with dependency resolution, DI container with constructor/property injection and singleton caching, configuration loading with environment overrides

## Requirements Discussion

### First Round Questions

**Q1: Application.cfc Singleton Pattern** - I assume you want the standard Lucee application scope singleton pattern with double-checked locking (check if exists, lock, check again, initialize). Is that correct, or should we use server scope singleton for better performance?

**Answer:** Application scope singleton with double-checked locking is correct.

**Q2: Module Naming Convention** - I'm thinking module names should follow conventional naming like `RoutingModule.cfc`, `EventsModule.cfc`, etc. Should we enforce this convention or allow custom names?

**Answer:** Conventional names like `RoutingModule.cfc` are correct.

**Q3: DI Injection Methods** - Should the DI container support constructor injection, property injection (via `inject` metadata), and setter injection? Or should we keep it simpler with just constructor + property?

**Answer:** Constructor + property injection only (simpler approach).

**Q4: Configuration Format** - Should configuration support both CFML structs and YAML files, or just CFML structs initially?

**Answer:** CFML structs only.

**Q5: Module Dependencies** - Should module dependencies be explicit (via `getDependencies()` method) or implicit (via DI container auto-detection)? Explicit provides clearer control for initialization order.

**Answer:** Explicit via `getDependencies()` with topological sort for initialization order.

**Q6: DI Container Scopes** - Should we support singleton, transient, and request scopes, or just singleton and transient initially?

**Answer:** Singleton + transient only.

**Q7: IModule Interface Methods** - I'm assuming the IModule interface should have `register()`, `boot()`, `getDependencies()`, and `getConfig()`. Any other methods needed?

**Answer:** Those four methods are correct - `register()`, `boot()`, `getDependencies()`, `getConfig()`.

**Q8: Scope Boundaries** - What should be explicitly OUT of scope for this spec? For example: hot reload, circular dependency resolution, aspect-oriented features, named bindings, scoped containers (request/session), lazy loading, auto-wiring of non-framework components?

**Answer:** OUT of scope: Setter injection, YAML config, lazy loading, hot reload, circular dependency resolution, named bindings, scoped containers beyond singleton/transient, auto-wiring non-framework components. Also out of scope: routing/events/cache/views (future roadmap items).

**Q9: Module Auto-Discovery** - Should modules be auto-discovered from `fuse/modules/` (framework modules) and `/modules/` (application modules) directories, or manually registered?

**Answer:** Framework modules (`fuse/modules/`) and application modules (`/modules/`) both auto-discovered.

### Existing Code to Reference

**Similar Features Identified:**

No similar existing features identified for reference - this is the foundation spec.

### Follow-up Questions

None required - all requirements clearly defined.

## Visual Assets

### Files Provided:

No visual assets provided.

### Visual Insights:

N/A - This is foundational infrastructure code without UI components.

## Requirements Summary

### Functional Requirements

**Application.cfc Initialization:**
- Standard Lucee application scope singleton pattern
- Double-checked locking (check existence, lock, check again, initialize)
- Thread-safe framework bootstrap on first request
- Application scope storage of framework instance

**Module System:**
- IModule interface with four methods: `register()`, `boot()`, `getDependencies()`, `getConfig()`
- Conventional naming: `RoutingModule.cfc`, `EventsModule.cfc`, etc.
- Auto-discovery from two locations:
  - Framework modules: `fuse/modules/`
  - Application modules: `/modules/`
- Explicit dependency declaration via `getDependencies()` returning array of module names
- Topological sort for dependency resolution and initialization order
- Two-phase initialization: `register()` phase (DI bindings), then `boot()` phase (use DI services)

**DI Container:**
- Constructor injection: Pass dependencies as constructor arguments
- Property injection: Auto-wire via `inject` metadata on properties
- Two scopes only: singleton (default, cached) and transient (new instance each time)
- Component registration by name or interface
- Interface-to-implementation binding for pluggable components
- Singleton caching in container
- Resolution of dependency trees

**Configuration Loading:**
- CFML struct-based configuration only (no YAML)
- Environment-specific overrides (development, production, test)
- Configuration accessible throughout framework via DI
- Modules provide configuration via `getConfig()` method

### Reusability Opportunities

This is foundational infrastructure - no existing similar features to reuse. However, patterns established here (singleton caching, double-checked locking, module interface) will inform all subsequent framework components.

### Scope Boundaries

**In Scope:**
- Application.cfc with thread-safe singleton initialization
- ModuleLoader with auto-discovery and dependency resolution
- DI container with constructor and property injection
- Singleton and transient scope caching
- CFML struct configuration loading with environment overrides
- IModule interface definition and implementation
- Topological sort for module dependency order
- Two-phase module initialization (register + boot)

**Out of Scope:**
- Setter injection (future enhancement)
- YAML configuration files (CFML structs only)
- Lazy loading of dependencies (all eager)
- Hot reload of framework/modules (manual reload only)
- Circular dependency detection/resolution (dependencies must be acyclic)
- Named bindings (multiple implementations of same interface)
- Request/session scoped containers (singleton/transient only)
- Auto-wiring of non-framework application components
- Aspect-oriented features (interceptors, proxies, decorators)
- Routing system (roadmap item #2)
- Event system (roadmap item #2)
- Cache manager (roadmap item #3)
- View rendering (roadmap item #3)

**Future Enhancements Mentioned:**
- Additional DI scopes (request, session)
- YAML configuration support
- Hot reload capabilities
- Named bindings for multiple implementations
- Circular dependency handling

### Technical Considerations

**Integration Points:**
- Application.cfc is entry point for all requests
- Bootstrap component initializes entire framework
- ModuleLoader discovers and loads all framework and application modules
- DI container provides dependencies to all framework components
- Configuration accessible throughout framework via DI

**Framework Architecture:**
- Everything-is-a-module design: routing, events, cache, ORM, views all loaded as modules
- Module dependencies create initialization order graph
- Two-phase init ensures DI bindings available before boot logic runs
- Application scope singleton for production (<1ms per-request overhead)

**Lucee 7 Features:**
- Static methods not used in this spec (used heavily in ORM layer)
- Standard CFC components with conventional CFML
- Thread-safe locking via Lucee's `lock` statement
- Application scope as standard singleton pattern

**Technology Constraints:**
- Lucee 7+ required (framework foundation)
- No external dependencies (pure CFML)
- Component-based architecture (all framework code in CFCs)
- Jakarta EE access via PageContext (not used in this spec)

**Similar Code Patterns:**
- None - this is the first roadmap item establishing foundational patterns
- Future specs will reference this DI container and module system
- ORM, routing, events, cache, views will all be implemented as modules following IModule interface
