# Migrating from ColdBox

Comprehensive guide for migrating ColdBox applications to Fuse.

## Overview

ColdBox and Fuse are both full-featured CFML frameworks with MVC architecture, but they differ significantly in scope and philosophy. ColdBox is enterprise-focused with extensive modules and conventions, while Fuse prioritizes simplicity and modern patterns with Lucee 7.

## Why Migrate

**Simplified Architecture:**
- Lighter framework core (faster bootstrapping)
- Fewer abstractions (easier to understand)
- Convention over configuration (less setup)
- Transient handlers (no shared state issues)

**Modern Foundation:**
- Built for Lucee 7 from ground up
- ActiveRecord ORM (simpler than ColdBox ORM)
- Enhanced CLI tooling
- Better performance characteristics

**Developer Experience:**
- Cleaner, more intuitive API
- Less boilerplate code
- Comprehensive test framework
- API-first design patterns

**Note:** ColdBox excels in enterprise environments with complex requirements. Migrate to Fuse if you prefer simplicity and modern patterns over extensive enterprise features.

## Side-by-Side Comparison

| Feature | ColdBox | Fuse | Notes |
|---------|---------|------|-------|
| **Handlers** | Event handlers | Handlers | Different lifecycle |
| **Modules** | ColdBox modules | Fuse modules | Similar concepts |
| **DI** | WireBox | Container | Constructor injection |
| **ORM** | Hibernate/Quick | ActiveRecord | Simpler ORM |
| **Interceptors** | Interceptors | Interceptors | Event system |
| **Routes** | Convention + explicit | Explicit only | More control |
| **Views** | CFML views | API-first | JSON focus |
| **CLI** | CommandBox | lucli | Lightweight CLI |
| **Testing** | TestBox | Fuse Testing | Built-in framework |

## Handlers to Handlers

Both frameworks use handlers for request processing, but with different lifecycles and conventions.

### Basic Handler Structure

**ColdBox:**
```cfml
// handlers/Users.cfc
component {

    property name="userService" inject="UserService";

    function index(event, rc, prc) {
        prc.users = userService.list();
        event.setView("users/index");
    }

    function show(event, rc, prc) {
        prc.user = userService.get(rc.id);
        event.setView("users/show");
    }

    function save(event, rc, prc) {
        var user = userService.save(rc);
        relocate(event="users.index");
    }
}
```

**Fuse:**
```cfml
// app/handlers/Users.cfc
component {

    public function init(required userService) {
        variables.userService = arguments.userService;
        return this;
    }

    public struct function index() {
        var users = variables.userService.list();
        return {users: users};
    }

    public struct function show(required string id) {
        var user = variables.userService.get(arguments.id);
        return {user: user};
    }

    public struct function create() {
        var user = variables.userService.save(form);
        return {
            success: true,
            user: user,
            location: this.urlFor("users_index")
        };
    }
}
```

**Key Differences:**

**Dependency Injection:**
- ColdBox: `property` injection via WireBox
- Fuse: Constructor injection via `init()`
- Fuse requires explicit parameter declaration

**Method Arguments:**
- ColdBox: `event`, `rc`, `prc` passed to all handlers
- Fuse: Route params passed as named arguments
- Fuse uses `form` scope for POST data

**Return Values:**
- ColdBox: Modify `prc`, call `event.setView()`
- Fuse: Return struct for JSON API responses
- Fuse handlers return data structures

**Lifecycle:**
- ColdBox: Handlers cached, persist across requests
- Fuse: Handlers transient (new instance per request)
- Fuse prevents shared state issues

**Relocation:**
- ColdBox: `relocate(event="users.index")`
- Fuse: Return struct with `location` and `urlFor()`

### Handler Actions

**ColdBox:**
```cfml
component {

    property name="userService" inject;

    // preHandler - runs before all actions
    function preHandler(event, rc, prc, action) {
        if (!auth.isLoggedIn()) {
            relocate(event="security.login");
        }
    }

    // postHandler - runs after all actions
    function postHandler(event, rc, prc, action) {
        prc.timestamp = now();
    }

    // aroundHandler - wraps action execution
    function aroundHandler(event, rc, prc, targetAction, eventArguments) {
        // Before action
        var result = arguments.targetAction(argumentCollection=arguments.eventArguments);
        // After action
        return result;
    }

    function index(event, rc, prc) {
        prc.users = userService.list();
    }
}
```

**Fuse:**
```cfml
component {

    public function init(required userService, required auth) {
        variables.userService = arguments.userService;
        variables.auth = arguments.auth;
        return this;
    }

    // Use interceptors for global hooks
    // Or implement per-action logic

    public struct function index() {
        // Authentication check
        if (!variables.auth.isLoggedIn()) {
            return {
                success: false,
                error: "Unauthorized",
                status: 401
            };
        }

        var users = variables.userService.list();
        return {
            users: users,
            timestamp: now()
        };
    }
}
```

