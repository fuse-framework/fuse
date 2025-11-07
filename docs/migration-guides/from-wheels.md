# Migrating from Wheels

Comprehensive guide for migrating CFWheels applications to Fuse.

## Overview

Fuse and Wheels share many philosophical similarities - both are convention-over-configuration frameworks with ActiveRecord ORM, RESTful routing, and MVC architecture. The migration path is straightforward, with most concepts mapping directly.

## Why Migrate

**Modern Foundation:**
- Lucee 7 with modern CFML features
- Improved performance and memory management
- Better dependency injection container
- Enhanced test framework

**Developer Experience:**
- Cleaner, more intuitive API
- Better error messages with detailed context
- Comprehensive CLI tooling
- Modern query builder with method chaining

**Architecture:**
- Lightweight core (no bloat)
- Module system for extensibility
- Event-driven architecture via interceptors
- Built for API-first applications

## Side-by-Side Comparison

| Feature | Wheels | Fuse | Notes |
|---------|--------|------|-------|
| **ORM** | ActiveRecord | ActiveRecord | Very similar API |
| **Routing** | RESTful routes | RESTful routes | Nearly identical |
| **Controllers** | Controllers | Handlers | Different lifecycle |
| **Validations** | validatesXxx() | this.validates() | Similar syntax |
| **Callbacks** | beforeSave, etc. | beforeSave, etc. | Same names |
| **Finders** | findAll(), findOne() | where(), find() | Different methods |
| **DI** | Global injection | Constructor injection | More explicit |
| **CLI** | Basic generators | Full CLI suite | More commands |
| **Testing** | Unit/integration | Full test framework | Better assertions |

## Models

### Model Structure

**Wheels:**
```cfml
// models/User.cfc
component extends="Model" {

    function init() {
        // Validations
        validatesPresenceOf("email,name");
        validatesFormatOf(property="email", type="email");
        validatesUniquenessOf("email");

        // Relationships
        hasMany("posts");
        hasMany("comments");

        // Callbacks
        beforeSave("normalizeEmail");
    }

    function normalizeEmail() {
        this.email = lcase(trim(this.email));
    }
}
```

**Fuse:**
```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        // Validations
        this.validates("email", {
            required: true,
            email: true,
            unique: true
        });
        this.validates("name", {required: true});

        // Relationships
        this.hasMany("posts");
        this.hasMany("comments");

        // Callbacks
        this.beforeSave("normalizeEmail");

        return this;
    }

    private function normalizeEmail() {
        if (structKeyExists(this, "email")) {
            this.email = lcase(trim(this.email));
        }
    }
}
```

**Key Differences:**
- Fuse requires `datasource` argument in `init()`
- Fuse uses hash-based validation syntax (more flexible)
- Fuse callbacks registered via `this.beforeSave("method")`
- Fuse requires explicit `return this` in `init()`

## Finders

### Basic Queries

**Wheels:**
```cfml
// Find by primary key
user = model("User").findByKey(1);

// Find all users
users = model("User").findAll(order="name");

// Find with conditions
users = model("User").findAll(where="active=1", order="created_at DESC");

// Find one record
user = model("User").findOne(where="email='#email#'");

// Count records
count = model("User").findAll(select="COUNT(*) AS count");
```

**Fuse:**
```cfml
// Find by primary key
user = User::find(1);

// Find all users
users = User::all().orderBy("name").get();

// Find with conditions
users = User::where({active: true})
    .orderBy("created_at DESC")
    .get();

// Find one record
user = User::where({email: email}).first();

// Count records
count = User::count();
```

**Migration Notes:**
- Replace `model("User")` with `User::` (Lucee 7 static syntax)
- Replace `findByKey()` with `find()`
- Replace `findAll()` with `where().get()` or `all().get()`
- Replace `findOne()` with `where().first()`
- Fuse uses hash-based conditions instead of SQL strings
- Method chaining provides more flexibility

### Advanced Queries

