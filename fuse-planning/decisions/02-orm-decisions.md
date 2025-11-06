# ORM & Query Builder Decisions

Decisions for Fuse ActiveRecord-style ORM and query builder.

## Decision Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **ORM Style** | ActiveRecord | Rails pattern, model = database row |
| **Query Builder Architecture** | Two-layer (Eloquent-inspired) | QueryBuilder + ModelBuilder separation |
| **Where Syntax** | Hash-based (ActiveRecord) | Natural for CFML structs |
| **Query Execution** | Explicit `.get()` (Eloquent) | Clear when queries run |
| **Eager Loading** | Smart (ActiveRecord) | Auto-optimize JOIN vs separate queries |
| **Relationship Definition** | Method calls in `init()` | Rails pattern, clear execution order |
| **Scope Definition** | Named methods | CFML-friendly, easy to understand |

---

## ORM Style: ActiveRecord

### Decision
ActiveRecord pattern where model instances represent database rows.

### Rationale
1. **Rails proven**: Mature pattern, well-understood
2. **Intuitive**: Object = row mapping is natural
3. **Convention-friendly**: Minimal configuration needed
4. **Peter's experience**: Maintains Wheels (ActiveRecord-style)
5. **Relationship handling**: Clean association syntax

### Pattern
```cfml
// models/User.cfc
component extends="fuse.orm.ActiveRecord" {
    property name="id" type="numeric";
    property name="email" type="string";
    property name="name" type="string";

    function init() {
        super.init();

        // Validations
        validates("email", {required: true, email: true, unique: true});

        // Relationships
        hasMany("posts");
        belongsTo("company");
    }
}

// Usage
user = User.find(1);
user.name = "New Name";
user.save();

posts = user.posts();
```

### Alternatives Considered
- **Data Mapper**: Separation of domain/persistence (more complex)
- **Query-only**: No ORM, just query builder (less productive)

---

## Query Builder Architecture: Two-layer

### Decision
Separate QueryBuilder (raw queries) and ModelBuilder (ORM features).

### Rationale
1. **Clear separation**: Database queries vs ORM features
2. **Easier implementation**: Can build in stages
3. **Eloquent pattern**: Proven architecture
4. **Reusability**: QueryBuilder works standalone
5. **Maintainability**: Cleaner code organization

### Architecture
```
┌─────────────────┐
│  ActiveRecord   │ (Model base class)
│   (User.cfc)    │
└────────┬────────┘
         │ delegates static methods
         ▼
┌─────────────────┐
│  ModelBuilder   │ (ORM features)
│                 │ - Relationships
│                 │ - Scopes
│                 │ - Eager loading
└────────┬────────┘
         │ extends
         ▼
┌─────────────────┐
│  QueryBuilder   │ (Raw query building)
│                 │ - where()
│                 │ - join()
│                 │ - orderBy()
│                 │ - SQL generation
└─────────────────┘
```

### Implementation
```cfml
// fuse/modules/orm/QueryBuilder.cfc
component {
    function where(criteria) {
        // Build WHERE clause
        return this;
    }

    function orderBy(column, direction="ASC") {
        // Build ORDER BY
        return this;
    }

    function get() {
        // Execute query, return array
    }
}

// fuse/modules/orm/ModelBuilder.cfc
component extends="QueryBuilder" {
    function includes(relationships) {
        // Eager loading logic
        return this;
    }

    function scopeActive() {
        // Scope logic
        return this;
    }
}
```

---

## Where Syntax: Hash-based

### Decision
Use CFML structs for WHERE conditions (ActiveRecord style).

### Rationale
1. **Natural CFML**: Structs are native CFML construct
2. **Concise**: Less verbose than method calls
3. **Readable**: `{name: "John", active: true}` is clear
4. **Multiple conditions**: Easy to express AND conditions
5. **ActiveRecord familiarity**: Rails developers recognize pattern

### Syntax
```cfml
// Simple conditions (AND)
User.where({name: "John", active: true})

// Operator structs for complex conditions
User.where({age: {gte: 18}})
User.where({name: {like: "%john%"}})
User.where({status: {in: ["active", "pending"]}})

// Mix with raw SQL
User.where({active: true})
    .whereRaw("created_at > ?", [dateAdd("d", -7, now())])
```

### Operator Syntax
```cfml
// Supported operators in struct values
{
    eq: value,           // =  (default if no operator)
    neq: value,          // !=
    gt: value,           // >
    gte: value,          // >=
    lt: value,           // <
    lte: value,          // <=
    like: value,         // LIKE
    in: [array],         // IN
    notIn: [array],      // NOT IN
    isNull: true,        // IS NULL
    isNotNull: true      // IS NOT NULL
}
```

### Helper Methods
```cfml
// For developers who prefer method syntax
User.whereGt("age", 18)
User.whereLike("name", "%john%")
User.whereIn("status", ["active", "pending"])
User.whereNull("deleted_at")
```

---

## Query Execution: Explicit

### Decision
Require explicit `.get()` or `.first()` to execute queries.

### Rationale
1. **Clarity**: Always know when query executes
2. **No surprises**: No implicit execution on iteration
3. **Eloquent pattern**: Proven approach
4. **Performance awareness**: Developers see execution points
5. **Debugging**: Easier to find where queries run

### Pattern
```cfml
// Must explicitly execute
users = User.where({active: true}).get();        // Returns array
user = User.where({email: "test@test.com"}).first();  // Returns object or null

// Exception: find() executes immediately
user = User.find(1);  // No .get() needed (Rails pattern)
```

