# Models & ORM

Fuse provides an ActiveRecord ORM pattern for database persistence with intuitive query builders, automatic table conventions, and powerful relationship support.

## Overview

Models represent database tables and provide methods for querying and persisting data:

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {
    // Conventions: table=users, primaryKey=id
}
```

```cfml
// Query data using static methods
var user = User::find(1);
var activeUsers = User::where({active: true}).get();

// Create and persist
var user = new User(datasource);
user.name = "John Doe";
user.email = "john@example.com";
user.save();
```

ActiveRecord combines data access and business logic in a single object, following Rails conventions.

## Model Conventions

Fuse uses convention over configuration to reduce boilerplate:

### Table Names

Model names are automatically pluralized to derive table names:

| Model Class | Table Name  | Convention     |
|-------------|-------------|----------------|
| User        | users       | Append 's'     |
| Post        | posts       | Append 's'     |
| Comment     | comments    | Append 's'     |
| Product     | products    | Append 's'     |

Override with `this.tableName`:

```cfml
// app/models/Person.cfc
component extends="fuse.orm.ActiveRecord" {
    // Override convention
    this.tableName = "people";
}
```

### Primary Keys

Primary key defaults to `id`:

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {
    // Default: this.primaryKey = "id"
}
```

Override for custom primary keys:

```cfml
// app/models/LegacyUser.cfc
component extends="fuse.orm.ActiveRecord" {
    this.tableName = "tbl_users";
    this.primaryKey = "user_id";
}
```

### Timestamps

Models automatically populate timestamp columns:
- `created_at` - Set on INSERT
- `updated_at` - Set on INSERT and UPDATE

Timestamps are managed automatically when columns exist:

```cfml
// Migration creates timestamp columns
table.timestamps();  // Adds created_at and updated_at

// Model automatically populates them
var user = new User(datasource);
user.name = "John";
user.save();
// user.created_at and user.updated_at now populated
```

## Creating Models

### Using Generators

Generate models with the CLI:

```bash
# Basic model
lucli generate model User

# Model with attributes
lucli generate model User name:string email:string:unique active:boolean

# Model with migration
lucli generate model Post title:string body:text user_id:integer:index
```

Generates `/app/models/User.cfc` and migration file.

### Manual Model Creation

Create model file manually:

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {
    // Optional: Override conventions
    // this.tableName = "users";
    // this.primaryKey = "id";
}
```

Model inherits all ActiveRecord functionality automatically.

## Basic Finders

Query data using static finder methods (Lucee 7 double-colon syntax):

### find() - Find by Primary Key

```cfml
// Find single record by ID
var user = User::find(1);
// Returns User instance or throws RecordNotFoundException

// Find multiple records by IDs
var users = User::find([1, 2, 3]);
// Returns array of User instances
```

### where() - Conditional Queries

```cfml
// Simple equality
var activeUsers = User::where({active: true}).get();

// Multiple conditions (AND)
var results = User::where({
    active: true,
    role: "admin"
}).get();

// Hash-based operators
var adults = User::where({
    age: {gte: 18}  // age >= 18
}).get();
```

### all() - Get All Records

```cfml
// Get all records
var allUsers = User::all().get();

// With ordering
var sortedUsers = User::all().orderBy("name").get();

// With limit
var recentUsers = User::all()
    .orderBy("created_at DESC")
    .limit(10)
    .get();
```

### first() - Get First Record

```cfml
// First record from query
var firstUser = User::where({active: true}).first();
// Returns User instance or null

// With ordering
var newest = User::all().orderBy("created_at DESC").first();
```

### count() - Count Records

```cfml
// Count all records
var totalUsers = User::count();

// Count with conditions
var activeCount = User::where({active: true}).count();
```

## Query Building

Chain query methods to build complex queries:

### Hash Syntax for Conditions

Supported operators:

```cfml
// Comparison operators
User::where({age: {gte: 18}}).get();        // age >= 18
User::where({age: {gt: 18}}).get();         // age > 18
User::where({age: {lte: 65}}).get();        // age <= 65
User::where({age: {lt: 65}}).get();         // age < 65
User::where({status: {ne: "banned"}}).get(); // status <> 'banned'

// Pattern matching
User::where({name: {like: "%John%"}}).get();  // name LIKE '%John%'

// List operators
User::where({
    role: {in: ["admin", "moderator"]}
}).get();  // role IN ('admin', 'moderator')

User::where({
    status: {notIn: ["banned", "deleted"]}
}).get();  // status NOT IN ('banned', 'deleted')

// Range operator
User::where({
    age: {between: [18, 65]}
}).get();  // age BETWEEN 18 AND 65

