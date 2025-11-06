# Handler Conventions

Handlers are the controllers in Fuse's MVC architecture. They receive requests from the router, process business logic, and return responses.

## Handler Location

Handlers are located in `/app/handlers/` directory:

```
/app/handlers/
  Users.cfc
  Pages.cfc
  Admin.cfc
```

## Handler Structure

Handlers are CFCs with public action methods:

```cfml
component {

    public function init() {
        return this;
    }

    // Action methods receive route params as arguments
    public struct function index() {
        return {users: []};
    }

    public struct function show(required string id) {
        return {user: {id: arguments.id}};
    }

}
```

## Handler Lifecycle

### Transient Instantiation

Handlers are **transient** - a fresh instance is created for each request. This ensures:
- Clean state per request
- No memory leaks from accumulated state
- Thread-safe request handling

```cfml
// Each request creates new handler instance
container.bind("Users", function(c) {
    return new app.handlers.Users();
});
```

### Constructor Dependency Injection

Handlers support constructor-based dependency injection via the DI Container:

```cfml
component {

    public function init(required logger, required userService) {
        variables.logger = arguments.logger;
        variables.userService = arguments.userService;
        return this;
    }

    public struct function index() {
        variables.logger.info("Listing users");
        var users = variables.userService.getAll();
        return {users: users};
    }

}
```

Dependencies are automatically resolved by the Container during handler instantiation.

## Action Methods

### Naming Convention

Action method names match the route action definitions:

```cfml
// Route definition
router.get("/users/:id", "Users.show");

// Handler action
public struct function show(required string id) {
    return {user: findUser(arguments.id)};
}
```

### Route Parameters

Route parameters are passed as named arguments to action methods:

```cfml
// Route: GET /posts/:post_id/comments/:id
router.get("/posts/:post_id/comments/:id", "Comments.show");

// Handler receives both params
public struct function show(
    required string post_id,
    required string id
) {
    return {
        post: findPost(arguments.post_id),
        comment: findComment(arguments.id)
    };
}
```

### RESTful Actions

Standard RESTful resource actions:

| Action    | HTTP Method | Route Pattern       | Purpose                  |
|-----------|-------------|---------------------|--------------------------|
| `index`   | GET         | `/resources`        | List all resources       |
| `new`     | GET         | `/resources/new`    | Show create form         |
| `create`  | POST        | `/resources`        | Create new resource      |
| `show`    | GET         | `/resources/:id`    | Show single resource     |
| `edit`    | GET         | `/resources/:id/edit` | Show edit form         |
| `update`  | PUT/PATCH   | `/resources/:id`    | Update resource          |
| `destroy` | DELETE      | `/resources/:id`    | Delete resource          |

Example handler with all CRUD actions:

```cfml
component {

    public struct function index() {
        return {users: getAllUsers()};
    }

    public string function new() {
        return "users/new"; // View name
    }

    public struct function create() {
        var user = createUser(form);
        return {created: true, user: user};
    }

    public struct function show(required string id) {
        return {user: findUser(arguments.id)};
    }

    public string function edit(required string id) {
        return "users/edit"; // View name
    }

    public struct function update(required string id) {
        var user = updateUser(arguments.id, form);
        return {updated: true, user: user};
    }

    public struct function destroy(required string id) {
        deleteUser(arguments.id);
        return {deleted: true};
    }

}
```

## Return Value Handling

Handlers can return different types based on the response needed:

### Struct Return (JSON Response)

Return a struct for JSON API responses:

```cfml
public struct function index() {
    return {
        success: true,
        users: getAllUsers()
    };
}
```

### String Return (View Name)

Return a string to render a specific view:

```cfml
public string function new() {
    return "users/new"; // Renders /views/users/new.cfm
}
```

### Void Return (Default View)

Return nothing to render the default view based on handler and action:

```cfml
public void function about() {
    // Renders /views/pages/about.cfm
}
```

## Helper Access

Handlers have access to framework helpers and utilities:

### URL Generation (urlFor)

The `urlFor` helper generates URLs from named routes:

```cfml
public struct function show(required string id) {
    var editUrl = this.urlFor("users_edit", {id: arguments.id});
    var indexUrl = this.urlFor("users_index");

    return {
        user: findUser(arguments.id),
        editUrl: editUrl,
        indexUrl: indexUrl
    };
}
```

Helper injection is handled via interceptors during the request lifecycle.

### Request Scope

Handlers have access to the standard CFML request scope containing:
- `request.urlFor()` - URL generation helper
- `request.params` - Route parameters
- `request.event` - Event context struct

### Form and URL Data

Standard CFML scopes are available:
- `form` - POST form data
- `url` - GET query parameters
- `cgi` - CGI variables

## Handler Registration

Handlers must be registered in the DI Container as transient bindings:

```cfml
// In Bootstrap or module registration
container.bind("Users", function(c) {
    return new app.handlers.Users(
        c.resolve("logger"),
        c.resolve("userService")
    );
});
```

Or use auto-binding conventions (future roadmap feature):

```cfml
// Auto-register all handlers from /app/handlers/
container.autoBindHandlers("/app/handlers/");
```

## Error Handling

### Missing Handler

If a handler is not registered in the Container:

```
Dispatcher.HandlerNotFound: Handler 'Users' not found
Handler 'Users' is not registered in the container.
Check that the handler exists at /app/handlers/Users.cfc
and is registered in the container.
```

### Missing Action

If an action method doesn't exist on the handler:

```
Dispatcher.ActionNotFound: Action 'show' not found on handler 'Users'
Available actions on 'Users': index, create, update, destroy
```

### Action Invocation Error

If an action throws an error:

```
Dispatcher.ActionInvocationError: Error invoking action 'Users.show'
Error: [original error message]
```

## Best Practices

1. **Keep handlers thin** - Move business logic to service layer
2. **Use constructor injection** - Inject all dependencies via constructor
3. **Return consistent types** - Document expected return types
4. **Validate params** - Check and validate route parameters
5. **Handle errors gracefully** - Use try/catch and return error structs
6. **Use urlFor** - Never hardcode URLs, use named routes
7. **Document actions** - Add clear docblocks to action methods

## Example: Complete Handler

```cfml
/**
 * Users Handler
 * Manages user CRUD operations
 */
component {

    /**
     * Constructor with dependencies
     *
     * @logger Logging service
     * @userService User business logic service
     */
    public function init(
        required logger,
        required userService
    ) {
        variables.logger = arguments.logger;
        variables.userService = arguments.userService;
        return this;
    }

    /**
     * List all users
     * GET /users
     */
    public struct function index() {
        variables.logger.info("Listing users");

        var users = variables.userService.getAll();

        return {
            success: true,
            users: users,
            count: arrayLen(users)
        };
    }

    /**
     * Show single user
     * GET /users/:id
     */
    public struct function show(required string id) {
        variables.logger.info("Showing user: #arguments.id#");

        try {
            var user = variables.userService.find(arguments.id);

            return {
                success: true,
                user: user,
                editUrl: this.urlFor("users_edit", {id: arguments.id})
            };
        } catch (UserNotFoundException e) {
            return {
                success: false,
                error: "User not found",
                status: 404
            };
        }
    }

    /**
     * Create new user
     * POST /users
     */
    public struct function create() {
        variables.logger.info("Creating user");

        try {
            var user = variables.userService.create(form);

            return {
                success: true,
                created: true,
                user: user,
                location: this.urlFor("users_show", {id: user.id})
            };
        } catch (ValidationException e) {
            return {
                success: false,
                errors: e.getErrors(),
                status: 422
            };
        }
    }

}
```
