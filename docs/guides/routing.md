# Routing

Fuse provides a Rails-inspired routing DSL for defining RESTful routes with pattern matching, named routes, and automatic URL generation.

## Overview

Routes map HTTP requests to handler actions. Define routes in `/config/routes.cfm` using the `router` object:

```cfml
// config/routes.cfm
router.get("/", "Home.index", {name: "home"});
router.resource("posts");
```

The router matches incoming requests against registered routes in order and dispatches to the appropriate handler action.

## Basic Routes

### HTTP Method Routes

Register routes for each HTTP method:

```cfml
// config/routes.cfm

// GET request
router.get("/about", "Pages.about", {name: "about_page"});

// POST request
router.post("/users", "Users.create", {name: "users_create"});

// PUT request (full update)
router.put("/users/:id", "Users.update", {name: "users_update"});

// PATCH request (partial update)
router.patch("/users/:id", "Users.update");

// DELETE request
router.delete("/users/:id", "Users.destroy", {name: "users_destroy"});
```

Each method accepts:
- **pattern**: URL pattern with optional parameters
- **handler**: Handler and action as "HandlerName.actionName"
- **options**: Optional struct with `name` key for named routes

### Static Routes

Static routes have no parameters:

```cfml
// config/routes.cfm
router.get("/", "Home.index", {name: "home"});
router.get("/about", "Pages.about", {name: "about"});
router.get("/contact", "Pages.contact", {name: "contact"});
router.get("/terms", "Pages.terms", {name: "terms"});
```

Static routes match exact paths only.

## Resource Routes

Generate all RESTful routes for a resource with `router.resource()`:

```cfml
// config/routes.cfm
router.resource("users");
```

This creates 7 standard routes:

| Action    | HTTP Method | Route Pattern        | Handler Action | Route Name      | Purpose           |
|-----------|-------------|----------------------|----------------|-----------------|-------------------|
| index     | GET         | /users               | Users.index    | users_index     | List all users    |
| new       | GET         | /users/new           | Users.new      | users_new       | Show create form  |
| create    | POST        | /users               | Users.create   | users_create    | Create new user   |
| show      | GET         | /users/:id           | Users.show     | users_show      | Show single user  |
| edit      | GET         | /users/:id/edit      | Users.edit     | users_edit      | Show edit form    |
| update    | PUT/PATCH   | /users/:id           | Users.update   | users_update    | Update user       |
| destroy   | DELETE      | /users/:id           | Users.destroy  | users_destroy   | Delete user       |

### Filtering Resource Routes

Limit routes with `only` or `except`:

```cfml
// config/routes.cfm

// Only include specified actions
router.resource("posts", {only: ["index", "show"]});
// Creates: GET /posts, GET /posts/:id

// Exclude specified actions
router.resource("comments", {except: ["new", "edit"]});
// Creates: index, create, show, update, destroy (no form routes)
```

Use `only` for API-only resources (no forms), `except` to skip specific actions.

## Named Parameters

Capture dynamic segments from URLs:

```cfml
// config/routes.cfm
router.get("/users/:id", "Users.show", {name: "users_show"});
router.get("/posts/:post_id/comments/:id", "Comments.show", {name: "post_comments"});
```

Parameters start with `:` and match any non-slash characters. They're passed as arguments to handler actions:

```cfml
// app/handlers/Users.cfc
component {
    // GET /users/123
    public struct function show(required string id) {
        // arguments.id = "123"
        return {user: findUser(arguments.id)};
    }
}
```

### Multiple Parameters

Routes can have multiple parameters:

```cfml
// config/routes.cfm
router.get("/posts/:post_id/comments/:id", "Comments.show");
router.get("/users/:user_id/posts/:id/edit", "UserPosts.edit");
```

```cfml
// app/handlers/Comments.cfc
component {
    // GET /posts/5/comments/42
    public struct function show(
        required string post_id,
        required string id
    ) {
        // arguments.post_id = "5"
        // arguments.id = "42"
        return {
            post: findPost(arguments.post_id),
            comment: findComment(arguments.id)
        };
    }
}
```

### Parameter Naming

Use descriptive parameter names that indicate the resource:

```cfml
// Good - clear resource relationship
router.get("/posts/:post_id/comments/:id", "Comments.show");
router.get("/users/:user_id/settings/:setting_key", "UserSettings.show");

// Avoid - ambiguous parameters
router.get("/posts/:id/comments/:id2", "Comments.show");
```

## Wildcards and Constraints

### Wildcard Parameters

Capture multiple path segments with `*`:

```cfml
// config/routes.cfm
router.get("/files/*path", "Files.serve", {name: "files"});
```

Matches any number of segments:
- `/files/images/logo.png` → `path = "images/logo.png"`
- `/files/docs/2023/report.pdf` → `path = "docs/2023/report.pdf"`

```cfml
// app/handlers/Files.cfc
component {
    public function serve(required string path) {
        // arguments.path contains full remaining path
        var filePath = expandPath("/public/files/#arguments.path#");
        // Serve file...
    }
}
```

### Pattern Order Matters

Routes match in registration order. Place specific routes before generic ones:

```cfml
// config/routes.cfm

// Correct - specific before generic
router.get("/users/new", "Users.new");
router.get("/users/:id", "Users.show");

// Incorrect - generic route catches "new" as :id
// router.get("/users/:id", "Users.show");  // Would match /users/new
// router.get("/users/new", "Users.new");   // Never reached
```

Resource routes handle this automatically by registering static routes before parameterized routes.

## Named Routes

Assign names to routes for URL generation:

```cfml
// config/routes.cfm
router.get("/", "Home.index", {name: "home"});
router.get("/about", "Pages.about", {name: "about_page"});
router.get("/users/:id", "Users.show", {name: "users_show"});
router.resource("posts"); // Auto-names: posts_index, posts_show, etc.
```

Names should be unique and descriptive. Resource routes automatically generate names following the pattern `{resource}_{action}`.

### Name Conflicts

If you register duplicate names, the last one wins:

```cfml
// Avoid this
router.get("/users", "Users.index", {name: "users"});
router.get("/admin/users", "Admin.users", {name: "users"}); // Overwrites!
```

Use namespace prefixes to avoid conflicts:

```cfml
// Better
router.get("/users", "Users.index", {name: "users_index"});
router.get("/admin/users", "Admin.users", {name: "admin_users"});
```

## URL Generation (urlFor)

Generate URLs from named routes using the `urlFor` helper:

### In Handlers

Access via `this.urlFor()`:

```cfml
// app/handlers/Users.cfc
component {
    public struct function show(required string id) {
        return {
            user: findUser(arguments.id),
            editUrl: this.urlFor("users_edit", {id: arguments.id}),
            indexUrl: this.urlFor("users_index")
        };
    }
}
```

### Route Parameters

Pass parameters as a struct to replace placeholders:

```cfml
// Static route (no params)
this.urlFor("home")
// Returns: "/"

// Route with single parameter
this.urlFor("users_show", {id: 123})
// Returns: "/users/123"

// Route with multiple parameters
this.urlFor("post_comments", {post_id: 5, id: 42})
// Returns: "/posts/5/comments/42"
```

### Missing Parameters

If you forget a required parameter, an error is thrown:

```cfml
// Route: /users/:id
this.urlFor("users_show")
// Throws: RouteParameterMissing - Required parameter 'id' not provided
```

### Building Links

Common pattern for navigation:

```cfml
// app/handlers/Posts.cfc
component {
    public struct function index() {
        var posts = Post::all().get();

        return {
            posts: posts.map(function(post) {
                return {
                    id: post.id,
                    title: post.title,
                    url: this.urlFor("posts_show", {id: post.id}),
                    editUrl: this.urlFor("posts_edit", {id: post.id})
                };
            })
        };
    }
}
```

## Listing Routes

View all registered routes with the `lucli routes` command:

```bash
lucli routes
```

Output displays an ASCII table:

```
+--------+------------------+------------------+------------------+
| Method | URI              | Name             | Handler          |
+--------+------------------+------------------+------------------+
| GET    | /                | home             | Home.index       |
| GET    | /about           | about_page       | Pages.about      |
| GET    | /users           | users_index      | Users.index      |
| POST   | /users           | users_create     | Users.create     |
| GET    | /users/new       | users_new        | Users.new        |
| GET    | /users/:id       | users_show       | Users.show       |
| GET    | /users/:id/edit  | users_edit       | Users.edit       |
| PUT    | /users/:id       | users_update     | Users.update     |
| PATCH  | /users/:id       |                  | Users.update     |
| DELETE | /users/:id       | users_destroy    | Users.destroy    |
+--------+------------------+------------------+------------------+
```

