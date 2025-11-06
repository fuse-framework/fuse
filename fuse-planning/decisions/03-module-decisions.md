# Module, Cache, and Extension Decisions

Decisions for Fuse module system, caching layer, and extensibility.

## Decision Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Module Discovery** | Auto-discovery | Convention-based, zero config, Rails-like |
| **Cache Layer** | Pluggable with RAM default | Extensible, sensible default |
| **Module Interface** | IModule.cfc contract | Clear expectations, consistent |
| **Extension Pattern** | Modules as plugins | Everything is a module (Rails engines) |

---

## Module Discovery: Auto-discovery

### Decision
Automatically scan and load modules from directories, no explicit registration required.

### Rationale
1. **Convention over configuration**: Zero-config module loading
2. **Rails pattern**: Similar to Rails engines auto-discovery
3. **Developer friendly**: Drop module in directory, it works
4. **Reduced boilerplate**: No registration code needed
5. **Consistent**: Aligns with framework philosophy

### Discovery Paths
```
fuse/modules/          - Core framework modules
/modules/              - Application modules
/vendor/modules/       - Third-party modules (optional)
```

### Pattern
```cfml
// Framework scans directories for Module.cfc files
// Loads them in dependency order
// No configuration needed

// Example structure:
fuse/
  modules/
    routing/Module.cfc
    events/Module.cfc
    cache/Module.cfc
    orm/Module.cfc

myapp/
  modules/
    auth/Module.cfc        <- Auto-discovered
    api/Module.cfc         <- Auto-discovered
```

### Override Option
```cfml
// config/fuse.cfc - for when you need control
settings.modules = {
    autoDiscover: true,  // Default
    paths: ["/modules", "/vendor/modules"],
    exclude: ["legacy-module"],  // Skip these
    explicit: []  // Load only these (disables auto-discovery)
};
```

### Loading Order
1. **Dependency resolution**: Analyze `getDependencies()` from each module
2. **Topological sort**: Load in dependency order
3. **Register phase**: All modules register DI bindings
4. **Boot phase**: All modules initialize (DI available)
5. **Route collection**: Collect routes from modules
6. **Interceptor registration**: Register event listeners

---

## Module Interface: IModule.cfc

### Decision
All modules implement `fuse.interfaces.IModule` interface for consistency.

### Interface Definition
```cfml
// fuse/interfaces/IModule.cfc
interface {
    /**
     * Module name (must be unique)
     */
    public string function getName();

    /**
     * Module dependencies
     * @return {required: ["module1"], optional: ["module2"]}
     */
    public struct function getDependencies();

    /**
     * Register phase: Register DI bindings
     * Called before any module boots
     */
    public void function register(required any injector);

    /**
     * Boot phase: Initialize module
     * Called after all modules registered, DI container ready
     */
    public void function boot(required any framework);

    /**
     * Optional: Routes provided by module
     */
    public array function getRoutes();

    /**
     * Optional: Event interceptors
     */
    public struct function getInterceptors();
}
```

### Example Module
```cfml
// modules/auth/Module.cfc
component implements="fuse.interfaces.IModule" {

    function getName() {
        return "auth";
    }

    function getDependencies() {
        return {
            required: ["cache", "events"],
            optional: ["email"]
        };
    }

    function register(injector) {
        // Register DI bindings
        injector.bind("AuthService")
            .to("modules.auth.AuthService")
            .asSingleton();

        injector.bind("SessionManager")
            .to("modules.auth.SessionManager")
            .asSingleton();
    }

    function boot(framework) {
        // Initialize module
        variables.authService = framework.injector.getInstance("AuthService");

        // Register middleware
        framework.router.middleware("auth", "modules.auth.AuthMiddleware");
    }

    function getRoutes() {
        return [
            {pattern: "/login", handler: "Auth.login", method: "GET"},
            {pattern: "/login", handler: "Auth.doLogin", method: "POST"},
            {pattern: "/logout", handler: "Auth.logout", method: "POST"}
        ];
    }

    function getInterceptors() {
        return {
            onBeforeHandler: "modules.auth.AuthInterceptor.checkAuth"
        };
    }
}
```