**Migration Notes:**
- ColdBox `preHandler()` → Fuse interceptors or per-action checks
- ColdBox `postHandler()` → Fuse interceptors or return value modification
- ColdBox `aroundHandler()` → Fuse interceptors
- Fuse interceptors fire globally, not per-handler

## Interceptors to Event Service

Both frameworks have event-driven architectures, but different APIs.

### Interceptor Definition

**ColdBox:**
```cfml
// interceptors/SecurityInterceptor.cfc
component {

    function preProcess(event, interceptData) {
        // Runs before request processing
        if (!isLoggedIn()) {
            event.overrideEvent("security.login");
        }
    }

    function postHandler(event, interceptData) {
        // Runs after handler execution
        logRequest(event.getCurrentEvent());
    }

    function onException(event, interceptData) {
        // Handle errors
        logError(interceptData.exception);
    }
}
```

**Fuse:**
```cfml
// Similar pattern with Fuse interceptors
// (Note: Fuse interceptor API may differ - check current implementation)

// Interceptors registered in bootstrap/config
interceptorService.register("security", new app.interceptors.SecurityInterceptor());
```

**ColdBox Interception Points:**
- `preProcess`, `postProcess`
- `preHandler`, `postHandler`, `aroundHandler`
- `preEvent`, `postEvent`
- `onException`, `onRequestCapture`

**Fuse Interception Points:**
- Check Fuse documentation for current interceptor events
- Likely similar: `onBeforeHandler`, `onAfterHandler`
- Global request/response lifecycle hooks

## Modules

Both frameworks support modular architecture.

### Module Structure

**ColdBox:**
```
/modules/
  /admin/
    ModuleConfig.cfc
    /handlers/
      Users.cfc
    /models/
      UserService.cfc
    /views/
      users/index.cfm
```

**Fuse:**
```
/app/modules/
  /admin/
    Module.cfc
    /handlers/
      Users.cfc
    /models/
      (optional module-specific models)
    /services/
      UserService.cfc
```

### Module Configuration

**ColdBox:**
```cfml
// modules/admin/ModuleConfig.cfc
component {

    this.title = "Admin Module";
    this.author = "Your Name";
    this.webURL = "http://www.example.com";
    this.description = "Admin functionality";

    function configure() {
        // Module settings
        settings = {
            displayName = "Admin"
        };

        // Module conventions
        conventions = {
            handlersLocation = "handlers"
        };

        // Parent settings
        parentSettings = {};

        // Module routes
        routes = [
            {pattern="/admin", handler="admin", action="index"}
        ];

        // Interceptors
        interceptors = [
            {class="interceptors.Security"}
        ];
    }

    function onLoad() {
        // Executed when module loads
    }

    function onUnload() {
        // Executed when module unloads
    }
}
```

**Fuse:**
```cfml
// app/modules/admin/Module.cfc
component implements="fuse.interfaces.IModule" {

    public function register(required container) {
        // Register module services
        arguments.container.bind("adminService", function(c) {
            return new services.AdminService();
        });
    }

    public function boot(required router, required container) {
        // Register routes
        arguments.router.get("/admin", "Admin.Users.index", {name: "admin_index"});
        arguments.router.resource("admin/users");
    }
}
```

**Migration Notes:**
- ColdBox `ModuleConfig.cfc` → Fuse `Module.cfc`
- ColdBox `configure()` → Fuse `register()` and `boot()`
- ColdBox auto-discovers modules → Fuse may require explicit registration
- Both support module-specific DI and routing

## WireBox to Fuse Container

### Dependency Injection

**ColdBox with WireBox:**
```cfml
// config/WireBox.cfc
component {
    function configure() {
        map("UserService")
            .to("model.services.UserService")
            .asSingleton();

        map("UserGateway")
            .to("model.gateways.UserGateway")
            .asSingleton();
    }
}

// In handler - property injection
component {
    property name="userService" inject="UserService";
    property name="logger" inject="logbox:logger:{this}";

    function index(event, rc, prc) {
        prc.users = userService.list();
    }
}
```

**Fuse:**
```cfml
// config/bootstrap.cfc
container.bind("userService", function(c) {
    return new app.services.UserService(
        c.resolve("datasource")
    );
}).asSingleton();

// In handler - constructor injection
component {

    public function init(required userService, required logger) {
        variables.userService = arguments.userService;
        variables.logger = arguments.logger;
        return this;
    }

    public struct function index() {
        var users = variables.userService.list();
        return {users: users};
    }
}
```

**Migration Notes:**
- WireBox `property inject` → Fuse constructor parameters
- WireBox mapping DSL → Fuse `container.bind()`
- WireBox `asSingleton()` → Fuse `.asSingleton()`
- Fuse requires explicit constructor injection

