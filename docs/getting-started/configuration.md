# Configuration

Configure Fuse framework for different environments and databases.

## Overview

Fuse uses a simple, environment-based configuration system:

1. **Database configuration** - `config/database.cfc` defines database settings per environment
2. **Environment variables** - Environment-specific values via server environment or `.env` files
3. **Application settings** - `Application.cfc` for framework and application settings

## Database Configuration

### Basic Setup

The `config/database.cfc` file defines database connection settings for each environment.

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
			"test": {
				"type": "mysql",
				"name": "myapp_test",
				"host": "localhost",
				"port": 3306,
				"database": "myapp_test",
				"username": "root",
				"password": ""
			},
			"production": {
				"type": "mysql",
				"name": "myapp",
				"host": server.system.environment.DB_HOST ?: "localhost",
				"port": server.system.environment.DB_PORT ?: 3306,
				"database": server.system.environment.DB_NAME ?: "myapp",
				"username": server.system.environment.DB_USER ?: "",
				"password": server.system.environment.DB_PASS ?: ""
			}
		};
	}

	private numeric function getDefaultPort(required string type) {
		switch (arguments.type) {
			case "mysql":
				return 3306;
			case "postgresql":
				return 5432;
			case "sqlserver":
				return 1433;
			case "h2":
				return 9092;
			default:
				return 3306;
		}
	}

}
```

### Database Types

Fuse supports multiple database systems:

#### MySQL

```cfml
"development": {
	"type": "mysql",
	"name": "myapp_dev",
	"host": "localhost",
	"port": 3306,
	"database": "myapp_dev",
	"username": "root",
	"password": "secret"
}
```

#### PostgreSQL

```cfml
"development": {
	"type": "postgresql",
	"name": "myapp_dev",
	"host": "localhost",
	"port": 5432,
	"database": "myapp_dev",
	"username": "postgres",
	"password": "secret"
}
```

#### SQL Server

```cfml
"development": {
	"type": "sqlserver",
	"name": "myapp_dev",
	"host": "localhost",
	"port": 1433,
	"database": "myapp_dev",
	"username": "sa",
	"password": "secret"
}
```

#### H2 (Embedded)

```cfml
"development": {
	"type": "h2",
	"name": "myapp_dev",
	"host": "",
	"port": 9092,
	"database": "./db/myapp_dev",
	"username": "",
	"password": ""
}
```

H2 is ideal for development and testing - no separate database server required.

### Configuration Properties

Each database configuration supports these properties:

| Property   | Type   | Required | Description |
|------------|--------|----------|-------------|
| type       | string | Yes      | Database type (mysql, postgresql, sqlserver, h2) |
| name       | string | Yes      | Datasource name (referenced in Application.cfc) |
| host       | string | Yes      | Database server hostname |
| port       | number | Yes      | Database server port |
| database   | string | Yes      | Database name or file path (for H2) |
| username   | string | No       | Database username |
| password   | string | No       | Database password |

## Environment Variables

### Using Environment Variables

Production configuration uses environment variables for security:

```cfml
"production": {
	"type": "mysql",
	"name": "myapp",
	"host": server.system.environment.DB_HOST ?: "localhost",
	"port": server.system.environment.DB_PORT ?: 3306,
	"database": server.system.environment.DB_NAME ?: "myapp",
	"username": server.system.environment.DB_USER ?: "",
	"password": server.system.environment.DB_PASS ?: ""
}
```

### Setting Environment Variables

**Linux/macOS:**

```bash
export DB_HOST=db.example.com
export DB_PORT=3306
export DB_NAME=myapp_prod
export DB_USER=app_user
export DB_PASS=secure_password
```

**Windows:**

```cmd
set DB_HOST=db.example.com
set DB_PORT=3306
set DB_NAME=myapp_prod
set DB_USER=app_user
set DB_PASS=secure_password
```

**Docker/Docker Compose:**

```yaml
# docker-compose.yml
services:
  app:
    environment:
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_NAME=myapp
      - DB_USER=root
      - DB_PASS=secret
