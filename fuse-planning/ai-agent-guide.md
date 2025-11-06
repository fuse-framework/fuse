# AI Agent Guide: Fuse Framework

Machine-readable reference for AI agents building Fuse applications.

**Repository:** https://github.com/fuse-framework/fuse
**Planning Docs:** https://github.com/fuse-framework/fuse-planning

---

## Quick Start for AI Agents

### What You Need to Know

**Fuse is:**
- Rails-inspired CFML framework
- Lucee 7 exclusive
- Convention-over-configuration
- ActiveRecord ORM
- Built-in DI, testing, CLI

### Critical Files

1. **[api-reference.yaml](api-reference.yaml)** - Machine-readable API schema (PARSE THIS FIRST)
2. **[error-reference.md](error-reference.md)** - All exceptions, when thrown, how to handle
3. **[patterns-catalog.md](patterns-catalog.md)** - Code recipes for common tasks
4. **[gotchas.md](gotchas.md)** - Common mistakes and edge cases
5. **[benchmarks.md](benchmarks.md)** - Performance characteristics
6. **[code-generation-templates/](code-generation-templates/)** - Templates for generating code

---

## Decision Trees

### When to Use Each Query Method

```
Need single record by ID?
  → User.find(id)
  → Returns: User|null
  → Executes: Immediate

Need single record by criteria?
  → User.where({...}).first()
  → Returns: User|null
  → Executes: On .first()

Need multiple records?
  → User.where({...}).get()
  → Returns: Array<User>
  → Executes: On .get()

Need to check existence?
  → User.where({...}).exists()
  → Returns: Boolean
  → Executes: On .exists()

Need count only?
  → User.where({...}).count()
  → Returns: Numeric
  → Executes: On .count()

Need column values?
  → User.where({...}).pluck("email")
  → Returns: Array<Any>
  → Executes: On .pluck()
```

### When to Eager Load Relationships

```
Accessing relationship in loop?
  YES → Use includes()
  NO → Access normally

Example:
BAD:  for (user in User.get()) { user.posts().get() }  // N+1
GOOD: for (user in User.includes("posts").get()) { user.posts }
```

### When to Use Transactions

```
Multiple database operations that must all succeed or all fail?
  YES → Use Transaction.run()

Need to manually control commit/rollback?
  YES → Use Transaction.begin/commit/rollback

Example:
Transaction.run(function() {
    user = User.create({...});
    user.posts().create({...});
    return user;
});
```

---

## Common Tasks

### Create a Model

**File:** `models/User.cfc`
```cfml
component extends="fuse.orm.ActiveRecord" {
    property name="id" type="numeric";
    property name="name" type="string";
    property name="email" type="string";

    function init() {
        super.init();

        // Validations
        validates("email", {required: true, email: true, unique: true});
        validates("name", {required: true, minLength: 2});

        // Relationships
        hasMany("posts");
        belongsTo("company");
    }
}
```

**Convention:** Model name = singular, table name = plural (User → users)

### Create a Handler

**File:** `handlers/UsersHandler.cfc`
```cfml
component {
    property name="userService" inject="UserService";

    function index() {
        return {
            view: "users/index",
            data: {users: User.all().get()}
        };
    }

    function show() {
        return {
            view: "users/show",
            data: {user: User.findOrFail(params.id)}
        };
    }

    function create() {
        var user = User.create(params.user);

        if (user.hasErrors()) {
            return {
                view: "users/new",
                data: {user: user, errors: user.getErrors()}
            };
        }

        relocate("users.show", {id: user.id});
    }
}
```

**Convention:** HandlerName + "Handler.cfc", methods = actions

### Create a Migration

**File:** `db/migrations/20250105120000_CreateUsersTable.cfc`
```cfml
component extends="fuse.orm.Migration" {
    function up() {
        schema.create("users", function(table) {
            table.id();
            table.string("name");
            table.string("email").unique();
            table.timestamps();
        });
    }

    function down() {
        schema.drop("users");
    }
}
```