**Wheels:**
```cfml
// Complex conditions
users = model("User").findAll(
    where="active=1 AND age >= 18",
    order="name ASC",
    maxrows=20,
    page=2
);

// Includes (eager loading)
posts = model("Post").findAll(
    include="user,comments",
    order="published_at DESC"
);

// Dynamic finders
user = model("User").findOneByEmail(email);
users = model("User").findAllByRoleAndActive("admin", true);
```

**Fuse:**
```cfml
// Complex conditions
users = User::where({active: true})
    .where({age: {gte: 18}})
    .orderBy("name ASC")
    .limit(20)
    .offset(20)
    .get();

// Includes (eager loading)
posts = Post::all()
    .includes("user")
    .includes("comments")
    .orderBy("published_at DESC")
    .get();

// Query building (no dynamic finders)
user = User::where({email: email}).first();
users = User::where({role: "admin", active: true}).get();
```

**Migration Notes:**
- Wheels `maxrows` → Fuse `limit()`
- Wheels `page` → Calculate offset: `offset((page - 1) * perPage)`
- Wheels `include` → Fuse `includes()` (method per association)
- No dynamic finders in Fuse - use explicit `where()` queries
- Fuse operators: `{gte: 18}`, `{like: "%term%"}`, `{in: [1,2,3]}`

## Validations

Wheels and Fuse validations are very similar, just different syntax.

**Wheels:**
```cfml
component extends="Model" {
    function init() {
        // Required fields
        validatesPresenceOf("email,name");

        // Format validation
        validatesFormatOf(property="email", type="email");

        // Uniqueness
        validatesUniquenessOf("email");

        // Length
        validatesLengthOf(property="name", minimum=2, maximum=100);

        // Numeric
        validatesNumericalityOf("age");

        // Range
        validatesInclusionOf(property="age", list="18,19,20,...");

        // Confirmation
        validatesConfirmationOf("password");

        // Custom messages
        validatesPresenceOf(property="email", message="Email is required");
    }
}
```

**Fuse:**
```cfml
component extends="fuse.orm.ActiveRecord" {
    public function init(datasource) {
        super.init(datasource);

        // Required and format combined
        this.validates("email", {
            required: true,
            email: true,
            unique: true
        });

        // Length validation
        this.validates("name", {
            required: true,
            length: {min: 2, max: 100}
        });

        // Numeric and range
        this.validates("age", {
            numeric: true,
            range: {min: 18, max: 120}
        });

        // Confirmation
        this.validates("password", {
            required: true,
            confirmation: true
        });

        return this;
    }
}
```

**Migration Notes:**
- `validatesPresenceOf()` → `{required: true}`
- `validatesFormatOf(type="email")` → `{email: true}`
- `validatesUniquenessOf()` → `{unique: true}`
- `validatesLengthOf()` → `{length: {min: X, max: Y}}`
- `validatesNumericalityOf()` → `{numeric: true}`
- `validatesConfirmationOf()` → `{confirmation: true}`
- Multiple validators combined in single `this.validates()` call
- Custom messages require custom validators (see [Custom Validators](../advanced/custom-validators.md))

## Routes

Wheels and Fuse routing are nearly identical.

**Wheels:**
```cfml
// config/routes.cfm
<cfset addRoute(name="home", pattern="/", controller="home", action="index")>
<cfset addRoute(name="about", pattern="/about", controller="pages", action="about")>

// Resource routes
<cfset addRoute(name="users", pattern="/users/[key]", controller="users", action="show")>
<cfset addRoute(name="users", pattern="/users", controller="users", action="index")>

// Named parameters
<cfset addRoute(pattern="/posts/[postId]/comments/[key]", controller="comments", action="show")>
```

**Fuse:**
```cfml
// config/routes.cfm
router.get("/", "Home.index", {name: "home"});
router.get("/about", "Pages.about", {name: "about"});

// Resource routes
router.resource("users");

// Named parameters
router.get("/posts/:postId/comments/:id", "Comments.show", {name: "post_comments_show"});
```