### Execution Methods
```cfml
.get()              // Execute, return array of models
.first()            // Execute, return first model or null
.firstOrFail()      // Execute, return first or throw exception
.pluck("column")    // Execute, return array of column values
.count()            // Execute, return count
.exists()           // Execute, return boolean
```

---

## Eager Loading: Smart

### Decision
ActiveRecord-style smart eager loading that chooses JOIN vs separate queries automatically.

### Rationale
1. **Performance**: Avoids N+1 queries
2. **Smart optimization**: Framework chooses best strategy
3. **Developer friendly**: Just use `includes()`, framework handles rest
4. **ActiveRecord pattern**: Proven approach from Rails

### Strategy Selection
```cfml
// Framework decides based on:
// - Number of relationships
// - Relationship type (hasMany vs belongsTo)
// - Query complexity

// Single relationship: Uses JOIN
users = User.includes("company").get();
// SQL: SELECT users.*, companies.* FROM users LEFT JOIN companies...

// Multiple relationships: Uses separate queries
users = User.includes("posts", "comments").get();
// SQL 1: SELECT * FROM users
// SQL 2: SELECT * FROM posts WHERE user_id IN (...)
// SQL 3: SELECT * FROM comments WHERE user_id IN (...)

// Nested: Mixed strategy
users = User.includes({posts: "comments"}).get();
```

### Manual Control
```cfml
// Force strategy when needed
User.joins("company").get()      // Force JOIN
User.preload("posts").get()      // Force separate queries
```

### Usage
```cfml
// Load users with their posts (no N+1)
users = User.includes("posts").where({active: true}).get();

for (user in users) {
    writeOutput(user.name);
    // posts already loaded, no additional query
    for (post in user.posts) {
        writeOutput(post.title);
    }
}
```

---

## Relationship Definition: Method calls in init()

### Decision
Define relationships using method calls in model's `init()` function.

### Rationale
1. **Rails pattern**: Familiar to Rails developers
2. **Clear execution order**: Happens during model initialization
3. **Explicit**: Easy to see what relationships exist
4. **Flexible**: Can add conditions, scopes to relationships

### Pattern
```cfml
// models/User.cfc
component extends="fuse.orm.ActiveRecord" {
    function init() {
        super.init();

        // One-to-many
        hasMany("posts");
        hasMany("comments");

        // Many-to-one
        belongsTo("company");

        // One-to-one
        hasOne("profile");

        // With options
        hasMany("publishedPosts", {
            className: "Post",
            conditions: {published: true},
            orderBy: "created_at DESC"
        });
    }
}
```

### Usage
```cfml
user = User.find(1);

// Access relationships
posts = user.posts();                    // Returns ModelBuilder
posts = user.posts().get();             // Execute, returns array
posts = user.posts().where({published: true}).get();

// Create through relationship
user.posts().create({title: "New Post", body: "..."});

// Association
company = user.company().first();
```

### Relationship Options
```cfml
hasMany("relationshipName", {
    className: "ModelName",          // Default: singularize(relationshipName)
    foreignKey: "user_id",           // Default: convention-based
    conditions: {published: true},   // Default WHERE conditions
    orderBy: "created_at DESC",      // Default ordering
    dependent: "destroy"             // On delete: destroy, delete, nullify
});

belongsTo("relationshipName", {
    className: "ModelName",
    foreignKey: "company_id",
    required: true                   // Validation
});
```

---

## Scope Definition: Named methods

### Decision
Define scopes as methods with `scope` prefix in model.

### Rationale
1. **CFML-friendly**: Methods are natural in CFC
2. **Clear**: Easy to understand, easy to find
3. **Flexible**: Full method capabilities
4. **Eloquent pattern**: Proven approach

### Pattern
```cfml
// models/User.cfc
component extends="fuse.orm.ActiveRecord" {
    function scopeActive(query) {
        return query.where({active: true});
    }

    function scopeRecent(query, days=7) {
        return query.where({
            created_at: {gte: dateAdd("d", -days, now())}
        });
    }

    function scopeVerified(query) {
        return query.whereNotNull("verified_at");
    }

    function scopeWithName(query, name) {
        return query.where({name: name});
    }
}
```

### Usage
```cfml
// Call without "scope" prefix
users = User.active().recent().get();
users = User.verified().recent(14).get();
users = User.withName("John").active().get();

// Chain with other query methods
users = User.active()
    .recent()
    .orderBy("created_at DESC")
    .limit(10)
    .get();
```

### Global Scopes
```cfml
// Applied automatically to all queries
component extends="fuse.orm.ActiveRecord" {
    function init() {
        super.init();

        // Always filter deleted records
        addGlobalScope("notDeleted", function(query) {
            return query.whereNull("deleted_at");
        });
    }
}

// All queries automatically include condition
users = User.get();  // Automatically adds WHERE deleted_at IS NULL

// Remove global scope when needed
users = User.withoutGlobalScope("notDeleted").get();
```

---

## Summary

ORM decisions create a **Rails-inspired ActiveRecord implementation** with:
- Eloquent's clean two-layer architecture
- ActiveRecord's intuitive syntax and smart features
- CFML-friendly patterns (struct-based where, method scopes)
- Modern query builder with explicit execution
- Smart eager loading to prevent N+1 queries

This combination provides best developer experience while maintaining clean implementation.