**Convention:** Timestamp + underscore + CamelCaseDescription.cfc

### Define Routes

**File:** `config/routes.cfm`
```cfml
// RESTful resource (generates 7 routes)
router.resource("users");

// Custom routes
router.get("/dashboard", "Dashboard.index");
router.post("/login", "Auth.doLogin");

// Nested resources
router.resource("users", function(r) {
    r.resource("posts");
});
```

### Query with Relationships

```cfml
// Eager load (prevents N+1)
users = User.includes("posts", "company").where({active: true}).get();

// Access loaded relationships
for (user in users) {
    writeOutput(user.name);
    for (post in user.posts) {  // No query - already loaded
        writeOutput(post.title);
    }
}

// Nested eager loading
users = User.includes({posts: "comments"}).get();
```

---

## Type System Reference

### Method Return Types

| Method | Returns | Null Possible? | Throws? |
|--------|---------|----------------|---------|
| `find(id)` | Model\|null | Yes | No |
| `findOrFail(id)` | Model | No | ModelNotFoundException |
| `where().get()` | Array<Model> | No (empty array) | No |
| `where().first()` | Model\|null | Yes | No |
| `where().firstOrFail()` | Model | No | ModelNotFoundException |
| `where().count()` | Numeric | No | No |
| `where().exists()` | Boolean | No | No |
| `where().pluck(col)` | Array<Any> | No (empty array) | No |
| `create(data)` | Model | No | ValidationException if invalid |
| `save()` | Boolean | No | ValidationException if invalid |
| `delete()` | Boolean | No | No |

### Chainable Methods (Return QueryBuilder)

All return `this` for chaining:
- `where()`
- `whereIn()`, `whereNull()`, `whereNotNull()`, `whereRaw()`
- `orderBy()`, `limit()`, `offset()`
- `join()`, `leftJoin()`
- `includes()`, `with()`
- `select()`

### Execution Methods (Execute Query)

These actually run the query:
- `get()`, `first()`, `firstOrFail()`
- `count()`, `exists()`, `pluck()`
- `create()`, `update()`, `delete()`
- `find()`, `findOrFail()`, `all()`

---

## State Management

### Model Lifecycle States

```
new
  ↓ (hydrate from DB)
hydrated + exists=true
  ↓ (set attribute)
dirty
  ↓ (validate)
validated (errors or clean)
  ↓ (save)
persisted (exists=true, dirty=false)
  ↓ (delete)
deleted (exists=false)
```

### When Validation Runs

- **Automatically:** On `save()`, `create()`, `update()`
- **Manually:** Call `validate()`
- **Result:** Returns boolean, sets errors on model

### When Callbacks Fire

```
create:  beforeCreate → beforeSave → INSERT → afterSave → afterCreate
update:  beforeUpdate → beforeSave → UPDATE → afterSave → afterUpdate
delete:  beforeDelete → DELETE → afterDelete
```

---

## Error Handling Patterns

### Pattern 1: Check Before Acting

```cfml
user = User.find(id);
if (isNull(user)) {
    return {status: 404, message: "User not found"};
}
// Continue with user
```

### Pattern 2: Let Framework Handle

```cfml
try {
    user = User.findOrFail(id);
    // Continue with user
} catch (ModelNotFoundException e) {
    return {status: 404, message: e.message};
}
```

### Pattern 3: Validation Errors

```cfml
user = User.create(params.user);

if (user.hasErrors()) {
    return {
        status: 422,
        errors: user.getErrors()
    };
}

// User valid and saved
return {status: 201, data: user};
```

### Pattern 4: Transaction Rollback

```cfml
try {
    Transaction.run(function() {
        user = User.create({...});
        user.posts().create({...});
        return user;
    });
} catch (any e) {
    // Transaction rolled back automatically
    return {status: 500, message: "Operation failed"};
}
```

---

## Performance Guidelines

### Always Use Eager Loading in Loops

