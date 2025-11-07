# Performance Optimization

Optimize Fuse application performance through query optimization, eager loading strategies, database indexing, and profiling techniques for production-ready applications.

## Overview

Performance optimization focuses on database query efficiency:

```cfml
// Before optimization: N+1 queries
var posts = Post::all().get();  // 1 query
for (var post in posts) {
    var author = post.user().first();  // N queries
    var comments = post.comments().get();  // N queries
}
// Total: 1 + N + N queries

// After optimization: 3 queries
var posts = Post::all()
    .includes(["user", "comments"])
    .get();

for (var post in posts) {
    var author = post.user;  // Cached
    var comments = post.comments;  // Cached
}
// Total: 3 queries (constant)
```

Performance gains scale with data volume and proper optimization can reduce response times from seconds to milliseconds.

## Query Optimization Strategies

### Select Only Required Columns

Fetch only columns you need:

```cfml
// Bad: Select all columns
var users = User::all().get();  // SELECT * FROM users

// Good: Select specific columns
var users = User::select(["id", "name", "email"]).get();
// SELECT id, name, email FROM users
```

**Benefits:**
- Reduced memory usage
- Faster query execution
- Lower network transfer
- Smaller result sets

### Use Appropriate Query Methods

Choose optimal query method for use case:

```cfml
// Finding single record by ID
var user = User::find(1);  // Optimal: SELECT ... WHERE id = 1 LIMIT 1

// Checking existence
var exists = User::where({email: "test@example.com"}).exists();
// Optimal: SELECT 1 FROM users WHERE email = ? LIMIT 1

// Counting records
var count = User::where({active: true}).count();
// Optimal: SELECT COUNT(*) FROM users WHERE active = 1

// Loading first result
var user = User::where({email: "test@example.com"}).first();
// Optimal: SELECT ... WHERE email = ? LIMIT 1
```

### Limit Result Sets

Always paginate large result sets:

```cfml
// Bad: Load all records
var posts = Post::all().get();  // Could be millions

// Good: Paginate results
var posts = Post::all()
    .limit(20)
    .offset(0)
    .get();

// Better: Use pagination helper
var page = val(url.page) ?: 1;
var perPage = 20;
var offset = (page - 1) * perPage;

var posts = Post::all()
    .orderBy("created_at DESC")
    .limit(perPage)
    .offset(offset)
    .get();
```

### Optimize WHERE Clauses

Use indexed columns in WHERE clauses:

```cfml
// Good: Query on indexed column
var user = User::where({email: "john@example.com"}).first();
// Assumes email has index

// Good: Query on primary key
var user = User::find(1);

// Less optimal: Query on non-indexed column
var users = User::where({bio: "Developer"}).get();
// Consider adding index if queried frequently
```

### Avoid OR Conditions on Different Columns

OR queries can prevent index usage:

```cfml
// Less optimal: OR on different columns
var users = User::where("name = ? OR email = ?", ["John", "john@example.com"]).get();

// Better: Use separate queries or UNION
var byName = User::where({name: "John"}).get();
var byEmail = User::where({email: "john@example.com"}).get();
// Combine results in application
```

## Eager Loading Best Practices

### When to Eager Load

Eager load when iterating over collections:

```cfml
// Always eager load in loops
var posts = Post::all()
    .includes("user")
    .get();

for (var post in posts) {
    writeOutput("#post.title# by #post.user.name#");
}
```

See [Eager Loading](../guides/eager-loading.md) guide for comprehensive coverage.

### Nested Eager Loading

Load deep relationship trees efficiently:

```cfml
// Load three levels: posts -> comments -> user
var posts = Post::all()
    .includes("comments.user")
    .limit(20)
    .get();

// Only 3 queries total:
// 1. Posts
// 2. Comments for those posts
// 3. Users for those comments

for (var post in posts) {
    for (var comment in post.comments) {
        writeOutput("#comment.user.name#: #comment.content#");
    }
}
```

### Avoid Over-Eager Loading

Don't load unused relationships:

