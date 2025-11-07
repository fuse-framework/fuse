# Quickstart Guide

Build and run your first Fuse application in 5 minutes.

## Prerequisites

Before starting, ensure you have:

- Lucee 7.0+ installed
- `lucli` CLI tool installed (see [Installation](installation.md))
- MySQL, PostgreSQL, or H2 database available

## Step 1: Create New App

Create a new Fuse application called `myapp`:

```bash
lucli new myapp --database=h2
cd myapp
```

We're using H2 (embedded database) for this quickstart so you don't need to set up a database server.

**Output:**

```
Creating new Fuse application: myapp

  ✓ Created directory structure
  ✓ Generated Application.cfc
  ✓ Generated config/routes.cfc
  ✓ Generated config/database.cfc
  ✓ Generated README.md
  ✓ Generated .gitignore
  ✓ Initialized git repository

Application created successfully!
```

## Step 2: Configure Database

For H2, no configuration needed! The generated `config/database.cfc` is already set up.

**For MySQL/PostgreSQL users:**

Edit `config/database.cfc` and update the development section:

```cfml
// config/database.cfc
component {

	public struct function getConfig() {
		return {
			"development": {
				"type": "mysql",
				"name": "myapp_dev",
				"host": "localhost",
				"port": 3306,
				"database": "myapp_dev",
				"username": "root",
				"password": ""
			},
			// ... test and production configs
		};
	}

	// ... helper methods
}
```

See [Configuration Guide](configuration.md) for detailed database setup.

## Step 3: Generate First Model

Create a `User` model with name and email fields:

```bash
lucli generate model User name:string email:string:unique
```

**Output:**

```
Generating model: User

  ✓ Created app/models/User.cfc
  ✓ Created tests/models/UserTest.cfc
  ✓ Created database/migrations/20251106143022_CreateUsers.cfc

Model created successfully!
```

**Generated files:**

`app/models/User.cfc`:
```cfml
component extends="fuse.orm.ActiveRecord" {

	function init() {
		super.init();

		// Define relationships here

		// Define validations here

		return this;
	}

}
```

`database/migrations/20251106143022_CreateUsers.cfc`:
```cfml
component extends="fuse.orm.Migration" {

	function up() {
		var schema = getSchema();
		schema.create("users", function(table) {
			table.id();
			table.string("name");
			table.string("email").unique();
			table.timestamps();
		});
	}

	function down() {
		var schema = getSchema();
		schema.drop("users");
	}

}
```

## Step 4: Run Migrations

Create the database table by running the migration:

```bash
lucli migrate
```

**Output:**

```
Running pending migrations...

  Migrated: 20251106143022_CreateUsers.cfc

Migrations complete! (1 migration)
```

The `users` table now exists with columns: `id`, `name`, `email`, `createdAt`, `updatedAt`.

## Step 5: Generate Handler

Generate a handler to process HTTP requests for users:

```bash
lucli generate handler Users
```

**Output:**

```
Generating handler: Users

  ✓ Created app/handlers/Users.cfc
  ✓ Created tests/handlers/UsersTest.cfc

Handler created successfully!
```

**Generated file:**

`app/handlers/Users.cfc`:
```cfml
component {

	/**
	 * List all users
	 * @route GET /users
	 */
	function index() {
		return {
			data: [],
			message: "List all users"
		};
	}

	/**
	 * Show single user
	 * @route GET /users/:id
	 */
	function show(required numeric id) {
		return {
			data: {},
			message: "Show user ##arguments.id##"
		};
	}

	/**
	 * Show new user form
	 * @route GET /users/new
	 */
	function new() {
		return {
			message: "New user form"
		};
	}

	/**
	 * Create new user
	 * @route POST /users
	 */
	function create() {
		return {
			created: true,
			message: "User created"
		};
	}

	/**
	 * Show edit user form
	 * @route GET /users/:id/edit
	 */
	function edit(required numeric id) {
		return {
			message: "Edit user ##arguments.id## form"
		};
	}

	/**
	 * Update user
	 * @route PUT/PATCH /users/:id
	 */
	function update(required numeric id) {
		return {
			updated: true,
			message: "User ##arguments.id## updated"
		};
	}

	/**
	 * Delete user
	 * @route DELETE /users/:id
	 */
	function destroy(required numeric id) {
		return {
			deleted: true,
			message: "User ##arguments.id## deleted"
		};
	}

}
```

## Step 6: Add Routes

Configure routes to connect URLs to handler actions.

Edit `config/routes.cfc`:

```cfml
// config/routes.cfc
component {

	public function configure(required any router) {
		// RESTful routes for users
		router.resource("users");
	}

}
```

The `router.resource("users")` creates all 7 RESTful routes automatically:

| Method | URI              | Name          | Handler Action  |
|--------|------------------|---------------|-----------------|
| GET    | /users           | users_index   | Users.index     |
| GET    | /users/new       | users_new     | Users.new       |
| POST   | /users           | users_create  | Users.create    |
| GET    | /users/:id       | users_show    | Users.show      |
| GET    | /users/:id/edit  | users_edit    | Users.edit      |
| PUT    | /users/:id       | users_update  | Users.update    |
| DELETE | /users/:id       | users_destroy | Users.destroy   |

## Step 7: Add Real Data

Update the handler to use the User model.

Edit `app/handlers/Users.cfc`:

```cfml
// app/handlers/Users.cfc
component {

	function index() {
		var users = User::all();
		return {
			users: users
		};
	}

	function show(required numeric id) {
		var user = User::find(arguments.id);
		return {
			user: user
		};
	}

	function create() {
		var user = User::create({
			name: form.name ?: "Test User",
			email: form.email ?: "test@example.com"
		});

		return {
			created: true,
			user: user
		};
	}

}
```