```cfml
// BAD: N+1 queries (1 + N)
users = User.get();
for (user in users) {
    posts = user.posts().get();  // Query per user
}

// GOOD: 2 queries total
users = User.includes("posts").get();
for (user in users) {
    posts = user.posts;  // Already loaded
}
```

### Use Specific Columns When Possible

```cfml
// BAD: SELECT * (unnecessary data)
users = User.get();

// GOOD: SELECT only needed columns
users = User.select(["id", "name", "email"]).get();
```

### Use count() Not get() for Counting

```cfml
// BAD: Fetches all records then counts
count = arrayLen(User.where({active: true}).get());

// GOOD: COUNT(*) query
count = User.where({active: true}).count();
```

### Use Raw SQL for Complex Queries

```cfml
// When query builder becomes awkward, use raw SQL
results = User.query()
    .whereRaw("DATE(created_at) = ?", [dateFormat(now(), "yyyy-mm-dd")])
    .get();

// Or completely raw
users = queryExecute("
    SELECT u.*, COUNT(p.id) as post_count
    FROM users u
    LEFT JOIN posts p ON p.user_id = u.id
    GROUP BY u.id
    HAVING post_count > ?
", [10]);
```

---

## File Structure Conventions

```
myapp/
├── Application.cfc           # Application configuration
├── config/
│   ├── fuse.cfc             # Framework config
│   ├── routes.cfm           # Route definitions
│   └── init.cfm             # Custom initialization (optional)
├── handlers/
│   ├── UsersHandler.cfc     # User controller
│   └── PostsHandler.cfc     # Post controller
├── models/
│   ├── User.cfc             # User model
│   └── Post.cfc             # Post model
├── views/
│   ├── users/
│   │   ├── index.cfm
│   │   └── show.cfm
│   └── layouts/
│       └── main.cfm
├── modules/                  # Application modules
│   └── auth/
│       └── Module.cfc
├── db/
│   └── migrations/          # Database migrations
│       └── 20250105_CreateUsers.cfc
├── tests/                   # Tests
│   ├── models/
│   └── handlers/
└── public/                  # Web root
    └── index.cfm           # Entry point
```

---

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| **Model** | Singular, PascalCase | User.cfc |
| **Table** | Plural, lowercase | users |
| **Handler** | PascalCase + "Handler" | UsersHandler.cfc |
| **Module** | Directory name, Module.cfc | auth/Module.cfc |
| **Migration** | Timestamp_Description | 20250105120000_CreateUsers.cfc |
| **Test** | Name + "Test.cfc" | UserTest.cfc |
| **View** | lowercase, matches action | users/index.cfm |
| **Layout** | lowercase | layouts/main.cfm |

---

