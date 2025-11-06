# Bootstrap Comparison: FW/1, ColdBox, Wheels

Research comparing how the three major CFML frameworks bootstrap and initialize.

## Executive Summary

- **FW/1**: Request-scoped lazy singleton, minimal footprint, delegation pattern
- **ColdBox**: Application-scoped service architecture, comprehensive lifecycle, Bootstrap CFC
- **Wheels**: WireBox DI-powered, event-based initialization, 1000+ line setup

---

## FW/1 Bootstrap Analysis

### Pattern
**Request-scoped lazy singleton** - Framework object created on first request access

### Entry Point
`framework/one.cfc` (single file framework)

### Application.cfc Pattern
```cfml
function _get_framework_one() {
    if (!structKeyExists(request, '_framework_one')) {
        request._framework_one = new framework.one({
            // config struct here
        });
    }
    return request._framework_one;
}

function onApplicationStart() {
    return _get_framework_one().onApplicationStart();
}

function onRequest(targetPath) {
    return _get_framework_one().onRequest(targetPath);
}
```

### Request Tracking
```cfml
request._fw1 = {
    cgiScriptName = CGI.SCRIPT_NAME,
    cgiPathInfo = CGI.PATH_INFO,
    controllers = [],
    requestDefaultsInitialized = false,
    routeMethodsMatched = {},
    trace = []
};
```

### Configuration Model
- Single struct passed to `init()`
- Merged with `variables.framework` defaults
- Convention-over-configuration

### Strengths
- Minimal footprint (single CFC)
- Flexible (extend via MyApplication.cfc)
- Request-scoped prevents cross-contamination
- No external dependencies
- Clear separation: framework vs application logic

### Weaknesses
- No dedicated DI container (optional DI/1 or WireBox)
- Limited event interception points
- Manual controller instantiation
- Request-scoped requires reload handling per request

---

## ColdBox Bootstrap Analysis

### Pattern
**Application-scoped service architecture** - Bootstrap CFC creates Controller in application scope

### Entry Point
`system/Bootstrap.cfc` + `system/web/Controller.cfc`

### Application.cfc Pattern
```cfml
function onApplicationStart() {
    application.cbBootstrap = new coldbox.system.Bootstrap(
        COLDBOX_CONFIG_FILE,
        COLDBOX_APP_ROOT_PATH,
        COLDBOX_APP_KEY,
        COLDBOX_APP_MAPPING
    );
    application.cbBootstrap.loadColdBox();
    return true;
}

function onRequestStart(targetPath) {
    application.cbBootstrap.onRequestStart(arguments.targetPath);
}
```

### loadColdBox() Sequence
1. Validate `/coldbox` mapping exists
2. Create `coldbox.system.web.Controller`
3. Framework setup via `LoaderService.loadApplication()`
4. Execute `ApplicationStartHandler` if configured
5. Fail-fast: concurrent requests get 503 during reinit

### Service Architecture
```cfml
application[appKey] contains:
- getLoaderService()        - App loading/shutdown
- getInterceptorService()   - AOP event announcements
- getModuleService()        - Module architecture
- getRequestService()       - Request context management
- getHandlerService()       - Controller registration
- getCacheBox()             - Multi-provider caching
- getWireBox()              - Full DI/AOP container
```

### Reload Architecture
**Double-lock pattern** for thread-safe reinitialization:
```cfml
lock type="exclusive" name="#appHash#" timeout="#lockTimeout#" {
    if (NOT structKeyExists(application, appkey) OR needReinit) {
        application.fwReinit = true;
        application[appKey].getModuleService().loadMappings();
        application[appKey].getInterceptorService().announce("preReinit");
        application[appKey].getLoaderService().processShutdown();
        loadColdBox();
    }
}
```

### Request Processing Lifecycle
1. Load module CF mappings
2. Capture request context
3. Pre-process interceptors: `announce("preProcess")`
4. Request start handler
5. Event caching check
6. Main event execution
7. Rendering (view/layout or renderData)
8. Event caching (if cacheable)
9. Post-process interceptors/handlers
10. Flash scope auto-save