### Filtering Routes

Filter by method, name, or handler:

```bash
# Show only GET routes
lucli routes --method=GET

# Filter by route name (contains match)
lucli routes --name=users

# Filter by handler (contains match)
lucli routes --handler=Posts
```

Use this to debug route conflicts and verify route registration.

## Common Patterns

### Nested Resources

Create nested routes for hierarchical resources:

```cfml
// config/routes.cfm
router.get("/posts/:post_id/comments", "Comments.index", {name: "post_comments_index"});
router.post("/posts/:post_id/comments", "Comments.create", {name: "post_comments_create"});
router.get("/posts/:post_id/comments/:id", "Comments.show", {name: "post_comments_show"});
router.delete("/posts/:post_id/comments/:id", "Comments.destroy", {name: "post_comments_destroy"});
```

```cfml
// app/handlers/Comments.cfc
component {
    public struct function index(required string post_id) {
        var post = Post::find(arguments.post_id);
        var comments = post.comments().get();
        return {comments: comments};
    }

    public struct function create(required string post_id) {
        var post = Post::find(arguments.post_id);
        var comment = post.comments().create(form);
        return {
            created: true,
            comment: comment,
            location: this.urlFor("post_comments_show", {
                post_id: arguments.post_id,
                id: comment.id
            })
        };
    }
}
```

### API Versioning

Namespace routes by API version:

```cfml
// config/routes.cfm
// v1 API
router.get("/api/v1/users", "Api.V1.Users.index", {name: "api_v1_users_index"});
router.get("/api/v1/users/:id", "Api.V1.Users.show", {name: "api_v1_users_show"});

// v2 API (different structure)
router.get("/api/v2/users", "Api.V2.Users.index", {name: "api_v2_users_index"});
```

### Custom Actions

Add custom actions beyond RESTful defaults:

```cfml
// config/routes.cfm
router.resource("posts");
router.post("/posts/:id/publish", "Posts.publish", {name: "posts_publish"});
router.post("/posts/:id/unpublish", "Posts.unpublish", {name: "posts_unpublish"});
router.get("/posts/:id/preview", "Posts.preview", {name: "posts_preview"});
```

Keep custom actions focused and RESTful where possible. Consider if the action should be a new resource instead (e.g., `/posts/:id/publication` instead of `/posts/:id/publish`).

### Root Route

Always define a root route for your application:

```cfml
// config/routes.cfm
router.get("/", "Home.index", {name: "home"});
```

## Anti-Patterns

### Hardcoded URLs

**Bad:**
```cfml
// app/handlers/Users.cfc
public struct function show(required string id) {
    return {
        user: findUser(arguments.id),
        editUrl: "/users/#arguments.id#/edit",  // Hardcoded
        indexUrl: "/users"                       // Hardcoded
    };
}
```

**Good:**
```cfml
public struct function show(required string id) {
    return {
        user: findUser(arguments.id),
        editUrl: this.urlFor("users_edit", {id: arguments.id}),
        indexUrl: this.urlFor("users_index")
    };
}
```

Hardcoded URLs break when routes change. Always use `urlFor` with named routes.

### Missing Route Names

**Bad:**
```cfml
// config/routes.cfm
router.get("/users/:id", "Users.show");  // No name
```

**Good:**
```cfml
router.get("/users/:id", "Users.show", {name: "users_show"});
```

Named routes enable `urlFor` and make code more maintainable.

### Order-Dependent Routes

**Bad:**
```cfml
// config/routes.cfm
router.get("/users/:action", "Users.custom"); // Too generic
router.get("/users/new", "Users.new");        // Never matches
```

**Good:**
```cfml
router.get("/users/new", "Users.new");        // Specific first
router.get("/users/:id", "Users.show");       // Generic after
```

Or use resource routes which handle ordering automatically:
```cfml
router.resource("users");  // Handles ordering correctly
```

### Inconsistent Naming