```cfml
// Bad: Loading relationships never used
var users = User::includes(["posts", "comments", "profile"]).get();

for (var user in users) {
    writeOutput(user.name);  // Only using name!
}

// Good: Load only what you need
var users = User::select(["id", "name"]).get();

for (var user in users) {
    writeOutput(user.name);
}
```

### Selective Eager Loading

Eager load conditionally based on need:

```cfml
// Load relationships only when displaying detail view
var post = Post::find(1);

if (showComments) {
    post = Post::find(1).includes("comments").first();
}
```

## Caching Patterns

**Note:** Caching system coming in v1.1. This section outlines planned patterns.

### Query Result Caching

Cache expensive query results:

```cfml
// Planned caching pattern (v1.1)
var stats = cache.remember("dashboard_stats", 3600, function() {
    return {
        userCount: User::count(),
        postCount: Post::count(),
        commentCount: Comment::count()
    };
});
```

### Fragment Caching

Cache rendered output fragments:

```cfml
// Planned view caching (v1.1)
cache.fragment("popular_posts", 1800, function() {
    var posts = Post::where({published: true})
        .orderBy("views DESC")
        .limit(10)
        .get();

    return renderView("posts/popular", {posts: posts});
});
```

### Application-Level Caching

Implement manual caching now:

```cfml
// Current workaround: Application scope caching
if (!structKeyExists(application, "categoryCache") ||
    dateDiff("n", application.categoryCacheTime, now()) > 60) {

    application.categoryCache = Category::all()
        .orderBy("name")
        .get();

    application.categoryCacheTime = now();
}

var categories = application.categoryCache;
```

## Database Indexing

### Index Foreign Keys

Always index foreign key columns:

```cfml
// migrations/2025-11-06-create-posts.cfc
public void function up() {
    schema.createTable("posts", function(table) {
        table.id();
        table.integer("user_id");
        table.string("title");
        table.text("body");
        table.timestamps();

        // Index foreign key
        table.index("user_id");
    });
}
```

### Index Frequently Queried Columns

Add indexes for common WHERE clauses:

```cfml
// migrations/2025-11-06-add-email-index.cfc
public void function up() {
    schema.table("users", function(table) {
        // Email queried frequently for login
        table.index("email");
    });
}

public void function down() {
    schema.table("users", function(table) {
        table.dropIndex("email");
    });
}
```

### Unique Indexes

Use unique indexes for uniqueness constraints:

```cfml
public void function up() {
    schema.table("users", function(table) {
        // Enforce uniqueness and improve query performance
        table.unique("email");
        table.unique("username");
    });
}
```

### Composite Indexes

Index multiple columns queried together:

```cfml
public void function up() {
    schema.table("posts", function(table) {
        // Frequently query published posts by date
        table.index(["published", "created_at"]);

        // User's published posts
        table.index(["user_id", "published"]);
    });
}
```

**Index order matters:** Place most selective column first.

### Indexing Best Practices

**Do index:**
- Primary keys (automatic)
- Foreign keys
- Columns in WHERE clauses
- Columns in ORDER BY
- Columns in JOIN conditions
- Unique constraint columns

**Don't over-index:**
- Low cardinality columns (true/false)
- Rarely queried columns
- Tables with heavy writes (indexes slow INSERTs)

## Profiling Queries

### Enable Query Debugging

Debug queries in development:

```cfml
// config/database.cfc
component {
    public struct function getDatasources() {
        return {
            default: {
                name: "myapp",
                host: "localhost",
                database: "myapp_dev",
                username: "root",
                password: "",
                // Log queries in development
                logQueries: true,
                logSlowQueries: true,
                slowQueryThreshold: 1000  // Log queries > 1 second
            }
        };
    }
}
```

### Manual Query Timing

Time expensive operations:

```cfml
var startTime = getTickCount();

var posts = Post::where({published: true})
    .includes(["user", "comments"])
    .orderBy("created_at DESC")
    .limit(50)
    .get();

var elapsed = getTickCount() - startTime;

if (elapsed > 100) {
    writeLog("Slow query: #elapsed#ms", "warning");
}
```