### Lifecycle
```
1. Discovery Phase
   - Scan directories
   - Load Module.cfc components

2. Dependency Phase
   - Call getDependencies() on each
   - Topological sort
   - Detect circular dependencies

3. Register Phase
   - Call register(injector) in order
   - Modules add DI bindings
   - No module instances yet

4. Boot Phase
   - Call boot(framework) in order
   - DI container ready
   - Modules can getInstance()

5. Route Collection
   - Call getRoutes() on each
   - Merge into route table

6. Interceptor Registration
   - Call getInterceptors() on each
   - Register with event system
```

---

## Cache Layer: Pluggable

### Decision
Pluggable cache layer with RAM provider default, extensible via modules.

### Architecture
```
┌──────────────────┐
│  CacheManager    │  <- Application uses this
└────────┬─────────┘
         │ delegates to
         ▼
┌──────────────────┐
│ ICacheProvider   │  <- Interface
└────────┬─────────┘
         │ implements
         ├─────────────────────────┐
         ▼                         ▼
┌──────────────────┐    ┌─────────────────┐
│  RAMProvider     │    │  RedisProvider  │
│  (built-in)      │    │  (module)       │
└──────────────────┘    └─────────────────┘
```

### Interface
```cfml
// fuse/interfaces/ICacheProvider.cfc
interface {
    public any function get(required string key);
    public void function set(required string key, required any value, numeric timeout=0);
    public boolean function exists(required string key);
    public void function delete(required string key);
    public void function clear();
    public struct function stats();
}
```

### Built-in RAM Provider
```cfml
// fuse/modules/cache/providers/RAMProvider.cfc
component implements="fuse.interfaces.ICacheProvider" {

    function init() {
        variables.cache = {};
        variables.timestamps = {};
        return this;
    }

    function get(key) {
        if (exists(key)) {
            return variables.cache[key];
        }
        throw(type="CacheMiss", message="Key not found: #key#");
    }

    function set(key, value, timeout=0) {
        variables.cache[key] = value;
        if (timeout > 0) {
            variables.timestamps[key] = {
                expires: dateAdd("s", timeout, now())
            };
        }
    }

    function exists(key) {
        if (!structKeyExists(variables.cache, key)) {
            return false;
        }

        // Check expiration
        if (structKeyExists(variables.timestamps, key)) {
            if (now() > variables.timestamps[key].expires) {
                delete(key);
                return false;
            }
        }

        return true;
    }

    function delete(key) {
        structDelete(variables.cache, key);
        structDelete(variables.timestamps, key);
    }

    function clear() {
        variables.cache = {};
        variables.timestamps = {};
    }

    function stats() {
        return {
            provider: "ram",
            keys: structCount(variables.cache),
            memoryUsage: 0  // TODO: estimate
        };
    }
}
```

### Cache Manager
```cfml
// fuse/modules/cache/CacheManager.cfc
component {

    function init(provider) {
        variables.provider = arguments.provider;
        return this;
    }

    function get(key, defaultValue=null) {
        try {
            return variables.provider.get(key);
        } catch (CacheMiss e) {
            if (!isNull(defaultValue)) {
                return defaultValue;
            }
            throw(e);
        }
    }

    function remember(key, timeout, generator) {
        if (variables.provider.exists(key)) {
            return get(key);
        }

        value = generator();
        variables.provider.set(key, value, timeout);
        return value;
    }

    function set(key, value, timeout=0) {
        return variables.provider.set(key, value, timeout);
    }

    function delete(key) {
        return variables.provider.delete(key);
    }

    function clear() {
        return variables.provider.clear();
    }

    function stats() {
        return variables.provider.stats();
    }
}
```

### Configuration
```cfml
// config/fuse.cfc
settings.cache = {
    provider: "ram",  // or "redis", "memcached"

    // Provider-specific config
    redis: {
        host: systemEnv.REDIS_HOST ?: "localhost",
        port: systemEnv.REDIS_PORT ?: 6379,
        password: systemEnv.REDIS_PASSWORD ?: ""
    }
};
```

### Third-party Cache Provider
```cfml
// modules/redis-cache/Module.cfc
component implements="fuse.interfaces.IModule" {

    function getName() { return "redis-cache"; }

    function getDependencies() {
        return {required: ["cache"]};
    }

    function register(injector) {
        // Only bind if configured
        if (application.fuse.config.cache.provider == "redis") {
            injector.bind("ICacheProvider")
                .to("modules.redis-cache.RedisProvider")
                .asSingleton();
        }
    }

    function boot(framework) {
        // Initialize Redis connection
    }
}
```