// NULL checks
User::where({deleted_at: {isNull: true}}).get();    // deleted_at IS NULL
User::where({email: {notNull: true}}).get();         // email IS NOT NULL
```

### Method Chaining

```cfml
// Chain multiple methods
var users = User::where({active: true})
    .where({role: "member"})
    .orderBy("created_at DESC")
    .limit(20)
    .offset(0)
    .get();

// Complex query
var results = Post::where({published: true})
    .where({view_count: {gte: 100}})
    .orderBy("published_at DESC")
    .limit(10)
    .get();
```

### Order By

```cfml
// Single column
User::all().orderBy("name").get();

// With direction
User::all().orderBy("created_at", "DESC").get();
User::all().orderBy("created_at DESC").get();  // Alternative

// Multiple columns
User::all()
    .orderBy("role")
    .orderBy("name")
    .get();
```

### Limit and Offset

```cfml
// Pagination
var page = 2;
var perPage = 20;
var offset = (page - 1) * perPage;

var users = User::where({active: true})
    .orderBy("name")
    .limit(perPage)
    .offset(offset)
    .get();
```

### Select Specific Columns

```cfml
// Select subset of columns
var users = User::all()
    .select("id, name, email")
    .get();

// Array syntax
var users = User::all()
    .select(["id", "name", "email"])
    .get();
```

## CRUD Operations

### create() - Insert New Record

Static method creates and persists in one call:

```cfml
// Create from struct
var user = User::create({
    name: "John Doe",
    email: "john@example.com",
    active: true
});
// Returns User instance with id populated

// Create from form data
var post = Post::create(form);
```

### save() - Persist Changes

Instance method saves new or updated record:

```cfml
// New record
var user = new User(datasource);
user.name = "Jane Doe";
user.email = "jane@example.com";
user.save();
// Executes INSERT, populates id and timestamps

// Existing record
var user = User::find(1);
user.email = "newemail@example.com";
user.save();
// Executes UPDATE with dirty tracking
```

`save()` returns boolean: `true` on success, `false` if validation fails.

### update() - Update Existing Record

Update attributes and save:

```cfml
// Instance method
var user = User::find(1);
user.update({
    email: "updated@example.com",
    active: false
});

// Static method (finds first, then updates)
User::where({id: 1}).update({
    email: "updated@example.com"
});
```

### delete() - Delete Record

```cfml
// Instance method
var user = User::find(1);
user.delete();

// Static method
User::where({active: false}).delete();  // Delete all inactive
```

## Dirty Tracking

Fuse tracks which attributes have changed:

```cfml
var user = User::find(1);
user.name = "New Name";

// Only UPDATE changed columns
user.save();
// SQL: UPDATE users SET name = ?, updated_at = ? WHERE id = ?
// Doesn't update unchanged columns
```

Benefits:
- Efficient UPDATE queries
- Optimistic concurrency control
- Audit trail support

## Mass Assignment

Assign multiple attributes from struct:

```cfml
var user = new User(datasource);
user.assign({
    name: "John Doe",
    email: "john@example.com",
    active: true
});
user.save();

// Or use create() to assign and save
var user = User::create({
    name: "John Doe",
    email: "john@example.com"
});
```

## Reloading Records

Refresh record from database:

```cfml
var user = User::find(1);
// ... user might be stale ...
user.reload();  // Fetch fresh data from database
```

## Model Callbacks

Hooks that fire at specific points in model lifecycle (implemented via `CallbackManager`):

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        // Register callbacks
        this.beforeSave("normalizeEmail");
        this.afterSave("sendWelcomeEmail");
        this.beforeDelete("archiveData");

        return this;
    }

    private function normalizeEmail() {
        if (structKeyExists(this, "email")) {
            this.email = lcase(trim(this.email));
        }
    }

    private function sendWelcomeEmail() {
        // Send email after successful save
    }

    private function archiveData() {
        // Archive before deletion
    }

}
```

Available callbacks:
- `beforeValidation`, `afterValidation`
- `beforeSave`, `afterSave`
- `beforeCreate`, `afterCreate`
- `beforeUpdate`, `afterUpdate`
- `beforeDelete`, `afterDelete`

Callbacks can abort operations by returning `false`.

## Common Patterns

### Finding or Creating

```cfml
// Find existing or create new
var user = User::where({email: "john@example.com"}).first();
if (isNull(user)) {
    user = User::create({
        email: "john@example.com",
        name: "John Doe"
    });
}
```

### Bulk Operations

```cfml
// Update multiple records
User::where({active: false})
    .update({status: "inactive"});

// Delete multiple records
Post::where({published_at: {isNull: true}})
    .where({created_at: {lt: dateAdd("d", -30, now())}})
    .delete();
```

### Scoped Queries

Define reusable query scopes in model:

```cfml
// app/models/Post.cfc
component extends="fuse.orm.ActiveRecord" {

    public function scopePublished(query) {
        return arguments.query.where({published: true});
    }

    public function scopeRecent(query) {
        return arguments.query
            .orderBy("published_at DESC")
            .limit(10);
    }

}
```

```cfml
// Use scopes
var posts = Post::published().recent().get();
```

### Attribute Casting

Cast database values to specific types:

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        // Define casts
        this.casts = {
            active: "boolean",
            settings: "json",
            birth_date: "date"
        };

        return this;
    }

}
```

## Anti-Patterns

### N+1 Queries

**Bad:**
```cfml
// Loads posts
var posts = Post::all().limit(20).get();

// Then loads user for EACH post (21 queries total)
for (var post in posts) {
    var author = User::find(post.user_id);
    // ...
}
```

**Good:**
```cfml
// Eager load users with posts (2 queries)
var posts = Post::all()
    .includes("user")
    .limit(20)
    .get();

for (var post in posts) {
    var author = post.user();  // Already loaded
    // ...
}
```

See [Eager Loading](eager-loading.md) guide for details.

### Direct Database Queries

**Bad:**
```cfml
var result = queryExecute("
    SELECT * FROM users WHERE active = ?
", [true]);
```

**Good:**
```cfml
var users = User::where({active: true}).get();
```

Use ORM for type safety, consistency, and maintainability.

### Ignoring Validations

**Bad:**
```cfml
var user = new User(datasource);
user.email = "not-an-email";  // Invalid
user.save();  // Fails silently or throws
```

**Good:**
```cfml
var user = new User(datasource);
user.email = "not-an-email";

if (user.isValid()) {
    user.save();
} else {
    // Handle validation errors
    var errors = user.getErrors();
}
```

Always validate before persisting. See [Validations](validations.md).

### Hardcoded Table Names

**Bad:**
```cfml
queryExecute("SELECT * FROM users WHERE id = ?", [id]);
```

**Good:**
```cfml
User::find(id);
```

Let models handle table naming conventions.

### Missing Error Handling

**Bad:**
```cfml
var user = User::find(999);  // Throws if not found
writeOutput(user.name);
```

**Good:**
```cfml
try {
    var user = User::find(999);
    writeOutput(user.name);
} catch (RecordNotFoundException e) {
    // Handle not found
}

// Or use first() which returns null
var user = User::where({id: 999}).first();
if (!isNull(user)) {
    writeOutput(user.name);
}
```

## Example: Complete Model

```cfml
/**
 * User Model
 * Represents application users
 */
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    /**
     * Initialize model with validations and relationships
     */
    public function init(datasource) {
        super.init(datasource);

        // Validations
        this.validates("email", {
            required: true,
            email: true,
            unique: true
        });

        this.validates("name", {
            required: true,
            length: {min: 2, max: 100}
        });

        // Relationships
        this.hasMany("posts");
        this.hasMany("comments");
        this.hasOne("profile");

        // Callbacks
        this.beforeSave("normalizeEmail");
        this.beforeCreate("setDefaults");

        return this;
    }

    /**
     * Normalize email to lowercase
     */
    private function normalizeEmail() {
        if (structKeyExists(this, "email")) {
            this.email = lcase(trim(this.email));
        }
    }

    /**
     * Set default values for new records
     */
    private function setDefaults() {
        if (!structKeyExists(this, "active")) {
            this.active = true;
        }
        if (!structKeyExists(this, "role")) {
            this.role = "member";
        }
    }

    /**
     * Get full name (computed property)
     */
    public string function getFullName() {
        return this.name;
    }

    /**
     * Check if user is admin
     */
    public boolean function isAdmin() {
        return this.role == "admin";
    }

    /**
     * Scope: Active users only
     */
    public function scopeActive(query) {
        return arguments.query.where({active: true});
    }

    /**
     * Scope: Users by role
     */
    public function scopeByRole(query, role) {
        return arguments.query.where({role: arguments.role});
    }

}
```

Usage:

```cfml
// Create user
var user = User::create({
    name: "John Doe",
    email: "JOHN@EXAMPLE.COM"  // Will be normalized
});

// Query with scopes
var admins = User::active().byRole("admin").get();

// Use relationships
var posts = user.posts().where({published: true}).get();