```

### .env Files (Optional)

While Fuse doesn't natively support `.env` files, you can use CommandBox's `.env` support:

```bash
# .env
DB_HOST=localhost
DB_PORT=3306
DB_NAME=myapp_dev
DB_USER=root
DB_PASS=secret
```

CommandBox automatically loads `.env` files into `server.system.environment`.

**Note:** Add `.env` to `.gitignore` to prevent committing sensitive credentials:

```
# .gitignore
.env
.env.local
.env.*.local
```

## Environment-Specific Settings

### Detecting Environment

Fuse detects the current environment in this order:

1. `application.environment` variable
2. `FUSE_ENV` environment variable
3. Default: `"production"`

### Setting Environment

**Via Application.cfc:**

```cfml
// Application.cfc
component {
	// Set environment
	this.environment = "development";

	// Other settings...
}
```

**Via Environment Variable:**

```bash
export FUSE_ENV=production
```

**Via CommandBox:**

```bash
# Start server in specific environment
box server start cfengine=lucee@7 FUSE_ENV=development
```

### Environment Names

Standard environment names:

- `development` - Local development
- `test` - Automated testing
- `staging` - Pre-production staging
- `production` - Live production

You can use any environment name - Fuse doesn't enforce specific names.

## Application Configuration

### Application.cfc Settings

Configure framework behavior in `Application.cfc`:

```cfml
// Application.cfc
component {

	// Application identity
	this.name = "MyApp";
	this.sessionManagement = true;
	this.sessionTimeout = createTimeSpan(0, 0, 30, 0);

	// Framework settings
	this.applicationKey = "fuse";
	this.lockTimeout = 30;

	// Datasource (matches name in database.cfc)
	this.datasource = "myapp_dev";

	// Framework mapping
	this.mappings["/fuse"] = expandPath("../fuse/");
	this.mappings["/app"] = expandPath("./app/");

	public boolean function onApplicationStart() {
		var bootstrap = new fuse.core.Bootstrap();
		bootstrap.initFramework(application, this.applicationKey, this.lockTimeout);
		return true;
	}

	public boolean function onRequestStart(required string targetPage) {
		if (!structKeyExists(application, this.applicationKey)) {
			throw(
				type = "Framework.NotInitialized",
				message = "Framework not initialized"
			);
		}

		request.fuse = application[this.applicationKey];
		return true;
	}

}
```

### Key Settings

| Setting           | Type    | Description |
|-------------------|---------|-------------|
| this.name         | string  | Unique application name |
| this.datasource   | string  | Default datasource name |
| this.applicationKey | string | Framework instance key (default: "fuse") |
| this.lockTimeout  | number  | Framework initialization lock timeout (seconds) |
| this.mappings     | struct  | CFC path mappings |

## Multiple Databases

### Configuring Multiple Databases

Configure additional databases in `database.cfc`:

```cfml
// config/database.cfc
component {

	public struct function getConfig() {
		return {
			"development": {
				// Primary database
				"primary": {
					"type": "mysql",
					"name": "myapp_dev",
					"host": "localhost",
					"port": 3306,
					"database": "myapp_dev",
					"username": "root",
					"password": ""
				},
				// Analytics database
				"analytics": {
					"type": "postgresql",
					"name": "analytics_dev",
					"host": "localhost",
					"port": 5432,
					"database": "analytics_dev",
					"username": "postgres",
					"password": ""
				}
			}
		};
	}

}
```

### Using Multiple Databases

Specify datasource when querying:

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

	function init() {
		super.init();

		// Use default datasource
		// (inherited from Application.cfc)

		return this;
	}

}

// app/models/AnalyticsEvent.cfc
component extends="fuse.orm.ActiveRecord" {

	variables.datasource = "analytics_dev";

	function init() {
		super.init();
		return this;
	}

}
```

Or specify datasource per query:

```cfml
// Query primary database (default)
var users = User::all();

// Query analytics database
var events = queryExecute(
	"SELECT * FROM events",
	[],
	{datasource: "analytics_dev"}
);
```

## Configuration Precedence

Configuration loads in this order (later overrides earlier):

1. **Framework defaults** - Built-in Fuse defaults
2. **Application.cfc** - Application-level settings
3. **database.cfc** - Environment-specific database config
4. **Environment variables** - Runtime environment values

Example:

```cfml
// 1. Framework default
datasource = "fuse"

// 2. Application.cfc overrides
this.datasource = "myapp_dev"

// 3. database.cfc provides connection details for "myapp_dev"

// 4. Environment variable overrides host
server.system.environment.DB_HOST = "production-db.example.com"
```

## Common Configuration Patterns

### Development with Local Database

```cfml
// Application.cfc
this.datasource = "myapp_dev";
this.environment = "development";

// config/database.cfc
"development": {
	"type": "h2",
	"name": "myapp_dev",
	"database": "./db/development",
	"username": "",
	"password": ""
}
```