### Analyze Query Plans

Use database EXPLAIN to analyze queries:

```sql
-- MySQL
EXPLAIN SELECT * FROM posts WHERE user_id = 1;

-- Check for:
-- - Full table scans (type: ALL)
-- - Missing indexes (key: NULL)
-- - High row counts

-- Add indexes based on EXPLAIN results
```

### Query Result Analysis

Log query execution details:

```cfml
var result = queryExecute(
    "SELECT * FROM posts WHERE user_id = ?",
    [1],
    {datasource: "myapp"}
);

// Lucee provides execution time
writeLog("Query executed in: #result.executionTime#ms");
writeLog("Rows returned: #result.recordCount#");
```

## N+1 Detection

### Identifying N+1 Queries

Watch for queries in loops:

```cfml
// N+1 problem example
var users = User::all().limit(100).get();  // 1 query

for (var user in users) {
    var postCount = user.posts().count();  // 100 queries!
    writeOutput("#user.name#: #postCount# posts<br>");
}
// Total: 101 queries
```

**Detection signs:**
- Response time scales with record count
- Database shows many similar queries
- Query count = 1 + N (where N = records)

### Automatic Detection

Implement query counter:

```cfml
// app/handlers/Base.cfc
component {

    public void function beforeAction() {
        if (isDevEnvironment()) {
            request.queryCount = 0;
            request.queryStart = getTickCount();
        }
    }

    public void function afterAction() {
        if (isDevEnvironment()) {
            var elapsed = getTickCount() - request.queryStart;
            var count = request.queryCount;

            if (count > 10) {
                writeLog("N+1 detected: #count# queries in #elapsed#ms", "warning");
            }
        }
    }
}
```

### Fixing N+1 Problems

Use eager loading:

```cfml
// Fixed with eager loading
var users = User::all()
    .includes("posts")
    .limit(100)
    .get();  // 2 queries

for (var user in users) {
    var postCount = arrayLen(user.posts);  // No query, cached
    writeOutput("#user.name#: #postCount# posts<br>");
}
// Total: 2 queries (constant)
```

## Batch Operations

### Batch Inserts

Insert multiple records efficiently:

```cfml
// Bad: Individual inserts
for (var i = 1; i <= 1000; i++) {
    User::create({
        name: "User #i#",
        email: "user#i#@example.com"
    });
}
// 1000 separate INSERT queries

// Better: Batch insert (planned for v1.1)
var users = [];
for (var i = 1; i <= 1000; i++) {
    arrayAppend(users, {
        name: "User #i#",
        email: "user#i#@example.com"
    });
}
User::insertBatch(users);  // Single multi-value INSERT

// Current workaround: Raw SQL
var sql = "INSERT INTO users (name, email) VALUES ";
var values = [];
for (var i = 1; i <= 1000; i++) {
    arrayAppend(values, "(?, ?)");
}
sql &= arrayToList(values, ", ");

var params = [];
for (var i = 1; i <= 1000; i++) {
    arrayAppend(params, "User #i#");
    arrayAppend(params, "user#i#@example.com");
}

queryExecute(sql, params, {datasource: getDatasource()});
```

### Batch Updates

Update multiple records in one query:

```cfml
// Good: Single update query
User::where({active: false})
    .update({status: "inactive"});

// Updates all matching records in one query
// UPDATE users SET status = 'inactive' WHERE active = 0
```

### Batch Deletes

Delete multiple records efficiently:

```cfml
// Good: Single delete query
Post::where("created_at < ?", [dateAdd("m", -6, now())])
    .delete();

// Deletes all matching records in one query
// DELETE FROM posts WHERE created_at < ?
```

## Performance Checklist

### Development Phase

- [ ] Eager load relationships in loops
- [ ] Select only required columns
- [ ] Paginate large result sets
- [ ] Use appropriate query methods
- [ ] Avoid N+1 queries

### Database Schema

- [ ] Index all foreign keys
- [ ] Index frequently queried columns
- [ ] Add unique indexes for constraints
- [ ] Use composite indexes for multi-column queries
- [ ] Avoid over-indexing write-heavy tables

