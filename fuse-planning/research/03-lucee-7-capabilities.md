# Lucee 7 Modern Capabilities

Key Lucee 7 features and capabilities that enable modern framework design patterns.

## Executive Summary

Lucee 7 introduces modern features enabling clean framework design:
- **Static methods in components**: Clean ActiveRecord pattern support
- **Jakarta EE support**: Modern Java ecosystem integration via wrappers
- **Application singleton optimization**: Optional server-level performance boost
- **Environment variable priority**: 12-factor app compliance
- **Standard performance**: Solid query execution, component loading

---

## Application Singleton Mode

### Feature
**Optional server-level optimization** that caches Application.cfc component instance.

### Configuration
**IMPORTANT**: Not configured in Application.cfc - requires server-level setup:

```bash
# System property or environment variable (choose one):
-Dlucee.application.singelton=true    # JVM arg
export lucee.application.singelton=true  # Env var

# Or in Lucee server config XML
```

**Default**: Disabled (standard reload behavior)

### How It Works
```java
// Lucee source: ModernAppListener.java
// Caches Application.cfc instance by path + modification timestamp
// Still checks file modification on each request
// Not truly zero-overhead, but reduces component instantiation cost
```

### Benefits (When Enabled)
- **Reduces component instantiation**: ~5-20ms saved per request
- **Less object allocation**: Component instance reused
- **Thread-safe**: Uses ConcurrentHashMap internally

### Limitations
- **Server-wide setting**: Cannot enable per-application
- **Still checks timestamps**: Not zero overhead
- **Requires server access**: Can't configure in code
- **Breaks hot reload**: File changes require server restart

### Impact on Fuse
- **Not a core dependency**: Framework works without it
- **Optional optimization**: Users can enable at server level for performance
- **Use manual caching**: Application scope with double-checked locking as standard
- **Document as optional**: "Works great out of box, optimize with server config"

---

## Jakarta EE Support

### Feature
Lucee 7 migrates from javax.* to jakarta.* namespace for servlet APIs.

### Impact
Modern Java ecosystem integration, Tomcat 10+ compatibility.

### Usage
```cfml
// Can now use Jakarta Servlet APIs
application.servletContext = getPageContext()
    .getServletContext(); // Returns jakarta.servlet.ServletContext

// Access to modern servlet features
application.servletContext.setAttribute("key", value);
```

### Benefits
- **Tomcat 10+ compatibility**: Modern servlet container support
- **Modern extension ecosystem**: Access to Jakarta libraries
- **Future-proof architecture**: Aligned with Java EE evolution
- **Better Java interoperability**: Seamless integration with Jakarta libs

### Impact on Fuse
- Can leverage Jakarta servlet features
- Better request/response handling
- Modern session management
- WebSocket support via Jakarta

---

## Static Methods in Components

### Feature
**Full support for static methods** in components (available since Lucee 6.x, stable in 7).

### Syntax
```cfml
component {
    // Static method
    static function find(id) {
        return query().where({id: arguments.id}).first();
    }

    // Static constructor block
    static {
        static.defaultLimit = 100;
    }
}

// Invocation
user = User::find(1);
users = User::where({active: true});
```

### Benefits for ActiveRecord
- **Clean syntax**: `User::find(1)` matches Rails/Laravel
- **Persistent state**: Static scope persists across instances
- **Good performance**: Method compiled once per class

### Limitations
- **No auto-delegation**: Each static method must be explicitly implemented
- **Boilerplate required**: Can't just forward unknown methods to builder
- **Manual implementation**: `find()`, `where()`, `all()` each need code

### Example Boilerplate
```cfml
component extends="fuse.orm.ActiveRecord" {
    // Every static method must be defined
    static function where(criteria, operator, value) {
        return query().where(argumentCollection=arguments);
    }

    static function find(id) {
        return query().where({id: arguments.id}).first();
    }

    static function all() {
        return query().get();
    }

    // ... etc for each query method
}
```

### Impact on Fuse
- **Pattern viable**: ActiveRecord syntax achievable
- **Code generator helpful**: Reduce boilerplate via CLI
- **Document reality**: Not magic, requires explicit methods
- **Alternative**: Could use facade pattern instead

---

## Configuration Hierarchy

### Feature
Environment variables consistently prioritized over config files.

### Pattern
```cfml
// Lucee 7 consistently prioritizes env vars
this.datasource = systemEnv.DATABASE_URL ?: getConfig("datasource");
this.name = systemEnv.APP_NAME ?: "defaultApp";

// Config settings
settings = {
    cacheHost = systemEnv.REDIS_HOST ?: "localhost",
    cachePort = systemEnv.REDIS_PORT ?: 6379,
    environment = systemEnv.FUSE_ENV ?: "development"
};
```

### Benefits (12-Factor App Compliance)
- **Secrets management**: Credentials via env vars, not config files
- **Dynamic configuration**: Change config without code changes
- **Container-friendly**: Perfect for Docker/Kubernetes
- **Environment parity**: Same code, different config per environment

### Impact on Fuse
- Environment-first configuration
- .env file support (like Wheels)
- Easy containerization
- Better security (no credentials in code)

---

## Performance Characteristics

### queryExecute() Performance
- **Standard implementation**: Same solid performance as Lucee 6.x
- **Tag pooling**: Reuses query tag instances (reduces allocation)
- **PreparedStatement caching**: JDBC driver level optimization
- **Parameterized queries**: Standard SQL injection protection

**Reality**: No special "Lucee 7 query optimizations" - solid standard performance.

### Component Loading
- **Static methods**: Loaded once per class lifetime (~0.1-1ms)
- **Instance creation**: Standard CFML component instantiation
- **Singleton caching**: Optional server-level optimization (5-20ms/request)