### Testing with Separate Database

```cfml
// Application.cfc (or test bootstrap)
this.datasource = "myapp_test";
this.environment = "test";

// config/database.cfc
"test": {
	"type": "h2",
	"name": "myapp_test",
	"database": "./db/test",
	"username": "",
	"password": ""
}
```

Tests use separate database to avoid polluting development data.

### Production with Environment Variables

```cfml
// Application.cfc
this.datasource = "myapp";
// Environment auto-detected from FUSE_ENV

// config/database.cfc
"production": {
	"type": "mysql",
	"name": "myapp",
	"host": server.system.environment.DB_HOST,
	"port": server.system.environment.DB_PORT,
	"database": server.system.environment.DB_NAME,
	"username": server.system.environment.DB_USER,
	"password": server.system.environment.DB_PASS
}
```

Never commit production credentials to version control!

### Staging Environment

```cfml
// Export staging environment
export FUSE_ENV=staging

// config/database.cfc
"staging": {
	"type": "mysql",
	"name": "myapp_staging",
	"host": "staging-db.example.com",
	"port": 3306,
	"database": "myapp_staging",
	"username": server.system.environment.DB_USER,
	"password": server.system.environment.DB_PASS
}
```

## Troubleshooting

### Database Connection Fails

**Problem:** Can't connect to database.

**Solution:**

1. Verify database is running:
   ```bash
   # MySQL
   mysql -h localhost -u root -p

   # PostgreSQL
   psql -h localhost -U postgres
   ```

2. Check credentials in `config/database.cfc`

3. Ensure database exists:
   ```sql
   CREATE DATABASE myapp_dev;
   ```

4. Test datasource in Lucee admin:
   - Navigate to Lucee admin
   - Go to Services → Datasource
   - Verify datasource or create manually

### Wrong Environment

**Problem:** Using production config in development.

**Solution:**

Check current environment:

```cfml
// Add to handler for debugging
function debug() {
	return {
		environment: application.fuse.config.detectEnvironment(),
		datasource: application.datasource
	};
}
```

Set environment explicitly:

```cfml
// Application.cfc
this.environment = "development";
```

### Datasource Not Found

**Problem:** "Datasource [myapp_dev] not found" error.

**Solution:**

1. Verify datasource name matches in both files:
   ```cfml
   // Application.cfc
   this.datasource = "myapp_dev";

   // config/database.cfc
   "name": "myapp_dev",
   ```

2. Check Lucee admin for datasource registration

3. Restart application:
   ```bash
   # Add ?fwreinit=1 to URL
   http://localhost:8080/?fwreinit=1
   ```

### Environment Variables Not Loading

**Problem:** Environment variables return empty.

**Solution:**

1. Verify variables are set:
   ```bash
   echo $DB_HOST
   ```

2. Restart Lucee server after setting variables

3. Use CommandBox `.env` file:
   ```bash
   # .env
   DB_HOST=localhost
   ```

4. Check variable access:
   ```cfml
   writeDump(server.system.environment);
   ```

## Best Practices

### Security

1. **Never commit credentials** - Use environment variables for production
2. **Use .gitignore** - Exclude `.env` files from version control
3. **Separate databases** - Use different databases per environment
4. **Minimal permissions** - Grant only required database privileges

### Organization

1. **Consistent naming** - Use `appname_environment` pattern (e.g., `myapp_dev`, `myapp_test`)
2. **Document settings** - Comment non-obvious configuration
3. **Provide defaults** - Use `?:` operator for fallback values
4. **Validate config** - Check required settings on startup

### Development Workflow

1. **Local development** - Use H2 or local MySQL/PostgreSQL
2. **Testing** - Use separate test database with transactions
3. **Staging** - Mirror production environment
4. **Production** - Use environment variables for all credentials

## Next Steps

Now that you understand configuration:

1. **Set up your database** - Configure connection for your environment
2. **Create migrations** - Define your database schema ([Migrations Guide](../guides/migrations.md))
3. **Build models** - Create ActiveRecord models ([Models Guide](../guides/models-orm.md))
4. **Learn routing** - Configure application routes ([Routing Guide](../guides/routing.md))

## Related Topics

- [Installation](installation.md) - Installing Fuse and lucli
- [Quickstart](quickstart.md) - Build your first app
- [Migrations](../guides/migrations.md) - Database schema management
- [Models & ORM](../guides/models-orm.md) - Working with databases