**Bad:**
```cfml
router.get("/users", "Users.index", {name: "list_users"});
router.get("/posts", "Posts.index", {name: "posts_index"});
router.get("/comments", "Comments.index", {name: "all_comments"});
```

**Good:**
```cfml
router.resource("users");     // users_index
router.resource("posts");     // posts_index
router.resource("comments");  // comments_index
```

Use consistent naming patterns. Resource routes provide this automatically.

### Non-RESTful Routes

**Bad:**
```cfml
router.get("/users/create", "Users.create");      // Should be POST
router.get("/users/:id/delete", "Users.destroy"); // Should be DELETE
router.post("/users/update", "Users.update");     // Should be PUT/PATCH with :id
```

**Good:**
```cfml
router.resource("users");  // Generates correct RESTful routes
// Or explicitly:
router.post("/users", "Users.create");
router.put("/users/:id", "Users.update");
router.delete("/users/:id", "Users.destroy");
```

Follow HTTP semantics: GET for reads, POST for creates, PUT/PATCH for updates, DELETE for deletes.

## Common Errors

### RouteNotFoundException

**Error:** 404 error when accessing URL.

**Cause:** No route matches the requested URL or HTTP method.

```cfml
// Route defined as GET
router.get("/users", "Users.index");

// But accessed as POST
// POST /users -> RouteNotFoundException
```

**Solution:** Ensure route exists for correct HTTP method:

```cfml
// Define routes for all needed methods
router.get("/users", "Users.index");
router.post("/users", "Users.create");
```

Use `lucli routes` command to see all registered routes.

See [Error Reference](../../fuse-planning/error-reference.md#routenotfoundexception).

### Handler Action Not Found

**Error:** Handler exists but action method doesn't.

**Cause:** Route references non-existent handler method.

```cfml
// Route defined
router.get("/profile", "Users.profile");

// But Users.cfc missing profile() method
// Error: Method 'profile' not found on Users handler
```

**Solution:** Implement handler action:

```cfml
// app/handlers/Users.cfc
public function profile() {
    return {message: "Profile page"};
}
```

### Named Route Not Found

**Error:** `urlFor()` throws error for non-existent route name.

**Cause:** Route name misspelled or route not named.

```cfml
var url = urlFor("user_profile");
// Error: Named route 'user_profile' not found
```

**Solution:** Verify route name or add name to route:

```cfml
// Add name to route
router.get("/profile", "Users.profile", {name: "user_profile"});

// Now works
var url = urlFor("user_profile");
```

### Parameter Binding Issues

**Error:** Route params not passed to handler action.

**Cause:** Parameter name mismatch between route and handler.

```cfml
// Route uses :userId
router.get("/users/:userId", "Users.show");

// But handler expects 'id'
public function show(required string id) {  // Wrong parameter name
    // arguments.id is empty!
}
```

**Solution:** Match parameter names:

```cfml
// Option 1: Match route param name
public function show(required string userId) {
    // arguments.userId populated correctly
}

// Option 2: Use standard :id in route
router.get("/users/:id", "Users.show");
public function show(required string id) {
    // arguments.id populated
}
```

### Route Order Conflicts

**Error:** More specific routes never match because generic route matches first.

**Cause:** Routes evaluated in definition order - generic route defined before specific.

```cfml
// BAD ORDER:
router.get("/users/*path", "Users.wildcard");  // Catches everything
router.get("/users/new", "Users.new");         // Never reached!
```

**Solution:** Define specific routes before generic ones:

```cfml
// CORRECT ORDER:
router.get("/users/new", "Users.new");         // Check specific first
router.get("/users/*path", "Users.wildcard");  // Then catch-all
```

## API Reference

For detailed routing method signatures:

- [Router Methods](../reference/api-reference.md#router) - get(), post(), put(), delete(), resource()
- [Route Registration](../reference/api-reference.md#route-registration) - Pattern matching, middleware
- [CLI Routes Command](../reference/cli-reference.md#routes) - View all registered routes

## Related Topics

- [Handlers](../handlers.md) - Handle requests and execute business logic
- [Models & ORM](models-orm.md) - Query data in route handlers
- [CLI Reference](../reference/cli-reference.md) - `lucli routes` command details
