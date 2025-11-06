# Specification: Bootstrap Core & DI Container

## Goal
Create foundational framework bootstrap system with thread-safe Application.cfc initialization, modular architecture via auto-discovered modules, and dependency injection container supporting constructor/property injection with singleton caching and environment-aware configuration.

## User Stories
- As a framework developer, I want automatic module discovery and dependency-ordered initialization so framework components load correctly
- As a developer, I want constructor and property injection so components receive dependencies without manual wiring
- As a developer, I want environment-specific configuration overrides so application behavior adapts to development/production/test contexts

## Specific Requirements

**Application.cfc Thread-Safe Bootstrap**
- Double-checked locking pattern: check application scope for framework instance, acquire named lock, check again, initialize if absent
- Framework singleton stored in application scope under configurable key (default: "fuse")
- Lock timeout configurable via Application.cfc property (default: 30 seconds)
- Bootstrap component instantiated once per application lifecycle, calls framework initialization sequence
- onApplicationStart() triggers bootstrap, onRequestStart() fails fast if framework not initialized
- Application scope used (not server scope) for standard Lucee application isolation
- Framework instance cached for <1ms overhead per request after initialization

**Module Discovery and Registry**
- Auto-discover modules from two locations: framework modules at `/fuse/modules/` and application modules at `/modules/`
- Module naming convention enforced: `RoutingModule.cfc`, `EventsModule.cfc`, `CacheModule.cfc`, etc.
- All modules must implement IModule interface with four required methods: `register()`, `boot()`, `getDependencies()`, `getConfig()`
- Module registry built by scanning both directories and instantiating found module CFCs
- Registry stored as ordered struct mapping module name to module metadata (path, instance, dependencies, loaded status)
- Framework modules loaded before application modules to ensure core infrastructure available

**Module Dependency Resolution**
- Each module declares dependencies via `getDependencies()` returning array of module names (e.g., `["RoutingModule", "ConfigModule"]`)
- Topological sort algorithm orders modules by dependencies before initialization
- Dependency graph must be acyclic - framework throws descriptive error if circular dependencies detected
- Missing dependencies cause framework initialization failure with clear error message identifying missing module
- Modules with no dependencies initialized first, then modules depending only on initialized modules, continuing until all loaded

**Two-Phase Module Initialization**
- Register phase: Framework calls `register()` on all modules in dependency order, modules bind services to DI container
- Boot phase: Framework calls `boot()` on all modules in same order, modules use DI container to resolve dependencies and perform initialization logic
- Two-phase approach ensures all DI bindings registered before any module attempts resolution
- Modules receive DI container instance in both `register()` and `boot()` methods
- Module configuration from `getConfig()` merged into global configuration before register phase

**DI Container Core Architecture**
- Container manages bindings map (interface/name to implementation) and instances cache (singleton storage)
- Binding methods: `bind(name, implementation)` for transient, `singleton(name, implementation)` for singleton
- Resolution method: `resolve(name)` returns instance, creating new or returning cached based on binding scope
- Container supports closure-based bindings for lazy instantiation: `singleton("logger", function(c) { return new Logger(); })`
- Container tracks resolution stack to detect circular dependencies during resolution
- Singleton instances cached in container's instances struct, keyed by binding name

**Constructor Injection**
- Container inspects component metadata via `getMetadata()` to find constructor (`init()`) parameters
- Parameter names matched against registered bindings in container
- Dependencies resolved recursively and passed as named arguments to `init()`
- If parameter not found in container and has no default value, throw descriptive error
- Supports primitive value injection via configuration bindings (strings, numbers, booleans, structs)

**Property Injection**
- Container inspects component properties for `inject` metadata attribute
- `property name="logger" inject="logger";` triggers automatic property injection
- After constructor invocation, container iterates properties and resolves each injected dependency
- Resolved dependency assigned to component via implicit setter (`setLogger()`)
- Property injection occurs after construction, allowing constructor to reference injected properties in post-init logic

**Singleton and Transient Scopes**
- Singleton scope (default): First resolution creates instance, subsequent resolutions return cached instance
- Transient scope: Every resolution creates new instance, no caching
- Scope declared at binding time: `container.singleton("router", RouterService)` vs `container.bind("request", Request)`
- Singleton cache keyed by binding name, stored in container's instances struct
- No automatic scope detection - developers explicitly choose scope per binding

**Configuration Loading**
- Configuration stored as CFML struct with nested keys for namespacing
- Base configuration loaded from `/config/application.cfc` returning struct via `getConfig()` method
- Environment-specific overrides loaded from `/config/environments/{environment}.cfc` if exists
- Environment determined from application setting or environment variable (APPLICATION.environment or ENV.FUSE_ENV)
- Override struct deep-merged into base configuration, with override values taking precedence
- Final merged configuration bound to DI container as "config" singleton
- Modules contribute configuration via `getConfig()` which gets merged under module name key

**IModule Interface Definition**
- `register(required container)`: Bind services to DI container, no dependency resolution allowed
- `boot(required container)`: Resolve dependencies and initialize module, all bindings available
- `getDependencies()`: Return array of module name strings this module depends on
- `getConfig()`: Return struct of configuration values to merge into global config under module name key
- All methods required, no optional methods in initial implementation
- Interface enforced via Lucee interface checking or runtime validation

## Visual Design

No visual assets provided.

## Existing Code to Leverage

**ColdBox Bootstrap.cfc**
- Double-checked locking pattern for application scope singleton initialization
- lockTimeout property and fail-fast behavior when framework reinitializing
- Application key configuration for flexibility in scope storage
- Validation of framework mapping existence before initialization

**ColdBox Injector.cfc (WireBox)**
- Constructor parameter resolution via getMetadata() introspection
- Property injection via inject metadata attribute scanning
- Singleton caching in instances struct with concurrent HashMap for thread safety
- Binder pattern for centralizing binding configuration
- Parent/child injector hierarchy for modular scoping

**ColdBox ModuleService.cfc**
- Module registry as ordered struct for deterministic initialization order
- Auto-discovery from multiple module locations (system vs application)
- Two-phase initialization (register then activate) pattern
- Module configuration cache separate from module instances
- Include/exclude lists for selective module loading

**Laravel Container**
- Bindings array storing closure-based factory functions
- Singleton instances array for caching resolved singletons
- Contextual bindings for interface-to-implementation mapping
- Build stack tracking for circular dependency detection
- Global resolving callbacks for cross-cutting concerns

**Laravel Application**
- Service provider registration and boot phases
- hasBeenBootstrapped and booted flags for lifecycle tracking
- Base path configuration with conventional directory structure
- Environment detection and configuration caching

**Rails Railtie**
- Initializer blocks with before/after ordering for fine-grained control
- Config object shared across all railties and application
- Modular extension pattern where each component is self-contained
- Rake tasks and generators loading via railtie hooks

## Out of Scope
- Setter injection (only constructor and property injection)
- YAML configuration files (CFML structs only in initial release)
- Lazy loading of dependencies (all eager instantiation)
- Hot reload of modules or configuration (requires application restart)
- Circular dependency resolution (must fail fast with clear error)
- Named bindings for multiple implementations of same interface
- Request/session scoped containers (singleton and transient only)
- Auto-wiring of non-framework application components (manual binding required)
- Aspect-oriented features like interceptors, proxies, or decorators
- Routing system (roadmap item 2)
- Event/interceptor system (roadmap item 2)
- Cache manager (roadmap item 3)
- View rendering engine (roadmap item 3)
- ORM integration (roadmap item 4)
- Testing utilities (roadmap item 5)