// Computed properties
writeOutput(user.getFullName());
writeOutput(user.isAdmin() ? "Yes" : "No");
```

## Testing Models

Test model CRUD operations and query logic:

```cfml
// tests/models/UserTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        variables.user = new app.models.User(getDatasource());
    }

    public function testCreateUser() {
        var user = User::create({
            name: "John Doe",
            email: "john@example.com"
        });

        assertGreaterThan(0, user.id);
        assertEqual("John Doe", user.name);
        assertNotNull(user.created_at);
    }

    public function testFindUser() {
        var created = User::create({name: "Jane", email: "jane@example.com"});
        var found = User::find(created.id);

        assertEqual(created.id, found.id);
        assertEqual("Jane", found.name);
    }

    public function testUpdateUser() {
        var user = User::create({name: "Old Name", email: "test@example.com"});
        user.name = "New Name";
        user.save();

        var reloaded = User::find(user.id);
        assertEqual("New Name", reloaded.name);
    }

    public function testDeleteUser() {
        var user = User::create({name: "Delete Me", email: "delete@example.com"});
        var id = user.id;
        user.delete();

        assertThrows(function() {
            User::find(id);
        });
    }

    public function testWhereQuery() {
        User::create({name: "Active User", email: "active@example.com", active: true});
        User::create({name: "Inactive User", email: "inactive@example.com", active: false});

        var activeUsers = User::where({active: true}).get();
        assertCount(1, activeUsers);
        assertEqual("Active User", activeUsers[1].name);
    }

    public function testCountQuery() {
        User::create({name: "User 1", email: "user1@example.com"});
        User::create({name: "User 2", email: "user2@example.com"});

        var count = User::count();
        assertEqual(2, count);
    }
}
```

See [Testing](testing.md) guide for comprehensive testing patterns.

## Common Errors

### ModelNotFoundException

**Error:** Record not found when using `find()` or `findOrFail()`.

**Cause:** Attempting to fetch record with non-existent ID.

```cfml
// Throws ModelNotFoundException
var user = User::find(999);
```

**Solution:** Use `first()` which returns null, or wrap in try/catch:

```cfml
// Option 1: Use first() and check
var user = User::where({id: 999}).first();
if (isNull(user)) {
    // Handle not found
}

// Option 2: Try/catch
try {
    var user = User::findOrFail(999);
} catch (ModelNotFoundException e) {
    // Handle error
}
```

See [Error Reference](../../fuse-planning/error-reference.md#modelnotfoundexception) for details.

### ValidationException

**Error:** Save fails with validation errors.

**Cause:** Attempting to save invalid data when validations are defined.

```cfml
var user = User::create({
    email: "invalid-email"  // Fails email validation
});
// Throws ValidationException
```

**Solution:** Check validity before saving:

```cfml
var user = new User(datasource);
user.email = "invalid-email";

if (user.isValid()) {
    user.save();
} else {
    var errors = user.getErrors();
    // {email: ["is not a valid email"]}
}
```

See [Validations](validations.md) and [Error Reference](../../fuse-planning/error-reference.md#validationexception).

### Incorrect Table Name Convention

**Error:** Table not found or query fails.

**Cause:** Model name doesn't match table name conventions.

```cfml
// app/models/Person.cfc
component extends="fuse.orm.ActiveRecord" {
    // Expects "persons" table but table is "people"
}
```

**Solution:** Override with `this.tableName`:

```cfml
// app/models/Person.cfc
component extends="fuse.orm.ActiveRecord" {
    this.tableName = "people";
}
```

### Missing Datasource

**Error:** Datasource not configured or not passed to model.

**Cause:** Model instantiated without datasource parameter.

```cfml
var user = new User();  // Missing datasource!
user.save();  // Fails
```

**Solution:** Always pass datasource or use static methods:

```cfml
// Option 1: Pass datasource
var user = new User(getDatasource());

// Option 2: Use static create()
var user = User::create({...});  // Gets datasource automatically
```

### N+1 Query Problem

**Error:** Slow performance loading relationships in loops.

**Cause:** Lazy loading relationships inside iteration.

```cfml
var posts = Post::all().get();
for (var post in posts) {
    var author = post.user().first();  // Query per post!
}
```

**Solution:** Use eager loading with `includes()`:

```cfml
var posts = Post::all().includes("user").get();
for (var post in posts) {
    var author = post.user;  // Already loaded
}
```

See [Eager Loading](eager-loading.md) for comprehensive guide.

## API Reference

For detailed method signatures and parameters:

- [Model Methods](../reference/api-reference.md#models-activerecord) - find(), where(), create(), save(), update(), delete()
- [Query Builder Methods](../reference/api-reference.md#querybuilder) - where(), whereIn(), orderBy(), limit(), get(), first()
- [Model Builder Methods](../reference/api-reference.md#modelbuilder-orm) - includes(), with()
- [WHERE Operators](../reference/api-reference.md#where-operators) - Advanced query operators (gt, lt, like, in, etc.)

## Related Topics

- [Migrations](migrations.md) - Create and manage database schema
- [Validations](validations.md) - Validate model data
- [Relationships](relationships.md) - Define associations between models
- [Eager Loading](eager-loading.md) - Optimize queries with relationship loading
- [Testing](testing.md) - Test model logic