## Module Structure

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
    }

    function boot(framework) {
        // Initialize module
        framework.router.middleware("auth", "modules.auth.AuthMiddleware");
    }

    function getRoutes() {
        return [
            {pattern: "/login", handler: "Auth.login", method: "GET"},
            {pattern: "/login", handler: "Auth.doLogin", method: "POST"}
        ];
    }

    function getInterceptors() {
        return {
            onBeforeHandler: "modules.auth.AuthInterceptor.checkAuth"
        };
    }
}
```

---

## Links to Detailed References

- **[API Reference (YAML)](api-reference.yaml)** - Complete machine-readable API
- **[Error Reference](error-reference.md)** - All exceptions and handling
- **[Patterns Catalog](patterns-catalog.md)** - Task-specific code recipes
- **[Gotchas](gotchas.md)** - Common mistakes and edge cases
- **[Benchmarks](benchmarks.md)** - Performance data and optimization
- **[Code Templates](code-generation-templates/)** - Generation templates

---

## Code Generation Strategy

When generating code:

1. **Start with template** from `code-generation-templates/`
2. **Follow conventions** (naming, file location, structure)
3. **Check api-reference.yaml** for exact method signatures
4. **Use patterns-catalog.md** for common tasks
5. **Handle errors** per error-reference.md
6. **Add type annotations** (JSDoc comments)
7. **Include validations** where appropriate
8. **Consider performance** (eager loading, specific selects)

---

## Example: Complete CRUD Feature

**Task:** Generate complete CRUD for Blog Posts

**1. Model** (`models/Post.cfc`):
```cfml
component extends="fuse.orm.ActiveRecord" {
    property name="id" type="numeric";
    property name="title" type="string";
    property name="body" type="string";
    property name="user_id" type="numeric";
    property name="published_at" type="date";

    function init() {
        super.init();

        validates("title", {required: true, minLength: 3});
        validates("body", {required: true});
        validates("user_id", {required: true});

        belongsTo("user");
        hasMany("comments");
    }

    function scopePublished(query) {
        return query.whereNotNull("published_at");
    }
}
```

**2. Migration** (`db/migrations/20250105130000_CreatePostsTable.cfc`):
```cfml
component extends="fuse.orm.Migration" {
    function up() {
        schema.create("posts", function(table) {
            table.id();
            table.string("title");
            table.text("body");
            table.foreignId("user_id").references("id").on("users");
            table.timestamp("published_at").nullable();
            table.timestamps();
        });
    }

    function down() {
        schema.drop("posts");
    }
}
```

**3. Handler** (`handlers/PostsHandler.cfc`):
```cfml
component {

    // GET /posts
    function index() {
        return {
            view: "posts/index",
            data: {
                posts: Post.published()
                    .includes("user")
                    .orderBy("published_at DESC")
                    .get()
            }
        };
    }

    // GET /posts/:id
    function show() {
        return {
            view: "posts/show",
            data: {
                post: Post.includes("user", "comments")
                    .findOrFail(params.id)
            }
        };
    }

    // GET /posts/new
    function new() {
        return {
            view: "posts/new",
            data: {post: Post.newInstance()}
        };
    }

    // POST /posts
    function create() {
        var post = Post.create(params.post);

        if (post.hasErrors()) {
            return {
                view: "posts/new",
                data: {post: post, errors: post.getErrors()}
            };
        }

        relocate("posts.show", {id: post.id});
    }

    // GET /posts/:id/edit
    function edit() {
        return {
            view: "posts/edit",
            data: {post: Post.findOrFail(params.id)}
        };
    }

    // PUT /posts/:id
    function update() {
        var post = Post.findOrFail(params.id);
        post.update(params.post);

        if (post.hasErrors()) {
            return {
                view: "posts/edit",
                data: {post: post, errors: post.getErrors()}
            };
        }

        relocate("posts.show", {id: post.id});
    }

    // DELETE /posts/:id
    function delete() {
        var post = Post.findOrFail(params.id);
        post.delete();

        relocate("posts.index");
    }
}
```

**4. Routes** (`config/routes.cfm`):
```cfml
router.resource("posts");
```

**5. Test** (`tests/models/PostTest.cfc`):
```cfml
component extends="fuse.testing.TestCase" {

    function testCreatePost() {
        var user = User.create({name: "Test", email: "test@test.com"});
        var post = Post.create({
            title: "Test Post",
            body: "Test body",
            user_id: user.id
        });

        assert(post.exists);
        assertEquals("Test Post", post.title);
        assertEquals(user.id, post.user_id);
    }

    function testValidation() {
        var post = Post.create({title: "AB"});  // Too short

        assert(post.hasErrors());
        assert(arrayLen(post.getErrors("title")) > 0);
    }

    function testPublishedScope() {
        var published = Post.create({
            title: "Published",
            body: "Body",
            user_id: 1,
            published_at: now()
        });

        var draft = Post.create({
            title: "Draft",
            body: "Body",
            user_id: 1
        });

        var posts = Post.published().get();

        assertEquals(1, arrayLen(posts));
        assertEquals(published.id, posts[1].id);
    }
}
```

This example demonstrates all major concepts in a working feature.