**Migration Notes:**
- `addRoute()` → `router.get()`, `router.post()`, etc.
- Wheels `[key]` → Fuse `:id`
- Wheels `[paramName]` → Fuse `:paramName`
- `resource()` auto-generates all RESTful routes
- Fuse uses `"Handler.action"` string instead of separate controller/action
- Both support named routes for `urlFor()`

### URL Generation

**Wheels:**
```cfml
// In controllers/views
#urlFor(route="users_show", key=user.id)#
#urlFor(controller="pages", action="about")#
#urlFor(route="home")#
```

**Fuse:**
```cfml
// In handlers
this.urlFor("users_show", {id: user.id})
this.urlFor("about")
this.urlFor("home")
```

**Migration Notes:**
- Wheels `key=` → Fuse `{id: }`
- Wheels route-based and controller/action-based → Fuse route-name only
- Same `urlFor` concept, cleaner API

## Controllers to Handlers

**Wheels:**
```cfml
// controllers/Users.cfc
component extends="Controller" {

    function init() {
        filters(through="requireLogin", except="index,show");
    }

    function index() {
        users = model("User").findAll(order="name");
    }

    function show() {
        user = model("User").findByKey(params.key);
    }

    function create() {
        user = model("User").new(params.user);
        if (user.save()) {
            redirectTo(route="users_show", key=user.id);
        } else {
            renderPage(action="new");
        }
    }

    function update() {
        user = model("User").findByKey(params.key);
        if (user.update(params.user)) {
            redirectTo(route="users_show", key=user.id);
        } else {
            renderPage(action="edit");
        }
    }

    function destroy() {
        user = model("User").findByKey(params.key);
        user.delete();
        redirectTo(route="users_index");
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
        var users = User::all().orderBy("name").get();
        return {users: users};
    }

    public struct function show(required string id) {
        try {
            var user = User::find(arguments.id);
            return {user: user};
        } catch (RecordNotFoundException e) {
            return {success: false, error: "User not found", status: 404};
        }
    }

    public struct function create() {
        var user = User::create(form);
        if (user.hasErrors()) {
            return {success: false, errors: user.getErrors(), status: 422};
        }
        return {
            success: true,
            user: user,
            location: this.urlFor("users_show", {id: user.id})
        };
    }

    public struct function update(required string id) {
        try {
            var user = User::find(arguments.id);
            if (!user.update(form)) {
                return {success: false, errors: user.getErrors(), status: 422};
            }
            return {success: true, user: user};
        } catch (RecordNotFoundException e) {
            return {success: false, error: "User not found", status: 404};
        }
    }

    public struct function destroy(required string id) {
        try {
            User::find(arguments.id).delete();
            return {success: true, deleted: true};
        } catch (RecordNotFoundException e) {
            return {success: false, error: "User not found", status: 404};
        }
    }
}
```

**Key Differences:**

**Lifecycle:**
- Wheels: Controllers cached, share state
- Fuse: Handlers are transient (new instance per request)
- Fuse handlers never share state between requests

**Dependency Injection:**
- Wheels: Global function injection (`model()`, `urlFor()`)
- Fuse: Constructor-based DI, explicit dependencies
- Fuse requires services passed to `init()`

**Return Values:**
- Wheels: Set variables, implicit view rendering
- Fuse: Return struct for JSON API responses
- Fuse handlers return explicit data structures

**Parameters:**
- Wheels: Access via `params` scope
- Fuse: Route params passed as method arguments
- Fuse uses `form` scope for POST data

**Filters:**
- Wheels: `filters(through="method")`
- Fuse: Use interceptors or handler logic
- Fuse interceptors fire globally, not per-handler

## Callbacks

Wheels and Fuse callbacks work identically.

**Wheels:**
```cfml
component extends="Model" {
    function init() {
        beforeValidation("trimFields");
        beforeSave("normalizeEmail");
        afterSave("sendWelcomeEmail");
        beforeCreate("setDefaults");
        beforeUpdate("updateTimestamp");
        beforeDelete("archiveData");
    }

    function normalizeEmail() {
        this.email = lcase(trim(this.email));
    }
}
```

