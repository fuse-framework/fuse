# Migrating from FW/1

Comprehensive guide for migrating Framework One (FW/1) applications to Fuse.

## Overview

FW/1 and Fuse share similar philosophies around convention-over-configuration and simplicity. However, Fuse is built for modern CFML (Lucee 7) with ActiveRecord ORM, while FW/1 is ORM-agnostic. The main differences are in the ORM layer and dependency injection approach.

## Why Migrate

**Modern ORM:**
- Built-in ActiveRecord pattern (no manual queries)
- Relationship management (hasMany, belongsTo)
- Migrations for schema versioning
- Query builder with method chaining

**Enhanced Developer Experience:**
- Full-featured CLI (lucli) for generators
- Comprehensive test framework with assertions
- Better error messages with context
- Cleaner API design

**Performance:**
- Lucee 7 optimizations
- Transient handlers (no shared state issues)
- Efficient eager loading for N+1 prevention
- Better memory management

## Side-by-Side Comparison

| Feature | FW/1 | Fuse | Notes |
|---------|------|------|-------|
| **Controllers** | Controllers | Handlers | Similar concept |
| **Subsystems** | Subsystems | Modules | Module system |
| **DI** | DI/1 | Container | Constructor injection |
| **Services** | Service layer | Service layer | Same pattern |
| **Routes** | Convention-based | Explicit routes | More control |
| **ORM** | Bring your own | ActiveRecord | Built-in ORM |
| **Views** | CFML views | API-first | JSON responses |
| **Lifecycle** | beforeAction, etc. | Interceptors | Event-driven |
| **CLI** | None | lucli | Full CLI suite |

## Controllers to Handlers

### Basic Structure

**FW/1:**
```cfml
// controllers/main.cfc
component {

    function default(struct rc) {
        // Business logic
        rc.users = getUserService().list();
    }

    function show(struct rc) {
        rc.user = getUserService().get(rc.id);
    }

    function save(struct rc) {
        getUserService().save(rc.user);
        framework.redirect("main.default");
    }
}
```

**Fuse:**
```cfml
// app/handlers/Main.cfc
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
        variables.userService.save(form);
        return {
            success: true,
            location: this.urlFor("main_index")
        };
    }
}
```

**Key Differences:**

**Dependency Injection:**
- FW/1: Services accessed via `getXxxService()` magic methods
- Fuse: Services injected via constructor, stored in `variables` scope
- Fuse requires explicit registration in container

**Request Context:**
- FW/1: `rc` struct passed to all methods
- Fuse: Route params passed as method arguments
- Fuse uses `form` scope for POST data

**Return Values:**
- FW/1: Modify `rc` struct, implicit view rendering
- Fuse: Return struct for JSON API responses
- Fuse handlers return data, not views

**Redirects:**
- FW/1: `framework.redirect("section.item")`
- Fuse: Return struct with `location` key and `urlFor()`
- Fuse uses named routes for redirects

### Lifecycle Methods

**FW/1:**
```cfml
// controllers/main.cfc
component {

    function before(struct rc) {
        // Runs before all actions
        if (!isLoggedIn()) {
            framework.redirect("security.login");
        }
    }

    function after(struct rc) {
        // Runs after all actions
        rc.timestamp = now();
    }

    function onError(struct rc, any exception) {
        // Error handling
        rc.error = exception.message;
    }
}
```

**Fuse:**
```cfml
// Use interceptors for global lifecycle hooks
// Or add logic to individual handler actions

// app/handlers/Main.cfc
component {

    public struct function index() {
        // Authentication check in action
        if (!isLoggedIn()) {
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
- FW/1 `before()` → Fuse interceptors or per-action checks
- FW/1 `after()` → Fuse interceptors or post-processing in actions
- FW/1 `onError()` → Fuse global error handler or try/catch
- Fuse interceptors fire globally, not per-handler

## Subsystems to Modules

### FW/1 Subsystems

**FW/1:**
```
/subsystems/
  /admin/
    /controllers/
      users.cfc
      posts.cfc
    /views/
      users/list.cfm
    /model/
      services/
        userService.cfc