## Routes

### Route Configuration

**ColdBox:**
```cfml
// config/Router.cfc
component {

    function configure() {
        setFullRewrites(true);

        // Resourceful routes
        resources("users");

        // Custom routes
        route("/").to("main.index");
        route("/about").to("pages.about");

        // Convention-based routing fallback
        route("/:handler/:action?").end();
    }
}
```

**Fuse:**
```cfml
// config/routes.cfm

// RESTful resources
router.resource("users");

// Custom routes
router.get("/", "Main.index", {name: "home"});
router.get("/about", "Pages.about", {name: "about"});

// No convention-based fallback - all routes explicit
```

**Migration Notes:**
- ColdBox `resources()` → Fuse `router.resource()`
- ColdBox `route().to()` → Fuse `router.get()`, etc.
- ColdBox has convention fallback → Fuse requires explicit routes
- Both support named routes

### URL Generation

**ColdBox:**
```cfml
// In handlers/views
event.buildLink(linkto="users.show", queryString="id=#user.id#")
event.buildLink(linkto="users.index")
event.buildLink("users.edit", {id: user.id})
```

**Fuse:**
```cfml
// In handlers
this.urlFor("users_show", {id: user.id})
this.urlFor("users_index")
this.urlFor("users_edit", {id: user.id})
```

## ORM: Hibernate/Quick to ActiveRecord

ColdBox typically uses Hibernate ORM or Quick (QueryBuilder). Fuse uses ActiveRecord.

### Basic Model

**ColdBox with Quick:**
```cfml
// models/User.cfc
component extends="quick.models.BaseEntity" {

    // Table name (optional if following conventions)
    variables._table = "users";

    // Attributes
    function _scopes() {
        return {};
    }

    // Relationships
    function posts() {
        return hasMany("Post");
    }

    // Validation
    function _validation() {
        return {
            email: {required: true, type: "email"},
            name: {required: true}
        };
    }
}
```

**Fuse:**
```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        // Table name (optional if following conventions)
        // this.tableName = "users";

        // Validations
        this.validates("email", {
            required: true,
            email: true,
            unique: true
        });
        this.validates("name", {required: true});

        // Relationships
        this.hasMany("posts");

        return this;
    }
}
```

### Querying

**ColdBox with Quick:**
```cfml
// Find all
users = getInstance("User").all();

// Find with conditions
users = getInstance("User")
    .where("active", 1)
    .orderBy("name")
    .get();

// Find one
user = getInstance("User").find(id);

// Eager loading
users = getInstance("User")
    .with("posts")
    .get();
```

**Fuse:**
```cfml
// Find all
users = User::all().get();

// Find with conditions
users = User::where({active: true})
    .orderBy("name")
    .get();

// Find one
user = User::find(id);

// Eager loading
users = User::all()
    .includes("posts")
    .get();
```

**Migration Notes:**
- Quick `getInstance("Model")` → Fuse `Model::` static syntax
- Quick `where("column", value)` → Fuse `where({column: value})`
- Quick `with()` → Fuse `includes()`
- Both support method chaining

### Creating Records

**ColdBox with Quick:**
```cfml
// Create and save
user = getInstance("User").fill({
    name: "John Doe",
    email: "john@example.com"
}).save();

// Or
user = getInstance("User").create({
    name: "John Doe",
    email: "john@example.com"
});
```

**Fuse:**
```cfml
// Create and save
user = User::create({
    name: "John Doe",
    email: "john@example.com"
});

// Or
user = new User(datasource);
user.name = "John Doe";
user.email = "john@example.com";
user.save();
```

## Migration Checklist

### Phase 1: Setup (Days 1-3)

- [ ] **Install Fuse and Lucli**
  ```bash
  box install lucli
  lucli new myapp
  ```

- [ ] **Configure Database**
  - Copy datasource config from ColdBox config/ColdBox.cfc
  - Set up `.env` file
  - Configure `config/database.cfc`

- [ ] **Create Migrations**
  ```bash
  lucli generate migration create_users_table
  ```
  - Generate migrations for existing schema
  - Run: `lucli migrate`

### Phase 2: Models (Days 4-10)

- [ ] **Migrate Models**
  - Convert Quick/Hibernate entities to ActiveRecord
  - Update validation syntax
  - Update relationship definitions
  - Test model CRUD operations

- [ ] **Update Queries**
  - Replace `getInstance("Model")` with `Model::`
  - Update where clause syntax
  - Replace `with()` with `includes()`
  - Test complex queries

### Phase 3: Services (Days 11-15)

- [ ] **Migrate Service Layer**
  - Copy services from `/models/services` to `/app/services`
  - Update constructor injection
  - Replace model access patterns
  - Register services in container