**Fuse:**
```cfml
component extends="fuse.orm.ActiveRecord" {
    public function init(datasource) {
        super.init(datasource);

        this.beforeValidation("trimFields");
        this.beforeSave("normalizeEmail");
        this.afterSave("sendWelcomeEmail");
        this.beforeCreate("setDefaults");
        this.beforeUpdate("updateTimestamp");
        this.beforeDelete("archiveData");

        return this;
    }

    private function normalizeEmail() {
        if (structKeyExists(this, "email")) {
            this.email = lcase(trim(this.email));
        }
    }
}
```

**Migration Notes:**
- Same callback names: `beforeSave`, `afterSave`, `beforeCreate`, etc.
- Same registration pattern: `this.beforeSave("methodName")`
- Same return-false-to-abort behavior
- Callbacks fire in same order

## Migration Checklist

Follow this systematic approach to migrate your Wheels application to Fuse.

### Phase 1: Setup (Days 1-2)

- [ ] **Install Fuse and Lucli**
  ```bash
  # Install Lucli CLI
  box install lucli

  # Create new Fuse project
  lucli new myapp
  ```

- [ ] **Configure Database**
  - Copy database settings from Wheels `config/settings.cfm`
  - Update `.env` file with datasource info
  - Configure `config/database.cfc`

- [ ] **Copy Static Assets**
  - Copy `/files`, `/images`, `/stylesheets`, `/javascripts` to Fuse `/public`
  - Update asset paths in views

### Phase 2: Models (Days 3-7)

- [ ] **Migrate Model Files**
  - Copy models from `/models` to `/app/models`
  - Change `extends="Model"` to `extends="fuse.orm.ActiveRecord"`
  - Add `datasource` parameter to `init()`
  - Update validation syntax (see Validations section above)
  - Update finder calls (see Finders section above)

- [ ] **Update Relationships**
  - Verify `hasMany`, `belongsTo`, `hasOne` declarations
  - Update foreign key conventions if needed
  - Test relationship methods

- [ ] **Create Migrations**
  ```bash
  # Generate migration for each table
  lucli generate migration create_users_table
  lucli generate migration create_posts_table
  ```
  - Copy table schema from Wheels database
  - Use Fuse migration DSL
  - Run migrations: `lucli migrate`

- [ ] **Test Models**
  - Create model unit tests
  - Test CRUD operations
  - Test validations
  - Test callbacks
  - Test relationships

### Phase 3: Routes (Day 8)

- [ ] **Migrate Route Definitions**
  - Convert `config/routes.cfm` to Fuse syntax
  - Replace `addRoute()` with `router.get()`, `router.post()`, etc.
  - Use `router.resource()` for RESTful routes
  - Update parameter syntax (`[key]` → `:id`)
  - Verify named routes

- [ ] **Test Routes**
  ```bash
  # List all routes
  lucli routes
  ```
  - Verify all routes registered correctly
  - Check route names match

### Phase 4: Controllers to Handlers (Days 9-14)

- [ ] **Migrate Controller Logic**
  - Copy controllers from `/controllers` to `/app/handlers`
  - Remove `extends="Controller"`
  - Add `init()` with dependency injection
  - Update `model("User")` calls to `User::` static syntax
  - Update finder methods
  - Replace `params.key` with `arguments.id`
  - Replace `params.user` with `form` scope
  - Change actions to return structs instead of setting variables

- [ ] **Update URL Generation**
  - Replace `urlFor()` calls with `this.urlFor()`
  - Update route name references
  - Update parameter names (`key=` → `{id: }`)

- [ ] **Handle Errors**
  - Add try/catch for `RecordNotFoundException`
  - Return error structs with status codes
  - Handle validation errors explicitly

- [ ] **Remove Filters**
  - Extract filter logic to services or interceptors
  - Implement authentication in interceptors
  - Implement authorization in handler methods

### Phase 5: Views (Days 15-20)

Note: If your Wheels app uses views, plan for view migration. Fuse view system may differ.

- [ ] **Evaluate View Strategy**
  - Option A: JSON API only (no views)
  - Option B: External frontend (React, Vue, etc.)
  - Option C: Server-rendered views (check Fuse view status)