### Production Optimization

- [ ] Enable query logging
- [ ] Monitor slow queries
- [ ] Analyze query plans
- [ ] Implement caching (when available)
- [ ] Use batch operations

### Monitoring

- [ ] Track query counts per request
- [ ] Monitor response times
- [ ] Log slow queries (> 1s)
- [ ] Alert on N+1 patterns
- [ ] Profile production queries

## Example: Optimized Dashboard

Complete optimization example:

```cfml
/**
 * Optimized dashboard with multiple performance techniques
 */
// app/handlers/Dashboard.cfc
component {

    public struct function index() {
        // Use caching for expensive aggregations (manual for now)
        var stats = getCachedStats();

        // Paginate user list
        var page = val(url.page) ?: 1;
        var perPage = 20;
        var offset = (page - 1) * perPage;

        // Eager load relationships and select only required columns
        var users = User::select(["id", "name", "email", "created_at"])
            .includes("profile")
            .where({active: true})
            .orderBy("created_at DESC")
            .limit(perPage)
            .offset(offset)
            .get();

        // Load recent activity efficiently
        var recentPosts = Post::select(["id", "title", "user_id", "created_at"])
            .includes("user")
            .where({published: true})
            .orderBy("created_at DESC")
            .limit(10)
            .get();

        return {
            stats: stats,
            users: users,
            recentPosts: recentPosts
        };
    }

    private struct function getCachedStats() {
        // Manual caching using application scope
        var cacheKey = "dashboard_stats";
        var cacheDuration = 600;  // 10 minutes in seconds

        if (!structKeyExists(application, cacheKey) ||
            dateDiff("s", application[cacheKey & "_time"], now()) > cacheDuration) {

            // Compute expensive stats
            var stats = {
                totalUsers: User::count(),
                activeUsers: User::where({active: true}).count(),
                totalPosts: Post::count(),
                publishedPosts: Post::where({published: true}).count()
            };

            application[cacheKey] = stats;
            application[cacheKey & "_time"] = now();
        }

        return application[cacheKey];
    }
}
```

**Optimizations applied:**
- Caching for expensive aggregations
- Pagination for large result sets
- Eager loading to prevent N+1
- Column selection to reduce data transfer
- Indexed columns in WHERE clauses

## Anti-Patterns

### Loading All Records

**Bad:**
```cfml
var users = User::all().get();  // Could be millions

for (var user in users) {
    processUser(user);
}
```

**Good:**
```cfml
// Paginate and process in batches
var page = 1;
var perPage = 100;

do {
    var users = User::all()
        .limit(perPage)
        .offset((page - 1) * perPage)
        .get();

    for (var user in users) {
        processUser(user);
    }

    page++;
} while (arrayLen(users) == perPage);
```

### Ignoring Indexes

**Bad:**
```cfml
// No index on email column
var user = User::where({email: "test@example.com"}).first();
// Full table scan on every login!
```

**Good:**
```cfml
// Migration adds index
table.unique("email");

// Now query uses index
var user = User::where({email: "test@example.com"}).first();
```

### Query in Loop

**Bad:**
```cfml
for (var userId in userIds) {
    var user = User::find(userId);  // N queries
    processUser(user);
}
```

**Good:**
```cfml
var users = User::whereIn("id", userIds).get();  // 1 query

for (var user in users) {
    processUser(user);
}
```

### Selecting Unused Columns

**Bad:**
```cfml
var users = User::all().get();  // SELECT * (all columns)

for (var user in users) {
    writeOutput(user.name);  // Only use name
}
```

**Good:**
```cfml
var users = User::select(["id", "name"]).get();  // SELECT id, name

for (var user in users) {
    writeOutput(user.name);
}
```

## Related Topics

- [Eager Loading](../guides/eager-loading.md) - Comprehensive eager loading guide
- [Models & ORM](../guides/models-orm.md) - Query builder methods
- [Migrations](../guides/migrations.md) - Database schema and indexes
- [Cache Providers](cache-providers.md) - Caching system (coming in v1.1)