## Step 8: Start Server

Start the development server:

```bash
lucli serve
```

**Output:**

```
Starting Fuse development server...
Server running at http://127.0.0.1:8080
Press Ctrl+C to stop
```

## Step 9: Test in Browser

Open your browser and test the endpoints:

### List All Users (Empty Initially)

```
GET http://127.0.0.1:8080/users
```

**Response:**

```json
{
	"users": []
}
```

### Create a User

```bash
# Using curl
curl -X POST http://127.0.0.1:8080/users \
  -d "name=John Doe" \
  -d "email=john@example.com"
```

**Response:**

```json
{
	"created": true,
	"user": {
		"id": 1,
		"name": "John Doe",
		"email": "john@example.com",
		"createdAt": "2025-11-06 14:30:22",
		"updatedAt": "2025-11-06 14:30:22"
	}
}
```

### List Users Again

```
GET http://127.0.0.1:8080/users
```

**Response:**

```json
{
	"users": [
		{
			"id": 1,
			"name": "John Doe",
			"email": "john@example.com",
			"createdAt": "2025-11-06 14:30:22",
			"updatedAt": "2025-11-06 14:30:22"
		}
	]
}
```

### Show Single User

```
GET http://127.0.0.1:8080/users/1
```

**Response:**

```json
{
	"user": {
		"id": 1,
		"name": "John Doe",
		"email": "john@example.com",
		"createdAt": "2025-11-06 14:30:22",
		"updatedAt": "2025-11-06 14:30:22"
	}
}
```

## Verify Routes

Check which routes are registered:

```bash
lucli routes
```

**Output:**

```
+--------+------------------+------------------+------------------+
| Method | URI              | Name             | Handler          |
+--------+------------------+------------------+------------------+
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

## What You Built

In 5 minutes, you created:

1. ✅ A complete Fuse application
2. ✅ A `User` model with name and email fields
3. ✅ A database migration to create the `users` table
4. ✅ A `Users` handler with RESTful actions
5. ✅ Routes connecting URLs to handler actions
6. ✅ Working CRUD operations (Create, Read, Update, Delete)
7. ✅ A running development server

## Next Steps

Now that you have a working app, explore more features:

### Add Validations

Ensure data integrity with model validations:

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

	function init() {
		super.init();

		// Add validations
		validates("name", "required");
		validates("email", "required|email|unique:users,email");

		return this;
	}

}
```

See [Validations Guide](../guides/validations.md) for more.

### Add Relationships

Create a `Post` model that belongs to a user:

```bash
lucli generate model Post title:string body:text user:references
lucli migrate
```

Update models:

```cfml
// app/models/User.cfc
function init() {
	super.init();
	hasMany("posts");
	return this;
}

// app/models/Post.cfc
function init() {
	super.init();
	belongsTo("user");
	return this;
}
```

See [Relationships Guide](../guides/relationships.md) for more.

### Write Tests

Test your models and handlers:

```cfml
// tests/models/UserTest.cfc
component extends="fuse.testing.TestCase" {

	function test_creates_user() {
		var user = User::create({
			name: "Test User",
			email: "test@example.com"
		});

		expect(user.name).toBe("Test User");
		expect(user.email).toBe("test@example.com");
	}

	function test_requires_name() {
		var user = User::new({email: "test@example.com"});
		var isValid = user.isValid();

		expect(isValid).toBe(false);
		expect(user.errors()).toHaveKey("name");
	}

}
```

See [Testing Guide](../guides/testing.md) for more.

### Build a Complete App

Follow the [Blog Tutorial](../tutorials/blog-application.md) to build a full-featured blog with users, posts, comments, and authentication.

## Troubleshooting

### Server Won't Start

**Problem:** `lucli serve` fails.

**Solution:**

```bash
# Check if port 8080 is already in use
lsof -i :8080

# Use different port
lucli serve --port=3000
```

### Migration Fails

**Problem:** `lucli migrate` returns database error.

**Solution:**

1. Verify database configuration in `config/database.cfc`
2. Ensure database exists (for MySQL/PostgreSQL)
3. Check database credentials
4. For H2, ensure directory permissions allow file creation

### Routes Not Working

**Problem:** Accessing URL returns 404.

**Solution:**

1. Verify routes are defined in `config/routes.cfc`
2. Check route configuration with `lucli routes`
3. Restart server after changing routes
4. Ensure URL matches exactly (case-sensitive on some systems)

### Model Not Found

**Problem:** "User component not found" error.

**Solution:**

Verify Application.cfc has correct mapping:

```cfml
// Application.cfc
this.mappings["/app"] = expandPath("./app/");
this.mappings["/fuse"] = expandPath("../fuse/");
```

## Command Summary

All commands used in this quickstart:

```bash
# Create app
lucli new myapp --database=h2
cd myapp

# Generate model with migration
lucli generate model User name:string email:string:unique

# Run migrations
lucli migrate

# Generate handler
lucli generate handler Users

# View routes
lucli routes

# Start server
lucli serve
```

## Related Topics

- [Installation](installation.md) - Detailed installation instructions
- [Configuration](configuration.md) - Database and environment configuration
- [Models & ORM](../guides/models-orm.md) - ActiveRecord pattern and querying
- [Routing](../guides/routing.md) - URL routing and RESTful routes
- [Handlers](../guides/handlers.md) - Request handling patterns
- [Migrations](../guides/migrations.md) - Database schema management
- [CLI Reference](../reference/cli-reference.md) - Complete CLI documentation