### Interceptor Points
26+ announcement points including:
- Application: `preReinit`, `applicationEnd`
- Request: `preProcess`, `postProcess`, `preRender`, `postRender`
- Session: `sessionStart`, `sessionEnd`
- Exception: `onException`
- Cache, ORM, module events

### Strengths
- Sophisticated service architecture
- Built-in DI (WireBox) and caching (CacheBox)
- Comprehensive interception points
- First-class module system
- RESTful request handling
- Async/Future support

### Weaknesses
- Higher complexity/learning curve
- Larger memory footprint
- More opinionated structure
- Requires understanding multiple subsystems

---

## Wheels Bootstrap Analysis

### Pattern
**WireBox DI + Event-based initialization** - Event CFCs handle lifecycle

### Entry Point
`wheels/events/onapplicationstart.cfc` (1014 lines)

### Application.cfc Pattern
```cfml
function onApplicationStart() {
    // 1. Create WireBox injector
    wirebox = new wirebox.system.ioc.Injector("wheels.Wirebox");

    // 2. Get global object
    application.wo = wirebox.getInstance("global");

    // 3. Initialize onApplicationStart event
    initArgs.path = "wheels";
    initArgs.filename = "onapplicationstart";
    application.wirebox.getInstance(
        name = "wheels.events.onapplicationstart",
        initArguments = initArgs
    ).$init(this);
}
```

### $init() Bootstrap Sequence

**Phase 1: Environment Detection**
```cfml
if (structKeyExists(server, "boxlang")) {
    application.$wheels.serverName = "BoxLang";
} else if (structKeyExists(server, "lucee")) {
    application.$wheels.serverName = "Lucee";
} else {
    application.$wheels.serverName = "Adobe ColdFusion";
}

local.upgradeTo = application.wo.$checkMinimumVersion(
    engine = application.$wheels.serverName,
    version = application.$wheels.serverVersion
);
```

**Phase 2: Core Framework Setup**
```cfml
application.$wheels.version = "3.0.0";
application.$wheels.controllers = {};
application.$wheels.models = {};
application.$wheels.routes = [];
application.$wheels.cache = {
    sql = {},
    image = {},
    main = {},
    action = {},
    page = {},
    partial = {},
    query = {}
};
```

**Phase 3: Environment Configuration**
```cfml
// Load environment file
application.wo.$include(template = "/config/environment.cfm");

// URL rewriting detection
if (Right(request.cgi.script_name, 12) == "/" & application.$wheels.rewriteFile) {
    application.$wheels.URLRewriting = "On";
} else if (Len(request.cgi.path_info)) {
    application.$wheels.URLRewriting = "Partial";
} else {
    application.$wheels.URLRewriting = "Off";
}
```

**Phase 4: Default Settings** (300+ settings)
```cfml
// Environment-aware caching
application.$wheels.cacheActions = false;
if (application.$wheels.environment != "development") {
    application.$wheels.cacheActions = true;
    application.$wheels.cachePages = true;
    application.$wheels.cacheQueries = true;
}

// Function defaults (100+ functions)
application.$wheels.functions.findAll = {
    reload = false,
    parameterize = true,
    perPage = 10,
    returnAs = "query"
};
```

**Phase 5: Settings Override**
```cfml
// Load global settings
application.wo.$include(template = "/config/settings.cfm");

// Load environment-specific settings
if (FileExists(ExpandPath("/config/#env#/settings.cfm"))) {
    application.wo.$include(template = "/config/#env#/settings.cfm");
}
```

**Phase 6: Component Loading**
```cfml
// Plugin loading
if (application.$wheels.enablePluginsComponent) {
    application.wo.$loadPlugins();
}

// Mapper for routes
application.$wheels.mapper = application.wo.$createObjectFromRoot(
    path = "wheels",
    fileName = "Mapper",
    method = "$init"
);

// Load routes
application.wo.$loadRoutes();

// Dispatcher
application.$wheels.dispatch = application.wo.$createObjectFromRoot(
    path = "wheels",
    fileName = "Dispatch",
    method = "$init"
);

// Migrator
if (application.wheels.enableMigratorComponent) {
    application.wheels.migrator = application.wo.$createObjectFromRoot(
        path = "wheels",
        fileName = "Migrator",
        method = "init"
    );
}
```

