# Modules

Extend and organize Fuse applications with modular architecture using the module system for reusable, self-contained functionality with dependency management and lifecycle hooks.

## Overview

Modules encapsulate related functionality:

```cfml
// app/modules/BlogModule.cfc
component implements="fuse.core.IModule" {

    public void function register(required container) {
        // Register services in DI container
        arguments.container.singleton("BlogService", function(c) {
            return new app.services.BlogService(c.resolve("datasource"));
        });
    }

    public void function boot(required container) {
        // Configure after all bindings registered
        var eventService = arguments.container.resolve("eventService");
        var blogService = arguments.container.resolve("BlogService");

        // Register event listeners
        eventService.registerInterceptor("onPostPublished", function(event) {
            blogService.notifySubscribers(event.post);
        });
    }

    public array function getDependencies() {
        // Module depends on these modules being loaded first
        return [];
    }

    public struct function getConfig() {
        // Default configuration values
        return {
            blog: {
                postsPerPage: 10,
                allowComments: true
            }
        };
    }
}
```

Modules provide clean separation of concerns and enable plugin architecture.

## Module System Overview

### Module Architecture

Fuse modules implement `IModule` interface:

- **register()** - Register services in DI container
- **boot()** - Initialize after all services registered
- **getDependencies()** - Declare module dependencies
- **getConfig()** - Provide default configuration

### Module Loading

Modules load at application startup:

```cfml
// config/application.cfc
component {
    this.name = "MyApp";

    public void function onApplicationStart() {
        // Bootstrap Fuse framework
        var container = new fuse.core.Container();

        // Load modules
        container.loadModules([
            new app.modules.DatabaseModule(),
            new app.modules.AuthModule(),
            new app.modules.BlogModule()
        ]);

        // Store container
        application.container = container;
    }
}
```

### Module Lifecycle

1. **Registration phase**: All `register()` methods called
2. **Dependency resolution**: Container bindings completed
3. **Boot phase**: All `boot()` methods called in dependency order
4. **Ready**: Application ready to handle requests

## IModule Interface

### Interface Definition

```cfml
// fuse/core/IModule.cfc
interface {

    /**
     * Register services in the DI container
     * No dependency resolution allowed in this phase
     */
    public void function register(required container);

    /**
     * Boot the module and resolve dependencies
     * All bindings are available in this phase
     */
    public void function boot(required container);

    /**
     * Get module dependencies
     * @return Array of module name strings
     */
    public array function getDependencies();

    /**
     * Get module configuration
     * @return Struct of configuration values
     */
    public struct function getConfig();
}
```

### Implementing IModule

Basic module structure:

```cfml
// app/modules/ExampleModule.cfc
component implements="fuse.core.IModule" {

    public void function register(required container) {
        // Register bindings
    }

    public void function boot(required container) {
        // Boot module
    }

    public array function getDependencies() {
        return [];
    }

    public struct function getConfig() {
        return {};
    }
}
```

## Module Lifecycle

### register() Phase

Register services without resolving dependencies:

```cfml
// app/modules/MailModule.cfc
component implements="fuse.core.IModule" {

    public void function register(required container) {
        // Bind MailService as singleton
        arguments.container.singleton("MailService", function(c) {
            var config = c.resolve("config");
            return new app.services.MailService(
                config.mail.host,
                config.mail.port,
                config.mail.username,
                config.mail.password
            );
        });

        // Bind MailQueue as transient
        arguments.container.bind("MailQueue", function(c) {
            return new app.services.MailQueue(
                c.resolve("datasource")
            );
        });
    }

    public void function boot(required container) {
        // Boot logic here
    }

    public array function getDependencies() {
        return [];
    }

    public struct function getConfig() {
        return {
            mail: {
                host: "localhost",
                port: 25,
                username: "",
                password: ""
            }
        };
    }
}
```

**Rules for register():**
- Only register bindings
- Don't resolve dependencies
- Don't perform initialization logic
- Keep lightweight

### boot() Phase

Initialize module with resolved dependencies:

```cfml
// app/modules/AdminModule.cfc
component implements="fuse.core.IModule" {

    public void function register(required container) {
        arguments.container.singleton("AdminService", function(c) {
            return new app.services.AdminService();
        });
    }

    public void function boot(required container) {
        // Resolve dependencies (all modules registered)
        var router = arguments.container.resolve("router");
        var adminService = arguments.container.resolve("AdminService");
        var eventService = arguments.container.resolve("eventService");

        // Register admin routes
        registerAdminRoutes(router);

        // Register interceptors
        eventService.registerInterceptor("onBeforeAction", function(event) {
            // Check admin authentication
            if (event.handler == "Admin" && !adminService.isAuthenticated()) {
                event.redirect("/login");
            }
        });
    }

    private void function registerAdminRoutes(required router) {
        arguments.router.group({prefix: "/admin"}, function(route) {
            route.get("/dashboard", "Admin.index");
            route.resource("users", "Admin.Users");
            route.resource("settings", "Admin.Settings");
        });
    }

    public array function getDependencies() {
        return [];
    }

    public struct function getConfig() {
        return {};
    }
}
```

**Purpose of boot():**
- Resolve dependencies from container
- Configure services
- Register event listeners
- Register routes
- Initialize module state

## Module Directory Structure

### Standard Layout

```
app/modules/
├── BlogModule.cfc          # Main module component
├── controllers/            # Module-specific handlers
│   ├── PostsController.cfc
│   └── CommentsController.cfc
├── models/                 # Module-specific models
│   ├── Post.cfc
│   └── Comment.cfc
├── services/              # Module business logic
│   └── BlogService.cfc
└── views/                 # Module templates (future)
    ├── posts/
    └── comments/
```

### Example Module Structure

```cfml
// app/modules/BlogModule.cfc
component implements="fuse.core.IModule" {

    public void function register(required container) {
        // Register blog-specific services
        arguments.container.singleton("BlogService", function(c) {
            return new app.modules.blog.services.BlogService(
                c.resolve("datasource")
            );
        });
    }

    public void function boot(required container) {
        var router = arguments.container.resolve("router");

        // Register blog routes
        router.group({prefix: "/blog"}, function(route) {
            route.get("/", "Blog.Posts.index");
            route.get("/posts/:id", "Blog.Posts.show");
            route.post("/posts/:id/comments", "Blog.Comments.create");
        });
    }

    public array function getDependencies() {
        return [];
    }

    public struct function getConfig() {
        return {
            blog: {
                postsPerPage: 10,
                enableComments: true
            }
        };
    }
}
```

```cfml
// app/modules/blog/controllers/PostsController.cfc
component {

    public function init(required BlogService blogService) {
        variables.blogService = arguments.blogService;
        return this;
    }

    public struct function index() {
        var posts = variables.blogService.getPublishedPosts();
        return {posts: posts};
    }

    public struct function show() {
        var post = variables.blogService.getPost(params.id);
        return {post: post};
    }
}
```

## Loading Modules

### Application Bootstrap

Load modules at startup:

```cfml
// config/bootstrap.cfc
component {

    public any function bootstrap() {
        var container = new fuse.core.Container();

        // Load core modules
        loadCoreModules(container);

        // Load application modules
        loadAppModules(container);

        return container;
    }

    private void function loadCoreModules(required container) {
        arguments.container.loadModules([
            new fuse.modules.RoutingModule(),
            new fuse.modules.EventModule()
        ]);
    }

    private void function loadAppModules(required container) {
        arguments.container.loadModules([
            new app.modules.DatabaseModule(),
            new app.modules.AuthModule(),
            new app.modules.BlogModule(),
            new app.modules.ApiModule()
        ]);
    }
}
```

### Module Registration

Register modules with container:

```cfml
// Manual module loading
var container = new fuse.core.Container();

// Single module
container.loadModule(new app.modules.BlogModule());

// Multiple modules
container.loadModules([
    new app.modules.ModuleA(),
    new app.modules.ModuleB()
]);
```

### Conditional Loading

Load modules based on environment:

```cfml
private void function loadAppModules(required container) {
    var modules = [
        new app.modules.CoreModule()
    ];

    // Load debug module in development
    if (isDevEnvironment()) {
        arrayAppend(modules, new app.modules.DebugModule());
    }

    // Load monitoring in production
    if (isProdEnvironment()) {
        arrayAppend(modules, new app.modules.MonitoringModule());
    }

    arguments.container.loadModules(modules);
}
```

## Module Dependencies

### Declaring Dependencies

Specify required modules:

```cfml
// app/modules/BlogModule.cfc
component implements="fuse.core.IModule" {

    public array function getDependencies() {
        // BlogModule requires DatabaseModule and AuthModule
        return ["DatabaseModule", "AuthModule"];
    }

    // ... other methods
}
```

### Dependency Resolution

Container loads modules in dependency order:

```cfml
// Module load order determined by dependencies:
// 1. DatabaseModule (no dependencies)
// 2. AuthModule (no dependencies)
// 3. BlogModule (depends on Database and Auth)
// 4. AdminModule (depends on Auth)

var container = new fuse.core.Container();
container.loadModules([
    new app.modules.BlogModule(),      // Depends on Database, Auth
    new app.modules.AdminModule(),     // Depends on Auth
    new app.modules.AuthModule(),      // No dependencies
    new app.modules.DatabaseModule()   // No dependencies
]);

// Container sorts by dependencies before loading
```

### Circular Dependencies

Avoid circular dependencies:

```cfml
// Bad: Circular dependency
// ModuleA depends on ModuleB
// ModuleB depends on ModuleA
// Results in error

// Good: Extract shared dependency
// ModuleA depends on SharedModule
// ModuleB depends on SharedModule
// SharedModule has no dependencies
```

## Creating Custom Modules

### Step-by-Step Module Creation

**1. Create module component:**

```cfml
// app/modules/NotificationModule.cfc
component implements="fuse.core.IModule" {

    public void function register(required container) {
        // Register notification service
        arguments.container.singleton("NotificationService", function(c) {
            return new app.services.NotificationService(
                c.resolve("MailService"),
                c.resolve("datasource")
            );
        });
    }

    public void function boot(required container) {
        var eventService = arguments.container.resolve("eventService");
        var notificationService = arguments.container.resolve("NotificationService");

        // Listen for user registration
        eventService.registerInterceptor("onUserRegistered", function(event) {
            notificationService.sendWelcomeEmail(event.user);
        });

        // Listen for post comments
        eventService.registerInterceptor("onCommentCreated", function(event) {
            notificationService.notifyPostAuthor(event.comment);
        });
    }

    public array function getDependencies() {
        return ["MailModule"];
    }

    public struct function getConfig() {
        return {
            notifications: {
                enabled: true,
                emailFrom: "noreply@example.com"
            }
        };
    }
}
```

**2. Create service:**

```cfml
// app/services/NotificationService.cfc
component {

    public function init(required MailService mailService, required string datasource) {
        variables.mailService = arguments.mailService;
        variables.datasource = arguments.datasource;
        return this;
    }

    public void function sendWelcomeEmail(required user) {
        variables.mailService.send(
            to: arguments.user.email,
            subject: "Welcome!",
            body: "Welcome to our application, #arguments.user.name#!"
        );
    }

    public void function notifyPostAuthor(required comment) {
        var post = Post::find(arguments.comment.post_id);
        var author = User::find(post.user_id);

        variables.mailService.send(
            to: author.email,
            subject: "New comment on your post",
            body: "Someone commented on #post.title#"
        );
    }
}
```

**3. Load module:**

```cfml
// config/bootstrap.cfc
container.loadModules([
    new app.modules.MailModule(),
    new app.modules.NotificationModule()  // Add new module
]);
```

## Example: Authentication Module

Complete authentication module:

```cfml
/**
 * Authentication Module
 * Provides user authentication services
 */
// app/modules/AuthModule.cfc
component implements="fuse.core.IModule" {

    public void function register(required container) {
        // Register AuthService
        arguments.container.singleton("AuthService", function(c) {
            return new app.services.AuthService(
                c.resolve("datasource"),
                c.resolve("config")
            );
        });

        // Register SessionService
        arguments.container.singleton("SessionService", function(c) {
            return new app.services.SessionService();
        });
    }

    public void function boot(required container) {
        var router = arguments.container.resolve("router");
        var eventService = arguments.container.resolve("eventService");
        var authService = arguments.container.resolve("AuthService");

        // Register auth routes
        registerAuthRoutes(router);

        // Register auth interceptor
        registerAuthInterceptor(eventService, authService);
    }

    private void function registerAuthRoutes(required router) {
        arguments.router.get("/login", "Auth.login");
        arguments.router.post("/login", "Auth.authenticate");
        arguments.router.post("/logout", "Auth.logout");
        arguments.router.get("/register", "Auth.register");
        arguments.router.post("/register", "Auth.create");
    }

    private void function registerAuthInterceptor(required eventService, required authService) {
        arguments.eventService.registerInterceptor("onBeforeAction", function(event) {
            // Skip auth for public pages
            var publicPages = ["Auth.login", "Auth.register", "Home.index"];
            var currentAction = event.handler & "." & event.action;

            if (!arrayFind(publicPages, currentAction)) {
                // Check authentication
                if (!arguments.authService.isAuthenticated()) {
                    event.redirect("/login");
                }
            }
        });
    }

    public array function getDependencies() {
        return ["SessionModule"];
    }

    public struct function getConfig() {
        return {
            auth: {
                sessionTimeout: 30,  // minutes
                passwordMinLength: 8,
                requireEmailVerification: false
            }
        };
    }
}
```

## Module Configuration

### Default Configuration

Modules provide default config:

```cfml
public struct function getConfig() {
    return {
        myModule: {
            enabled: true,
            apiKey: "",
            timeout: 30
        }
    };
}
```

### Override Configuration

Application config overrides module defaults:

```cfml
// config/application.cfc
this.moduleConfig = {
    myModule: {
        enabled: true,
        apiKey: "production-key",
        timeout: 60  // Override default
    }
};
```

### Access Configuration

Modules access merged config:

```cfml
public void function boot(required container) {
    var config = arguments.container.resolve("config");
    var myConfig = config.myModule;

    if (myConfig.enabled) {
        // Initialize with config values
    }
}
```

## Anti-Patterns

### Resolving Dependencies in register()

**Bad:**
```cfml
public void function register(required container) {
    var service = arguments.container.resolve("SomeService");  // Error!
    // Other modules not registered yet
}
```

**Good:**
```cfml
public void function register(required container) {
    arguments.container.bind("MyService", function(c) {
        var service = c.resolve("SomeService");  // Resolved later
        return new MyService(service);
    });
}
```

Resolve dependencies in `boot()`, not `register()`.

### Circular Dependencies

**Bad:**
```cfml
// ModuleA depends on ModuleB
public array function getDependencies() {
    return ["ModuleB"];
}

// ModuleB depends on ModuleA
public array function getDependencies() {
    return ["ModuleA"];  // Circular!
}
```

**Good:**
```cfml
// Extract shared functionality to ModuleC
// ModuleA depends on ModuleC
// ModuleB depends on ModuleC
// No circular dependency
```

### Heavy Logic in Constructor

**Bad:**
```cfml
component implements="fuse.core.IModule" {

    public function init() {
        // Heavy initialization in constructor
        variables.data = loadLargeDataset();
        variables.connection = connectToService();
        return this;
    }
}
```

**Good:**
```cfml
component implements="fuse.core.IModule" {

    public void function boot(required container) {
        // Initialize during boot phase
        var service = arguments.container.resolve("MyService");
        service.initialize();
    }
}
```

Keep constructors lightweight, initialize in `boot()`.

### Tight Coupling Between Modules

**Bad:**
```cfml
// ModuleA directly instantiates from ModuleB
var blogService = new app.modules.blog.BlogService();
```

**Good:**
```cfml
// Use DI container for loose coupling
var blogService = container.resolve("BlogService");
```

Use container for inter-module dependencies.

## Related Topics

- [Handlers](../handlers.md) - Handler dependency injection
- [Configuration](../getting-started/configuration.md) - Application configuration
- [Views](views.md) - View system (coming in v1.1)
- [Cache Providers](cache-providers.md) - Cache modules (coming in v1.1)