```

URL: `/admin/users/list`

**Fuse:**
```
/app/
  /modules/
    /admin/
      Module.cfc
      /handlers/
        Users.cfc
        Posts.cfc
      /models/
        (models if module-specific)
      /services/
        UserService.cfc
```

URL: `/admin/users` (via routes)

### Module Registration

**FW/1:**
```cfml
// Application.cfc
variables.framework.subsystems = {
    admin: {defaultSection: "users"}
};
```

**Fuse:**
```cfml
// config/modules.cfm
// Modules auto-discovered from /app/modules

// Or explicit registration
moduleManager.register("admin", new app.modules.admin.Module());
```

**Migration Notes:**
- FW/1 subsystems map to Fuse modules
- Fuse modules implement `IModule` interface
- Fuse modules have `register()` and `boot()` lifecycle
- Routes must be explicitly defined in Fuse

## DI/1 to Fuse Container

### Service Declaration

**FW/1 with DI/1:**
```cfml
// Application.cfc
variables.framework.diEngine = "di1";
variables.framework.diLocations = "model,controllers";

// Services auto-discovered from /model/services
```

**Fuse:**
```cfml
// config/bootstrap.cfc
// Register services explicitly
container.bind("userService", function(c) {
    return new app.services.UserService(
        c.resolve("datasource")
    );
});

// Or use auto-binding (future feature)
container.autoBindServices("/app/services");
```

**Migration Notes:**
- DI/1 uses auto-discovery by default
- Fuse requires explicit container binding (currently)
- Fuse supports constructor injection only
- Both support singleton and transient scopes

### Service Access

**FW/1:**
```cfml
// In controller
component {
    function default(struct rc) {
        // Magic method - DI/1 injects service
        rc.users = getUserService().list();
    }
}
```

**Fuse:**
```cfml
// In handler
component {
    public function init(required userService) {
        // Constructor injection
        variables.userService = arguments.userService;
        return this;
    }

    public struct function index() {
        var users = variables.userService.list();
        return {users: users};
    }
}
```

**Migration Notes:**
- FW/1 `getXxxService()` → Fuse constructor injection
- FW/1 magic methods → Fuse explicit dependencies
- Declare all dependencies in `init()` parameters
- Store injected services in `variables` scope

### Service Implementation

Service layer pattern is nearly identical in both frameworks:

**FW/1:**
```cfml
// model/services/userService.cfc
component {

    function init(userGateway) {
        variables.userGateway = arguments.userGateway;
        return this;
    }

    function list() {
        return variables.userGateway.getAll();
    }

    function get(id) {
        return variables.userGateway.getById(arguments.id);
    }

    function save(user) {
        return variables.userGateway.save(arguments.user);
    }
}
```

**Fuse:**
```cfml
// app/services/UserService.cfc
component {

    public function init(required datasource) {
        variables.datasource = arguments.datasource;
        return this;
    }

    public array function list() {
        return User::all().orderBy("name").get();
    }

    public any function get(required string id) {
        return User::find(arguments.id);
    }

    public any function save(required struct data) {
        return User::create(arguments.data);
    }
}
```

**Migration Notes:**
- Service layer logic stays mostly the same
- Replace manual queries/gateways with Fuse ORM
- Use `User::` static methods for model access
- Services remain testable and reusable

## Route Conventions

### Convention-Based vs Explicit Routes

**FW/1:**
```cfml
// URL pattern: /section/item
// Maps automatically to: controllers/section.cfc -> function item()

// Examples:
// /main/default -> controllers/main.cfc::default()
// /user/list -> controllers/user.cfc::list()
// /user/edit?id=5 -> controllers/user.cfc::edit(rc)
```

**Fuse:**
```cfml
// config/routes.cfm
// Explicit route definitions required

// RESTful resources
router.resource("users");
// Creates: GET /users -> Users.index
//          POST /users -> Users.create
//          GET /users/:id -> Users.show
//          etc.