**Phase 7: Developer Hooks**
```cfml
// Run developer's onApplicationStart
application.wo.$include(
    template = "#application.wheels.eventPath#/onapplicationstart.cfm"
);

// Auto-migrate if configured
if (application.wheels.enableMigratorComponent &&
    application.wheels.autoMigrateDatabase) {
    application.wheels.migrator.migrateToLatest();
}
```

### Environment Variables (.env support)
```cfml
// Load .env file in Application.cfc pseudo-constructor
if (!structKeyExists(this, "env")) {
    this.env = {};
    envFilePath = this.appDir & "../.env";
    if (fileExists(envFilePath)) {
        loadEnvFile(envFilePath, this.env);
    }
}

// Environment-specific .env files
if (len(currentEnv)) {
    envSpecificPath = this.appDir & "../.env." & currentEnv;
    if (fileExists(envSpecificPath)) {
        loadEnvFile(envSpecificPath, this.env);
    }
}

// Variable interpolation: ${VAR} syntax
performVariableInterpolation(this.env);
```

### Locking Strategy
```cfml
application.wo.$simpleLock(
    name = "reloadLock" & this.name,
    execute = "methodName",
    type = "readOnly|exclusive",
    timeout = 180,
    executeArgs = arguments
);
```

### Strengths
- WireBox DI from start
- Comprehensive default configuration
- Environment-aware settings
- Rails-like conventions
- DB migrations built-in
- Modern .env file support
- Event-driven extensibility
- Plugin architecture

### Weaknesses
- Very large initialization (1000+ lines)
- Many settings to understand
- Heavy on conventions
- Opinionated structure
- Complex locking patterns

---

## Comparison Matrix

| Aspect | FW/1 | ColdBox | Wheels |
|--------|------|---------|--------|
| **Bootstrap Location** | Request scope | Application scope | Application scope |
| **Initialization** | Lazy (on first request) | Eager (onApplicationStart) | Eager (onApplicationStart) |
| **DI Container** | Optional (DI/1 or WireBox) | Built-in (WireBox) | Built-in (WireBox) |
| **Configuration** | Single struct | Config CFC | Multiple CFM files |
| **Reload Mechanism** | Request-scoped recreation | Double-lock with shutdown | Lock + applicationStop |
| **Module Support** | Subsystems | First-class modules | Plugin system |
| **Caching** | Basic | CacheBox (multi-provider) | Built-in multi-tier |
| **Event System** | Limited callbacks | 26+ interception points | Event-based lifecycle |
| **Memory Footprint** | Minimal | Large | Medium |
| **Learning Curve** | Low | High | Medium |
| **Convention Strength** | Medium | High | Very High |
| **Setup Complexity** | ~100 lines | ~500 lines | ~1000 lines |

---

## Key Insights

### FW/1 Approach
- **Philosophy**: Minimal, flexible, get out of the way
- **Best for**: Small to medium apps, teams wanting control
- **Innovation**: Request-scoped singleton avoids reload complexity

### ColdBox Approach
- **Philosophy**: Enterprise-grade, comprehensive, batteries-included
- **Best for**: Large apps, teams, long-term maintenance
- **Innovation**: Service architecture with sophisticated lifecycle

### Wheels Approach
- **Philosophy**: Rails conventions, rapid development, opinionated
- **Best for**: Standard CRUD apps, teams familiar with Rails
- **Innovation**: .env file support, auto-migration, WireBox integration

---

## Files Examined

### FW/1
- `/Users/peter/Documents/Code/Active/frameworks/fw1/framework/one.cfc`

### ColdBox
- `/Users/peter/Documents/Code/Active/frameworks/coldbox-platform/system/Bootstrap.cfc`
- `/Users/peter/Documents/Code/Active/frameworks/coldbox-platform/system/web/Controller.cfc`

### Wheels
- `/Users/peter/Documents/Code/Active/frameworks/wheels/wheels/core/src/wheels/events/onapplicationstart.cfc`
- `/Users/peter/Documents/Code/Active/frameworks/wheels/wheels/core/src/wheels/events/onrequeststart.cfc`