### Impact on Fuse
- **Expect standard performance**: 1-5ms framework overhead per request
- **ORM query generation**: 2-10ms depending on complexity
- **Not revolutionary**: Solid, modern CFML performance
- **Optimize via architecture**: Two-layer builder, smart eager loading

---

## AST Generation API

### Feature
Analyze CFML code structure programmatically.

### Use Case
Framework introspection, documentation generation, code analysis.

### Example
```cfml
// NEW: Analyze CFML code structure
ast = getASTForComponent("path/to/Component.cfc");

// Useful for:
// - Documentation generators
// - Code analyzers
// - Route introspection
// - Automatic API documentation
```

### Impact on Fuse
- Could generate route documentation automatically
- Introspect models for schema info
- Auto-generate API docs from handlers
- Code analysis tools for framework

---

## Other Lucee 7 Features

### Modern CFML Syntax
- Better closure support
- Enhanced arrow functions
- Improved null handling

### HTTP/2 Support
- Better performance for modern apps
- Server push capabilities

### Improved Thread Safety
- Better concurrent request handling
- Safer application scope usage

---

## Fuse Bootstrap Strategy

### Leveraging Lucee 7 Features

1. **Manual Application Scope Caching** (Standard Pattern)
   ```cfml
   component {
       function onApplicationStart() {
           lock name="fuseInit" type="exclusive" timeout="30" {
               application.fuse = new fuse.system.Bootstrap().init();
           }
           return true;
       }

       function onRequestStart(targetPath) {
           // Optional: reload support for dev
           if (structKeyExists(url, "fuseReload") && application.fuse.config.environment == "development") {
               lock name="fuseReload" type="exclusive" timeout="30" {
                   applicationStop();
               }
           }

           return application.fuse.framework.handleRequest(targetPath);
       }
   }
   ```

2. **Environment-First Config**
   ```cfml
   settings = {
       environment: systemEnv.FUSE_ENV ?: "development",
       database: systemEnv.DATABASE_URL ?: "default",
       cacheProvider: systemEnv.CACHE_PROVIDER ?: "ram"
   };
   ```

3. **Static Methods for ActiveRecord**
   ```cfml
   // models/User.cfc
   component extends="fuse.orm.ActiveRecord" {
       static function find(id) {
           return query().where({id: arguments.id}).first();
       }
   }

   // Usage
   user = User::find(1);
   ```

4. **Jakarta Servlet Access** (Where Useful)
   ```cfml
   // Access via PageContext wrapper
   servletContext = getPageContext().getServletContext();
   request = getPageContext().getRequest();
   // Use for specific features (WebSockets, async)
   ```

---

## Comparison: Fuse Pattern vs Traditional

### Traditional Framework Pattern
```cfml
// Complex reload logic, read locks, etc.
function onRequestStart(targetPath) {
    // Reload detection with double-checked locking
    if (structKeyExists(url, "reload")) {
        lock name="appReload" type="exclusive" timeout="30" {
            if (structKeyExists(url, "reload")) {
                applicationStop();
                location(url=cgi.script_name, addToken=false);
            }
        }
    }

    // Read lock for every request
    lock name="frameworkAccess" type="readonly" timeout="10" {
        return application.framework.handleRequest(targetPath);
    }
}
```

### Fuse Pattern (Lucee 7 Optimized)
```cfml
// Simpler, cleaner
function onApplicationStart() {
    lock name="fuseInit" type="exclusive" timeout="30" {
        application.fuse = new fuse.system.Bootstrap().init();
    }
    return true;
}

function onRequestStart(targetPath) {
    // Direct access, no read locks needed (application scope thread-safe for reads)
    return application.fuse.framework.handleRequest(targetPath);
}
```

### Benefits
- **Simpler code**: No complex reload logic by default
- **Modern patterns**: Static methods, environment config
- **Optional optimization**: Can enable server singleton for extra performance
- **Better architecture**: Clean separation of concerns

---

## Recommendations for Fuse

### Core Strategy
**Lucee 7 exclusive** - embrace modern platform fully:

1. **Static methods** for ActiveRecord syntax (requires Lucee 7)
2. **lucli CLI** for tooling (requires Lucee 7)
3. **Environment variable** priority for 12-factor compliance
4. **Standard bootstrap** with optional server-level singleton
5. **Jakarta servlet** access where useful (WebSockets, async)
6. **Architecture-first performance** (clean design beats runtime magic)

### Why Lucee 7 Exclusive?
- **Static methods**: Essential for clean ActiveRecord pattern
- **lucli integration**: Framework CLI relies on lucli
- **Modern runtime**: Jakarta EE, current support
- **Stable platform**: Lucee 7 mature, well-tested
- **Future-aligned**: Active development, community support
- **Clean codebase**: No legacy compatibility needed
- **No compromises**: Use best patterns without constraints

### What This Means
- **Requires Lucee 7**: Framework won't work on older versions
- **No Adobe CF support**: Exclusive to Lucee ecosystem
- **Modern stack**: Target forward-thinking developers
- **Realistic performance**: 1-5ms framework overhead via architecture
- **Optional optimizations**: Server singleton available but not required

### Trade-offs
- **Narrower audience**: Lucee 7+ only (acceptable for new framework)
- **No Adobe CF**: Can't target Adobe (acceptable)
- **Requires modern hosting**: Lucee 7 availability needed

**Decision**: Lucee 7 exclusive - static methods + lucli make this natural choice.

---

## Future Lucee Features to Watch

- **Native async/await**: Better than current thread model
- **Pattern matching**: More expressive code
- **Improved REPL**: Better interactive development
- **Enhanced module system**: Native module loading

These could inform future Fuse evolution.
