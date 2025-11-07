# Installation

Get Fuse framework up and running on your system.

## System Requirements

Before installing Fuse, ensure your system meets these requirements:

- **Lucee 7.0+** - Fuse is built specifically for Lucee 7 and newer
- **Java 11+** - Required by Lucee
- **CommandBox** - For CLI tooling (recommended)
- **Database** - One of:
  - MySQL 5.7+
  - PostgreSQL 10+
  - SQL Server 2016+
  - H2 (embedded, for development/testing)

## Installing lucli

The `lucli` CLI tool is the primary interface for Fuse development. Install via CommandBox:

```bash
# Install CommandBox first if you haven't already
# Visit: https://www.ortussolutions.com/products/commandbox

# Install lucli globally
box install lucli

# Verify installation
lucli --version
```

**Alternative Installation:**

If you don't want to use CommandBox, you can invoke Fuse CLI commands directly:

```bash
# Direct invocation (requires Lucee in PATH)
lucee fuse.cli.commands.New myapp

# Or via box (if CommandBox is available)
box task run fuse.cli.commands.New myapp
```

For the rest of this guide, we'll use the `lucli` command for brevity.

## Creating Your First App

Create a new Fuse application using the `new` command:

```bash
# Create app with default MySQL database
lucli new myapp

# Create app with PostgreSQL
lucli new myapp --database=postgresql

# Create app with H2 (embedded, no setup required)
lucli new myapp --database=h2
```

This creates a complete application scaffold with all necessary files and directories.

### Generated Output

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

Next steps:
  cd myapp
  # Configure database in config/database.cfc
  lucli migrate
  lucli serve
```

### What Gets Created

```
myapp/
├── Application.cfc           # Application configuration
├── box.json                  # CommandBox package descriptor
├── README.md                 # Project documentation
├── .gitignore               # Git ignore rules
├── app/
│   ├── models/              # ActiveRecord models
│   ├── handlers/            # Request handlers (controllers)
│   └── views/               # View templates (future)
│       └── layouts/         # Layout templates
├── config/
│   ├── routes.cfc           # Route definitions
│   ├── database.cfc         # Database configuration
│   └── templates/           # Custom generator templates
├── database/
│   ├── migrations/          # Database migrations
│   │   └── README.md
│   └── seeds/               # Seed data
│       └── DatabaseSeeder.cfc
├── modules/                 # Fuse modules (plugins)
├── public/                  # Static assets
│   ├── css/
│   ├── js/
│   └── images/
└── tests/                   # Test files
    ├── fixtures/            # Test fixtures
    ├── integration/         # Integration tests
    └── unit/                # Unit tests
```

## Directory Structure Tour

### `/app` - Application Code

Your application logic lives here:

- **`models/`** - ActiveRecord model classes that represent database tables
- **`handlers/`** - Request handlers that process HTTP requests and return responses
- **`views/`** - View templates (coming in future release)

### `/config` - Configuration

Application configuration files:

- **`routes.cfc`** - Define your URL routing rules
- **`database.cfc`** - Database connection settings for each environment
- **`templates/`** - Optional custom templates for code generators

### `/database` - Database Schema

Database-related files:

- **`migrations/`** - Versioned database schema changes
- **`seeds/`** - Sample or default data for development/testing

### `/public` - Static Assets

Publicly accessible files served directly by the web server:

- **`css/`** - Stylesheets
- **`js/`** - JavaScript files
- **`images/`** - Images and graphics

### `/tests` - Test Suite

Automated tests for your application:

- **`unit/`** - Unit tests (test individual components in isolation)
- **`integration/`** - Integration tests (test multiple components together)
- **`fixtures/`** - Test data and fixtures

### `/modules` - Fuse Modules

Third-party and custom Fuse modules (plugins) for extending functionality.

## Verifying Installation

After creating your app, verify everything works:

```bash
cd myapp

# Check that framework is accessible
lucli routes
```

Expected output:

```
+--------+------------------+------------------+------------------+
| Method | URI              | Name             | Handler          |
+--------+------------------+------------------+------------------+
| (No routes defined yet)                                         |
+--------+------------------+------------------+------------------+
```

If you see this output, your installation is successful!

## Troubleshooting

### Error: "lucli: command not found"

**Problem:** The `lucli` command is not in your system PATH.

**Solution:**

```bash
# Verify CommandBox is installed
box version

# If CommandBox works, reinstall lucli
box install lucli --force

# Or use box directly
box task run fuse.cli.commands.New myapp
```

### Error: "Lucee not found"

**Problem:** Lucee is not installed or not in PATH.

**Solution:**

1. Install Lucee 7+ from [https://lucee.org](https://lucee.org)
2. Ensure `lucee` command is in your PATH
3. Or use CommandBox which bundles Lucee: `box server start`

### Error: "Could not create directory"

**Problem:** Permission denied or directory already exists.

**Solution:**

```bash
# Check if directory exists
ls -la myapp

# Remove existing directory if needed
rm -rf myapp

# Create with different name
lucli new myapp-2

# Or check permissions
sudo chown -R $USER:$GROUP .
```

### Generated Files Not Loading

**Problem:** Framework components can't be found.

**Solution:** Verify the Fuse framework mapping in `Application.cfc`:

```cfml
// Application.cfc
this.mappings["/fuse"] = expandPath("../fuse/");
```

Adjust the path based on where Fuse is installed relative to your application.

### Database Connection Fails

**Problem:** Can't connect to database after setup.

**Solution:** See [Configuration Guide](configuration.md) for detailed database setup instructions.

## Next Steps

Now that Fuse is installed:

1. **Configure your database** - See [Configuration Guide](configuration.md)
2. **Build your first app** - Follow the [Quickstart Guide](quickstart.md)
3. **Learn routing** - Read the [Routing Guide](../guides/routing.md)
4. **Explore generators** - Check the [CLI Reference](../reference/cli-reference.md)

## Related Topics

- [Quickstart Guide](quickstart.md) - Build your first app in 5 minutes
- [Configuration Guide](configuration.md) - Configure database and environments
- [CLI Reference](../reference/cli-reference.md) - Complete CLI command documentation
