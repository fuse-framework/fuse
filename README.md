# Fuse Framework

Modern CFML framework for Lucee 7 with Rails-inspired routing, DI container, and modular architecture.

## Features

### Bootstrap Core & DI Container
- Lightweight dependency injection container with auto-wiring
- Singleton and transient bindings
- Constructor and property injection
- Thread-safe initialization
- Modular architecture with two-phase initialization (register/boot)

### Routing & Event System
- Rails-inspired routing DSL
- RESTful resource routes with full CRUD support
- Named routes and URL generation
- Pattern matching (static, named params, wildcards)
- Event service with interceptor lifecycle hooks
- Request dispatcher with handler conventions

## Quick Start

### Routing Examples

#### Define Routes in `/config/routes.cfm`

```cfml
// Static route
router.get("/", "Home.index", {name: "home"});

// Named route
router.get("/about", "Pages.about", {name: "about_page"});

// RESTful resource routes (generates 7 standard routes)
router.resource("users");
// Creates: index, new, create, show, edit, update, destroy

// Resource routes with filtering
router.resource("posts", {only: ["index", "show"]});
router.resource("comments", {except: ["new", "edit"]});

// Named parameters
router.get("/users/:id", "Users.show", {name: "users_show"});
router.get("/posts/:post_id/comments/:id", "Comments.show", {name: "post_comments"});

// Wildcard parameters
router.get("/files/*path", "Files.serve", {name: "files"});
```

#### Create Handler at `/app/handlers/Users.cfc`

```cfml
component {

    // Constructor injection (optional)
    public function init(any logger) {
        if (structKeyExists(arguments, "logger")) {
            variables.logger = arguments.logger;
        }
        return this;
    }

    // GET /users
    public struct function index() {
        return {
            users: getUserList()
        };
    }

    // GET /users/:id
    public struct function show(required string id) {
        return {
            user: getUserById(arguments.id)
        };
    }

    // POST /users
    public struct function create() {
        var newUser = createUser(form);
        return {
            created: true,
            user: newUser
        };
    }

    // PUT/PATCH /users/:id
    public struct function update(required string id) {
        updateUser(arguments.id, form);
        return {
            updated: true
        };
    }

    // DELETE /users/:id
    public struct function destroy(required string id) {
        deleteUser(arguments.id);
        return {
            deleted: true
        };
    }

}
```

#### URL Generation in Handlers

```cfml
// Use urlFor helper (injected via interceptor or request scope)
public struct function dashboard() {
    return {
        links: {
            home: urlFor("home"),
            users: urlFor("users_index"),
            user_detail: urlFor("users_show", {id: 5}),
            about: urlFor("about_page")
        }
    };
}
```

### Event Interceptors

Register interceptors during module initialization to hook into request lifecycle:

```cfml
component implements="IModule" {

    public function register(required container) {
        // Get event service from container
        var eventService = arguments.container.resolve("eventService");

        // Register authentication interceptor
        eventService.registerInterceptor("onBeforeRequest", function(event) {
            // Check authentication
            event.authenticated = checkAuth(event.request);
            if (!event.authenticated) {
                event.abort = true; // Short-circuit request
            }
        });

        // Register logging interceptor
        eventService.registerInterceptor("onAfterHandler", function(event) {
            // Log request details
            logRequest(event.route, event.handler, event.result);
        });
    }

    public function boot(required container) {
        // Boot logic here
    }

}
```

### Interceptor Points

Six lifecycle points available:
- `onBeforeRequest` - Before routing
- `onAfterRouting` - After route matched
- `onBeforeHandler` - Before handler action
- `onAfterHandler` - After handler action
- `onBeforeRender` - Before view rendering (future)
- `onAfterRender` - After view rendering (future)

### Complete Request Lifecycle

```
1. Request received
2. onBeforeRequest interceptors
3. Route matching
4. onAfterRouting interceptors
5. Handler instantiation (transient, auto-wired)
6. onBeforeHandler interceptors
7. Handler action execution
8. onAfterHandler interceptors
9. Response rendering
```

## Handler Conventions

- Location: `/app/handlers/{HandlerName}.cfc`
- Scope: Transient (new instance per request)
- Injection: Constructor auto-wiring via DI container
- Actions: Public methods matching route actions
- Parameters: Route params passed as method arguments
- Return values:
  - Struct for JSON responses
  - String for view names
  - Void for default view rendering

## Development

### Running Tests

```bash
box testbox run
```

### Project Structure

```
fuse/
├── fuse/core/          # Framework core components
│   ├── Bootstrap.cfc   # Framework initialization
│   ├── Container.cfc   # DI container
│   ├── Router.cfc      # Routing DSL
│   ├── RoutePattern.cfc# Pattern matching engine
│   ├── Dispatcher.cfc  # Request dispatcher
│   ├── EventService.cfc# Event/interceptor service
│   ├── Config.cfc      # Configuration loader
│   └── ...
├── config/             # Application configuration
│   └── routes.cfm      # Route definitions
├── app/
│   └── handlers/       # Request handlers
├── tests/              # Test suites
│   ├── core/          # Core component tests
│   └── fixtures/      # Test fixtures
└── README.md
```

## Roadmap

- [x] #1: Bootstrap Core & DI Container
- [x] #2: Routing & Event System
- [ ] #3: View Layer & Rendering
- [ ] #4: Middleware Chain
- [ ] #5: Database Layer & ORM
- [ ] #6: Session & Authentication
- [ ] #7: Form Validation
- [ ] #8: CLI & Tooling

## License

TBD