// Custom routes
router.get("/", "Main.index", {name: "home"});
router.get("/about", "Pages.about", {name: "about"});
router.get("/users/:id/edit", "Users.edit", {name: "users_edit"});
```

**Migration Notes:**
- FW/1 uses URL conventions for routing
- Fuse requires explicit route registration
- Fuse route params passed as method arguments
- Fuse supports RESTful resource routes
- Fuse named routes enable URL generation

### URL Generation

**FW/1:**
```cfml
// In controllers/views
#buildURL('user.edit', 'id=#user.id#')#
#buildURL('user.list')#
#framework.buildURL('security.login')#
```

**Fuse:**
```cfml
// In handlers
this.urlFor("users_edit", {id: user.id})
this.urlFor("users_index")
this.urlFor("login")
```

**Migration Notes:**
- FW/1 `buildURL('section.item')` → Fuse `urlFor("route_name")`
- FW/1 query string params → Fuse hash-based params
- Both support named routes
- Fuse routes more explicit, less magic

## Adding ORM (ActiveRecord)

FW/1 doesn't include an ORM. When migrating to Fuse, you'll replace manual queries with ActiveRecord.

### From Manual Queries

**FW/1 (with QueryExecute):**
```cfml
// model/gateways/userGateway.cfc
component {

    function getAll() {
        return queryExecute("
            SELECT * FROM users
            ORDER BY name
        ");
    }

    function getById(id) {
        return queryExecute("
            SELECT * FROM users
            WHERE id = ?
        ", [arguments.id], {returntype: "struct"});
    }

    function save(user) {
        if (structKeyExists(arguments.user, "id")) {
            // Update
            queryExecute("
                UPDATE users
                SET name = ?, email = ?, updated_at = ?
                WHERE id = ?
            ", [
                arguments.user.name,
                arguments.user.email,
                now(),
                arguments.user.id
            ]);
        } else {
            // Insert
            queryExecute("
                INSERT INTO users (name, email, created_at, updated_at)
                VALUES (?, ?, ?, ?)
            ", [
                arguments.user.name,
                arguments.user.email,
                now(),
                now()
            ]);
        }
        return arguments.user;
    }
}
```

**Fuse (with ActiveRecord):**
```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        // Optional: Validations
        this.validates("name", {required: true});
        this.validates("email", {
            required: true,
            email: true,
            unique: true
        });

        return this;
    }
}

// Usage in service
public array function list() {
    return User::all().orderBy("name").get();
}

public any function get(required string id) {
    return User::find(arguments.id);
}