- [ ] **Update Service Methods**
  - Replace Quick/Hibernate calls with ActiveRecord
  - Add error handling
  - Test service methods

### Phase 4: Routes (Days 16-18)

- [ ] **Define Explicit Routes**
  ```cfml
  // config/routes.cfm
  router.get("/", "Main.index", {name: "home"});
  router.resource("users");
  ```
  - Map all ColdBox routes to Fuse
  - Remove convention-based routing
  - Use `router.resource()` where appropriate

- [ ] **Verify Routes**
  ```bash
  lucli routes
  ```

### Phase 5: Handlers (Days 19-28)

- [ ] **Migrate Handler Logic**
  - Copy handlers from `/handlers` to `/app/handlers`
  - Change property injection to constructor injection
  - Remove `event`, `rc`, `prc` parameters
  - Add route parameters to method signatures
  - Update return values (struct instead of view)

- [ ] **Update Handler Methods**
  - Replace `event.setView()` with return struct
  - Replace `relocate()` with location + `urlFor()`
  - Replace `event.buildLink()` with `this.urlFor()`
  - Add error handling (try/catch)

- [ ] **Remove Lifecycle Methods**
  - Extract `preHandler` logic to interceptors or actions
  - Extract `postHandler` logic to interceptors
  - Remove `aroundHandler` (use interceptors)

### Phase 6: Interceptors (Days 29-31)

- [ ] **Migrate Interceptors**
  - Adapt ColdBox interceptors to Fuse event system
  - Update interception point names
  - Register interceptors in config
  - Test global functionality

### Phase 7: Modules (Days 32-36)

- [ ] **Convert Modules**
  - Create Fuse module structure
  - Implement `IModule` interface
  - Migrate handlers, models, services
  - Register module routes

- [ ] **Test Module Integration**
  - Verify module loading
  - Test module routes
  - Test module services

### Phase 8: Testing (Days 37-42)

- [ ] **Migrate Tests**
  - Convert TestBox specs to Fuse tests
  - Update test syntax and assertions
  - Test models, services, handlers

- [ ] **Run Test Suite**
  ```bash
  lucli test
  ```
  - Fix failing tests
  - Add integration tests

### Phase 9: Views & Frontend (Days 43-50)

- [ ] **Decide Frontend Strategy**
  - Option A: JSON API + separate frontend
  - Option B: Server-rendered views (check Fuse status)
  - Option C: Keep ColdBox views, Fuse backend

- [ ] **Implement Frontend**
  - Build new frontend if needed
  - Update API integrations

### Phase 10: Deploy (Days 51-55)

- [ ] **Environment Configuration**
  - Configure `.env` for each environment
  - Test deployment process

- [ ] **Monitor & Iterate**
  - Deploy to staging
  - Run smoke tests
  - Deploy to production

## Incremental Migration Strategy

For large ColdBox applications:

1. **Parallel Deployment:**
   - Run ColdBox and Fuse concurrently
   - Route API endpoints to Fuse
   - Keep ColdBox views temporarily

2. **Module-by-Module:**
   - Identify independent modules
   - Migrate one module completely
   - Test thoroughly before next module

3. **API-First Approach:**
   - Migrate backend to Fuse JSON APIs
   - Build new frontend separately
   - Gradually replace ColdBox

## Common Pitfalls

### Event Object Dependency

**Issue:** Using `event` object in Fuse.

**Solution:**
```cfml
// Wrong
public struct function show() {
    var id = event.getValue("id");  // event doesn't exist
}

// Correct
public struct function show(required string id) {
    // arguments.id from route params
}
```

### Property Injection

**Issue:** Using `property inject` in Fuse.

**Solution:**
```cfml
// Wrong
property name="userService" inject;

// Correct - constructor injection
public function init(required userService) {
    variables.userService = arguments.userService;
    return this;
}
```

### View Rendering

**Issue:** Calling `event.setView()` in Fuse.

**Solution:**
```cfml
// Wrong
event.setView("users/index");

// Correct - return data
return {users: users};
```

### Relocation

**Issue:** Using `relocate()` in Fuse.

**Solution:**
```cfml
// Wrong
relocate(event="users.index");

// Correct
return {
    success: true,
    location: this.urlFor("users_index")
};
```

## Getting Help

- **Documentation:** [Handlers](../handlers.md), [Models & ORM](../guides/models-orm.md)
- **CLI:** `lucli help`
- **API Reference:** [API Reference](../reference/api-reference.md)
- **Tutorial:** [Blog Application](../tutorials/blog-application.md)

## Related Topics

- [Handlers](../handlers.md) - Handler lifecycle and patterns
- [Models & ORM](../guides/models-orm.md) - ActiveRecord pattern
- [Routing](../guides/routing.md) - Route configuration
- [Modules](../advanced/modules.md) - Module system
- [Testing](../guides/testing.md) - Test framework