- [ ] **Migrate View Logic**
  - Extract view logic from controllers
  - Update variable references
  - Update `urlFor()` calls
  - Update form helpers (if available)

### Phase 6: Services & Business Logic (Days 21-25)

- [ ] **Extract Service Layer**
  - Move complex business logic from handlers to services
  - Create `/app/services` directory
  - Implement service classes
  - Register services in DI container
  - Inject services into handlers

- [ ] **Update Dependencies**
  - Register all services in container
  - Use constructor injection in handlers
  - Remove global function calls

### Phase 7: Testing (Days 26-30)

- [ ] **Migrate Tests**
  - Convert Wheels tests to Fuse test framework
  - Copy tests from `/tests` to `/tests`
  - Update test syntax
  - Use Fuse assertions
  - Test models, handlers, integration

- [ ] **Run Test Suite**
  ```bash
  lucli test
  ```
  - Fix failing tests
  - Add coverage for new features
  - Test error paths

### Phase 8: Polish & Deploy (Days 31-35)

- [ ] **Environment Configuration**
  - Set up `.env` for each environment
  - Configure production database
  - Set up error logging
  - Configure performance settings

- [ ] **Documentation**
  - Document migration decisions
  - Update README
  - Document custom code
  - Train team on Fuse patterns

- [ ] **Deploy**
  - Test in staging environment
  - Run smoke tests
  - Deploy to production
  - Monitor for errors

### Incremental Migration Strategy

For large applications, consider incremental migration:

1. **Run Both Frameworks**
   - Keep Wheels app running
   - Deploy Fuse alongside Wheels
   - Route new features to Fuse
   - Migrate old features gradually

2. **API-First Approach**
   - Migrate API endpoints first
   - Keep Wheels views temporarily
   - Migrate frontend separately

3. **Module-by-Module**
   - Identify independent modules
   - Migrate one module at a time
   - Test thoroughly before next module

## Common Pitfalls

### Scope Confusion

**Issue:** Using `params` instead of `arguments` in handlers.

**Solution:**
```cfml
// Wrong
public struct function show() {
    var user = User::find(params.key);  // params doesn't exist
}

// Correct
public struct function show(required string id) {
    var user = User::find(arguments.id);
}
```

### Finder Syntax

**Issue:** Using Wheels finder methods in Fuse.

**Solution:**
```cfml
// Wrong
users = User::findAll(where="active=1");  // Method doesn't exist

// Correct
users = User::where({active: true}).get();
```

### Model Access

**Issue:** Using `model()` function in Fuse.

**Solution:**
```cfml
// Wrong
user = model("User").findByKey(1);  // model() doesn't exist

// Correct
user = User::find(1);
```

### Validation Errors

**Issue:** Not checking validation errors after save.

**Solution:**
```cfml
// Wrong
var user = User::create(form);
// May have validation errors but not checked

// Correct
var user = User::create(form);
if (user.hasErrors()) {
    return {success: false, errors: user.getErrors()};
}
```

### Handler State

**Issue:** Storing request data in `variables` scope expecting persistence.

**Solution:**
- Remember handlers are transient (new instance per request)
- Don't rely on `variables` scope for cross-request state
- Use session, database, or cache for persistence

## Getting Help

- **Documentation:** `/docs` directory, especially [Models & ORM](../guides/models-orm.md)
- **CLI Help:** `lucli help [command]`
- **API Reference:** [API Reference](../reference/api-reference.md)
- **Examples:** [Blog Tutorial](../tutorials/blog-application.md)

## Related Topics

- [Models & ORM](../guides/models-orm.md) - ActiveRecord pattern in Fuse
- [Handlers](../handlers.md) - Handler lifecycle and patterns
- [Routing](../guides/routing.md) - RESTful routing in Fuse
- [Validations](../guides/validations.md) - Model validation rules
- [Testing](../guides/testing.md) - Testing framework
- [CLI Reference](../reference/cli-reference.md) - Command-line tools