public any function save(required struct data) {
    if (structKeyExists(arguments.data, "id")) {
        // Update
        var user = User::find(arguments.data.id);
        user.update(arguments.data);
        return user;
    } else {
        // Create
        return User::create(arguments.data);
    }
}
```

**Benefits of ActiveRecord:**
- No SQL boilerplate
- Automatic timestamps (created_at, updated_at)
- Built-in validations
- Relationship management
- Query builder with method chaining
- Eager loading to prevent N+1 queries

### Relationships

**FW/1 (Manual Joins):**
```cfml
// model/gateways/userGateway.cfc
function getWithPosts(id) {
    return queryExecute("
        SELECT u.*, p.id AS post_id, p.title AS post_title
        FROM users u
        LEFT JOIN posts p ON u.id = p.user_id
        WHERE u.id = ?
    ", [arguments.id]);
}
```

**Fuse (Relationships):**
```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {
    public function init(datasource) {
        super.init(datasource);

        // Define relationship
        this.hasMany("posts");

        return this;
    }
}

// app/models/Post.cfc
component extends="fuse.orm.ActiveRecord" {
    public function init(datasource) {
        super.init(datasource);

        this.belongsTo("user");

        return this;
    }
}

// Usage
var user = User::find(id);
var posts = user.posts().get();  // Lazy load

// Or eager load to prevent N+1
var user = User::find(id).includes("posts").get();
```

See [Relationships](../guides/relationships.md) and [Eager Loading](../guides/eager-loading.md) guides.

## Request/Response Pattern

### Data Flow

**FW/1:**
```cfml
// 1. Request comes in: /user/edit?id=5
// 2. Framework populates rc: {section: "user", item: "edit", id: "5"}
// 3. Controller method modifies rc
component {
    function edit(struct rc) {
        rc.user = getUserService().get(rc.id);
        // Implicit: renders views/user/edit.cfm
    }
}
// 4. View accesses rc.user
```

**Fuse:**
```cfml
// 1. Request comes in: GET /users/5/edit
// 2. Router matches route, extracts params
// 3. Handler method receives params as arguments
component {
    public struct function edit(required string id) {
        var user = User::find(arguments.id);
        return {
            user: user
            // JSON response or view data
        };
    }
}
// 4. Framework serializes return value to JSON
```

**Migration Strategy:**

1. **API-First Approach:**
   - Migrate FW/1 controllers to Fuse handlers returning JSON
   - Build new frontend separately (React, Vue, etc.)
   - Decouple backend and frontend

2. **Hybrid Approach:**
   - Keep FW/1 views temporarily
   - Expose Fuse JSON APIs
   - Gradually migrate frontend

3. **View Migration:**
   - Check Fuse view system status
   - May need server-side rendering solution

## Migration Checklist

### Phase 1: Setup (Days 1-3)

- [ ] **Install Fuse and Lucli**
  ```bash
  box install lucli
  lucli new myapp
  ```

- [ ] **Configure Database**
  - Copy datasource config from FW/1 Application.cfc
  - Set up `.env` file
  - Configure `config/database.cfc`

- [ ] **Create Migrations**
  ```bash
  lucli generate migration create_users_table
  lucli generate migration create_posts_table
  ```
  - Generate migrations for existing schema
  - Run migrations: `lucli migrate`

### Phase 2: Models & ORM (Days 4-10)

- [ ] **Replace Gateways with Models**
  - Create model for each gateway: `lucli generate model User`
  - Define validations in model `init()`
  - Define relationships (hasMany, belongsTo)
  - Test models with unit tests

- [ ] **Convert Queries to ActiveRecord**
  - Replace `queryExecute()` with `User::where().get()`
  - Replace manual JOINs with `includes()` for eager loading
  - Use query builder for complex queries

### Phase 3: Services (Days 11-15)

- [ ] **Migrate Service Layer**
  - Copy services from `/model/services` to `/app/services`
  - Update constructor to accept dependencies
  - Replace gateway calls with model calls
  - Register services in container

- [ ] **Update Service Methods**
  - Replace manual queries with ORM methods
  - Add error handling (try/catch for RecordNotFoundException)
  - Test services independently

### Phase 4: Routes (Day 16)

- [ ] **Define Explicit Routes**
  ```cfml
  // config/routes.cfm
  router.get("/", "Main.index", {name: "home"});
  router.resource("users");
  router.resource("posts");
  ```
  - Map FW/1 URLs to Fuse routes
  - Use `router.resource()` for RESTful routes
  - Add custom routes as needed

- [ ] **Verify Routes**
  ```bash
  lucli routes
  ```

### Phase 5: Controllers to Handlers (Days 17-25)

- [ ] **Migrate Controller Logic**
  - Copy controllers to `/app/handlers`
  - Add constructor with dependency injection
  - Update method signatures (remove `rc` parameter, add route params)
  - Replace `rc.variable = value` with `return {variable: value}`
  - Replace `framework.redirect()` with return struct + `urlFor()`

- [ ] **Remove Framework Dependencies**
  - Replace `getXxxService()` with injected services
  - Replace `framework.buildURL()` with `this.urlFor()`
  - Remove framework-specific code

- [ ] **Handle Errors**
  - Add try/catch for database operations
  - Return error structs with status codes
  - Handle validation errors explicitly

### Phase 6: Replace Lifecycle Methods (Days 26-28)

- [ ] **Migrate `before()` Logic**
  - Extract authentication to interceptors
  - Or add checks to individual actions
  - Remove `before()` method

- [ ] **Migrate `after()` Logic**
  - Extract post-processing to interceptors
  - Or add to action return values
  - Remove `after()` method

- [ ] **Migrate `onError()` Logic**
  - Implement global error handler
  - Or use try/catch in actions
  - Remove `onError()` method

### Phase 7: Subsystems to Modules (Days 29-33)

- [ ] **Convert Subsystems**
  - Create module directory structure
  - Implement `IModule` interface
  - Register module in `config/modules.cfm`
  - Move handlers, models, services to module

- [ ] **Update Module Routes**
  - Define routes in module or main routes file
  - Use route prefixes for modules
  - Test module functionality

### Phase 8: Testing (Days 34-38)

- [ ] **Migrate Tests**
  - Convert to Fuse test framework
  - Update test syntax and assertions
  - Test models, services, handlers

- [ ] **Run Test Suite**
  ```bash
  lucli test
  ```
  - Fix failing tests
  - Add integration tests
  - Test error paths

### Phase 9: Views & Frontend (Days 39-45)

- [ ] **Decide Frontend Strategy**
  - Option A: JSON API + separate frontend
  - Option B: Server-rendered views (check Fuse status)
  - Option C: Hybrid approach

- [ ] **Implement Frontend**
  - Build new frontend if needed
  - Update API calls to Fuse endpoints
  - Test integration

### Phase 10: Deploy (Days 46-50)

- [ ] **Environment Configuration**
  - Set up `.env` for each environment
  - Configure production settings
  - Test deployment

- [ ] **Monitor & Iterate**
  - Deploy to staging
  - Run smoke tests
  - Monitor errors
  - Deploy to production

## Incremental Migration Strategy

For large FW/1 applications:

1. **Run Both Frameworks Concurrently**
   - Keep FW/1 app running
   - Deploy Fuse API alongside
   - Route API calls to Fuse
   - Keep views in FW/1 temporarily

2. **API-First Migration**
   - Migrate backend logic to Fuse
   - Expose JSON APIs
   - FW/1 views call Fuse APIs
   - Gradually replace FW/1 controllers

3. **Feature-by-Feature**
   - Identify isolated features
   - Migrate one feature completely
   - Test thoroughly
   - Repeat for next feature

## Common Pitfalls

### RC Scope Dependency

**Issue:** Expecting `rc` struct in Fuse handlers.

**Solution:**
```cfml
// Wrong
public struct function show() {
    var user = User::find(rc.id);  // rc doesn't exist
}

// Correct
public struct function show(required string id) {
    var user = User::find(arguments.id);
}
```

### Magic Service Methods

**Issue:** Using `getXxxService()` in Fuse.

**Solution:**
```cfml
// Wrong
var users = getUserService().list();  // Method doesn't exist

// Correct - inject service
public function init(required userService) {
    variables.userService = arguments.userService;
    return this;
}

public struct function index() {
    var users = variables.userService.list();
    return {users: users};
}
```

### Framework Redirects

**Issue:** Using `framework.redirect()` in Fuse.

**Solution:**
```cfml
// Wrong
framework.redirect("users.list");  // framework object doesn't exist

// Correct
return {
    success: true,
    location: this.urlFor("users_index")
};
```

### View Expectations

**Issue:** Expecting view rendering like FW/1.

**Solution:**
- Fuse handlers return data, not render views
- Build JSON API or separate frontend
- Check Fuse view system if needed

## Getting Help

- **Documentation:** [Models & ORM](../guides/models-orm.md), [Handlers](../handlers.md), [Routing](../guides/routing.md)
- **CLI Help:** `lucli help`
- **API Reference:** [API Reference](../reference/api-reference.md)
- **Tutorial:** [Blog Application](../tutorials/blog-application.md)

## Related Topics

- [Handlers](../handlers.md) - Handler structure and lifecycle
- [Models & ORM](../guides/models-orm.md) - ActiveRecord pattern
- [Routing](../guides/routing.md) - Explicit route definitions
- [Modules](../advanced/modules.md) - Module system
- [Testing](../guides/testing.md) - Test framework