### Usage
```cfml
// In application code
cache = getInstance("CacheManager");

// Simple get/set
cache.set("user:1", user, 3600);
user = cache.get("user:1");

// Remember pattern (get or generate)
user = cache.remember("user:1", 3600, function() {
    return User.find(1);
});

// Delete
cache.delete("user:1");

// Clear all
cache.clear();
```

---

## Extension Pattern: Everything is a Module

### Decision
Framework core features implemented as modules, third-party extensions use same pattern.

### Rationale
1. **Rails engines pattern**: Rails itself is composed of engines
2. **Consistency**: Core and extensions work the same way
3. **Swappable**: Can replace core modules with alternatives
4. **Testable**: Each module independently testable
5. **Maintainable**: Clear boundaries, single responsibility

### Core Modules
```
fuse/modules/
  routing/          - Router, route matching
  events/           - Event system, interceptors
  cache/            - Cache manager + RAM provider
  orm/              - ActiveRecord, query builder
  views/            - View rendering, layouts
  testing/          - Test framework
  validation/       - Validation rules
  sessions/         - Session management
  csrf/             - CSRF protection
```

### Third-party Modules
```
modules/
  fuse-auth/        - Authentication system
  fuse-admin/       - Admin panel
  fuse-api/         - API toolkit (versioning, rate limiting)
  fuse-redis/       - Redis cache provider
  fuse-s3/          - S3 file storage
  fuse-email/       - Email sending
  fuse-queue/       - Background jobs
```

### Module Generator
```bash
# Create module skeleton
lucli fuse:generate:module mymodule

# Creates:
modules/
  mymodule/
    Module.cfc              - Main module file
    handlers/               - Module handlers
    models/                 - Module models
    views/                  - Module views
    tests/                  - Module tests
    README.md               - Module documentation
```

### Module Distribution
```cfml
// box.json for module
{
    "name": "fuse-auth",
    "version": "1.0.0",
    "type": "fuse-modules",
    "dependencies": {
        "fuse": "^1.0.0"
    },
    "installPaths": {
        "fuse-auth": "modules/fuse-auth/"
    }
}

// Install via CommandBox
box install fuse-auth
```

---

## Module Examples

### Authentication Module
```cfml
// modules/fuse-auth/Module.cfc
component implements="fuse.interfaces.IModule" {

    function register(injector) {
        injector.bind("AuthService").to("modules.fuse-auth.AuthService").singleton();
        injector.bind("PasswordHasher").to("modules.fuse-auth.BCryptHasher").singleton();
    }

    function boot(framework) {
        // Add auth helper to all views
        framework.viewHelpers.add("currentUser", function() {
            return getInstance("AuthService").currentUser();
        });

        // Add auth middleware
        framework.router.middleware("auth", "modules.fuse-auth.AuthMiddleware");
    }

    function getRoutes() {
        return [
            {pattern: "/login", handler: "fuse-auth.Auth.login", method: "GET"},
            {pattern: "/login", handler: "fuse-auth.Auth.doLogin", method: "POST"},
            {pattern: "/logout", handler: "fuse-auth.Auth.logout", method: "POST"},
            {pattern: "/register", handler: "fuse-auth.Auth.register", method: "GET"},
            {pattern: "/register", handler: "fuse-auth.Auth.doRegister", method: "POST"}
        ];
    }

    function getInterceptors() {
        return {
            onBeforeHandler: "modules.fuse-auth.AuthInterceptor.loadUser"
        };
    }
}
```

### Admin Panel Module
```cfml
// modules/fuse-admin/Module.cfc
component implements="fuse.interfaces.IModule" {

    function getDependencies() {
        return {required: ["fuse-auth"]};  // Requires auth
    }

    function boot(framework) {
        // Register admin namespace routes
        framework.router.namespace("admin", {
            middleware: ["auth", "admin"]
        }, function(r) {
            r.resource("users");
            r.resource("posts");
            r.get("/dashboard", "admin.Dashboard.index");
        });
    }
}
```

---

## Summary

Module decisions create a **Rails engines-inspired extension system**:
- Auto-discovery for zero-config loading
- IModule interface for consistency
- Pluggable cache layer with clean abstraction
- Core framework itself composed of modules
- Third-party extensions use same patterns

This provides maximum extensibility while maintaining convention-based simplicity.
