# Migrations

Migrations provide version control for your database schema. Create, modify, and rollback database changes with simple, code-based definitions.

## Overview

Migrations are classes that define schema changes:

```cfml
// database/migrations/20251105000001_CreateUsersTable.cfc
component extends="fuse.orm.Migration" {

    public function up() {
        schema.create("users", function(table) {
            table.id();
            table.string("email").notNull().unique();
            table.string("name");
            table.timestamps();
        });
    }

    public function down() {
        schema.drop("users");
    }

}
```

Run migrations to apply changes:

```bash
lucli migrate
```

Fuse tracks which migrations have run and only executes pending ones.

## Migration File Naming

Migration files follow strict naming conventions:

**Format:** `YYYYMMDDHHMMSS_DescriptiveName.cfc`

Examples:
- `20251105120000_CreateUsersTable.cfc`
- `20251105120100_AddEmailToUsers.cfc`
- `20251105120200_CreatePostsTable.cfc`

### Timestamp Prefix

Timestamp determines execution order:
- **YYYY** - Year (4 digits)
- **MM** - Month (01-12)
- **DD** - Day (01-31)
- **HH** - Hour (00-23)
- **MM** - Minute (00-59)
- **SS** - Second (00-59)

Migrations run in chronological order based on timestamp.

### Descriptive Name

Name describes the change in PascalCase:
- `CreateUsersTable` - Creating new table
- `AddEmailToUsers` - Adding column
- `RemovePhoneFromUsers` - Removing column
- `CreatePostsCommentsRelation` - Adding foreign key

Names should be clear and specific.

## Creating Migrations

### Using Generators

Generate migrations with the CLI:

```bash
# Create table migration
lucli generate migration CreateUsers

# Add column migration
lucli generate migration AddEmailToUsers email:string:unique

# Remove column migration
lucli generate migration RemovePhoneFromUsers phone:remove

# Custom migration
lucli generate migration UpdateUserStatuses
```

Generates file in `/database/migrations/` with timestamp prefix.

### Generated Migration Structure

Create table migration:

```cfml
// database/migrations/20251105120000_CreateUsers.cfc
component extends="fuse.orm.Migration" {

    public function up() {
        schema.create("users", function(table) {
            table.id();
            table.string("email").notNull().unique();
            table.timestamps();
        });
    }

    public function down() {
        schema.drop("users");
    }

}
```

Add column migration:

```cfml
// database/migrations/20251105120100_AddEmailToUsers.cfc
component extends="fuse.orm.Migration" {

    public function up() {
        schema.table("users", function(table) {
            table.string("email").notNull();
        });
    }

    public function down() {
        schema.table("users", function(table) {
            table.dropColumn("email");
        });
    }

}
```

## Migration Structure

### up() Method

Defines forward migration (apply change):

```cfml
public function up() {
    schema.create("posts", function(table) {
        table.id();
        table.string("title");
        table.text("body");
        table.timestamps();
    });
}
```

### down() Method

Defines reverse migration (undo change):

```cfml
public function down() {
    schema.drop("posts");
}
```

Down migrations should reverse exactly what up() does.

### schema Object

Access SchemaBuilder via `schema` variable:

```cfml
public function up() {
    schema.create("users", callback);        // Create table
    schema.table("users", callback);         // Modify table
    schema.drop("users");                    // Drop table
    schema.dropIfExists("users");            // Drop if exists
    schema.rename("old_name", "new_name");   // Rename table
}
```

## Schema Builder API

### Creating Tables

```cfml
schema.create("users", function(table) {
    table.id();                              // Auto-increment primary key
    table.string("email").notNull().unique();
    table.string("name", 100);               // Length: 100
    table.text("bio");
    table.integer("age");
    table.boolean("active").default(1);
    table.datetime("published_at");
    table.timestamps();                      // created_at, updated_at
});
```

### Create If Not Exists

```cfml
schema.createIfNotExists("users", function(table) {
    table.id();
    table.string("email");
});
```

Useful for conditional migrations or testing.

### Modifying Tables

```cfml
schema.table("users", function(table) {
    // Add columns
    table.string("phone");
    table.integer("age").default(0);

    // Add indexes
    table.index("email");
    table.index(["user_id", "status"]);  // Composite index

    // Add foreign keys
    table.foreignKey("team_id")
        .references("teams", "id")
        .onDelete("CASCADE");
});
```

### Dropping Tables

```cfml
// Drop unconditionally
schema.drop("users");

// Drop if exists
schema.dropIfExists("temp_table");
```

### Renaming Tables

```cfml
schema.rename("old_users", "users");
```

## Column Types and Modifiers

### Column Types

```cfml
table.id();                          // Autoincrement INT primary key

// Numeric types
table.integer("count");              // INT
table.bigInteger("user_id");         // BIGINT
table.decimal("price", 10, 2);       // DECIMAL(10,2)
table.float("rating");               // FLOAT

// String types
table.string("email");               // VARCHAR(255) default
table.string("name", 100);           // VARCHAR(100) with length
table.text("body");                  // TEXT
table.char("code", 5);               // CHAR(5) fixed length

// Boolean
table.boolean("active");             // TINYINT or BOOLEAN

// Date/Time
table.date("birth_date");            // DATE
table.datetime("published_at");      // DATETIME
table.timestamp("created_at");       // TIMESTAMP

// Special
table.timestamps();                  // created_at, updated_at DATETIME
table.json("metadata");              // JSON column (if supported)
```

### Column Modifiers

Chain modifiers after column type:

```cfml
// NOT NULL constraint
table.string("email").notNull();

// UNIQUE constraint
table.string("email").unique();

// DEFAULT value
table.boolean("active").default(1);
table.string("status").default("pending");
table.integer("count").default(0);

// INDEX flag
table.string("email").index();
table.bigInteger("user_id").index();

// Combine modifiers
table.string("email", 255)
    .notNull()
    .unique()
    .index();
```

### Primary Keys

```cfml
// Standard auto-increment id
table.id();

// Custom primary key
table.bigInteger("user_id").primary();

// Composite primary key (future feature)
table.primary(["user_id", "role_id"]);
```

### Foreign Keys

```cfml
// Add foreign key column and constraint
table.bigInteger("user_id").notNull();
table.foreignKey("user_id")
    .references("users", "id")
    .onDelete("CASCADE")
    .onUpdate("CASCADE");

// Cascade options
.onDelete("CASCADE")     // Delete related records
.onDelete("SET NULL")    // Set FK to NULL
.onDelete("RESTRICT")    // Prevent deletion
.onDelete("NO ACTION")   // Database default

.onUpdate("CASCADE")     // Update related records
.onUpdate("RESTRICT")    // Prevent updates
```

### Indexes

```cfml
// Single column index
table.index("email");

// Composite index
table.index(["user_id", "post_id"]);
table.index(["user_id", "status"]);

// Named index (future feature)
table.index("email", "idx_user_email");
```

### Timestamps

Convenience method for created_at and updated_at:

```cfml
table.timestamps();

// Equivalent to:
table.datetime("created_at");
table.datetime("updated_at");
```

Models automatically populate these when present.

## Running Migrations

### Execute Pending Migrations

```bash
lucli migrate
```

Output:

```
Running pending migrations...

  Migrated: 20251105000001_CreateUsersTable.cfc
  Migrated: 20251105000002_CreatePostsTable.cfc

Migrations complete! (2 migrations)
```

### Migration Status

View which migrations have run:

```bash
lucli migrate --status
```

Output:

```
Migration Status:

  [✓] 20251105000001_CreateUsersTable.cfc
  [✓] 20251105000002_CreatePostsTable.cfc
  [ ] 20251105000003_AddPhoneToUsers.cfc

2 migrations run, 1 pending
```

### Reset Migrations

Rollback all migrations:

```bash
lucli migrate --reset
```

Executes `down()` for all migrations in reverse order.

### Refresh Migrations

Reset and re-run all migrations:

```bash
lucli migrate --refresh
```

Useful for recreating database from scratch.

### Specify Datasource

Use non-default datasource:

```bash
lucli migrate --datasource=secondary_db
```

## Rolling Back

### Rollback Last Migration

```bash
lucli rollback
```

Executes `down()` for most recent migration.

### Rollback Multiple Migrations

```bash
# Rollback 3 migrations
lucli rollback --steps=3
```

### Rollback All Migrations

```bash
lucli rollback --all
```

Same as `lucli migrate --reset`.

## Migration Patterns

### Creating Related Tables

Create tables with foreign keys:

```cfml
// 20251105120000_CreateUsersTable.cfc
component extends="fuse.orm.Migration" {
    public function up() {
        schema.create("users", function(table) {
            table.id();
            table.string("email").notNull().unique();
            table.string("name");
            table.timestamps();
        });
    }

    public function down() {
        schema.drop("users");
    }
}

// 20251105120100_CreatePostsTable.cfc
component extends="fuse.orm.Migration" {
    public function up() {
        schema.create("posts", function(table) {
            table.id();
            table.bigInteger("user_id").notNull();
            table.string("title", 200).notNull();
            table.text("body").notNull();
            table.timestamps();

            // Foreign key with cascade delete
            table.foreignKey("user_id")
                .references("users", "id")
                .onDelete("CASCADE");

            // Indexes
            table.index("user_id");
        });
    }

    public function down() {
        schema.drop("posts");
    }
}
```

Order matters: Create users before posts (posts reference users).

### Adding Columns

```cfml
// 20251105120200_AddPhoneToUsers.cfc
component extends="fuse.orm.Migration" {
    public function up() {
        schema.table("users", function(table) {
            table.string("phone", 20);
        });
    }

    public function down() {
        schema.table("users", function(table) {
            table.dropColumn("phone");
        });
    }
}
```

### Removing Columns

```cfml
// 20251105120300_RemovePhoneFromUsers.cfc
component extends="fuse.orm.Migration" {
    public function up() {
        schema.table("users", function(table) {
            table.dropColumn("phone");
        });
    }

    public function down() {
        schema.table("users", function(table) {
            table.string("phone", 20);
        });
    }
}
```

### Renaming Columns

```cfml
// Future feature - manual SQL for now
public function up() {
    var sql = "ALTER TABLE users RENAME COLUMN old_name TO new_name";
    queryExecute(sql, {}, {datasource: variables.datasource});
}
```

### Adding Indexes

```cfml
// 20251105120400_AddIndexesToPosts.cfc
component extends="fuse.orm.Migration" {
    public function up() {
        schema.table("posts", function(table) {
            table.index("status");
            table.index(["user_id", "status"]);
        });
    }

    public function down() {
        schema.table("posts", function(table) {
            table.dropIndex("status");
            table.dropIndex(["user_id", "status"]);
        });
    }
}
```

### Many-to-Many Join Tables

```cfml
// 20251105120500_CreatePostTagsTable.cfc
component extends="fuse.orm.Migration" {
    public function up() {
        schema.create("post_tags", function(table) {
            table.id();
            table.bigInteger("post_id").notNull();
            table.bigInteger("tag_id").notNull();
            table.timestamps();

            // Foreign keys
            table.foreignKey("post_id")
                .references("posts", "id")
                .onDelete("CASCADE");

            table.foreignKey("tag_id")
                .references("tags", "id")
                .onDelete("CASCADE");

            // Composite unique index
            table.index(["post_id", "tag_id"]);
        });
    }

    public function down() {
        schema.drop("post_tags");
    }
}
```

## Anti-Patterns

### Editing Old Migrations

**Bad:**
```cfml
// Editing existing migration that's already run
// 20251105120000_CreateUsersTable.cfc
public function up() {
    schema.create("users", function(table) {
        table.id();
        table.string("email");
        table.string("phone");  // Added after migration ran
    });
}
```

**Good:**
```cfml
// Create new migration instead
// 20251105120100_AddPhoneToUsers.cfc
public function up() {
    schema.table("users", function(table) {
        table.string("phone");
    });
}
```

Never edit migrations that have run in production. Create new migrations.

### Missing down() Method

**Bad:**
```cfml
component extends="fuse.orm.Migration" {
    public function up() {
        schema.create("users", function(table) {
            table.id();
        });
    }

    // Missing down() - can't rollback!
}
```

**Good:**
```cfml
component extends="fuse.orm.Migration" {
    public function up() {
        schema.create("users", function(table) {
            table.id();
        });
    }

    public function down() {
        schema.drop("users");
    }
}
```

Always implement reversible down() methods.

### Hardcoded Data

**Bad:**
```cfml
public function up() {
    schema.create("roles", function(table) {
        table.id();
        table.string("name");
    });

    // Don't insert data in migrations
    queryExecute("
        INSERT INTO roles (name) VALUES ('admin'), ('user')
    ", {}, {datasource: variables.datasource});
}
```

**Good:**
```cfml
// Migration creates schema only
public function up() {
    schema.create("roles", function(table) {
        table.id();
        table.string("name");
    });
}

// Use seeder for data
// database/seeders/RoleSeeder.cfc
component extends="fuse.orm.Seeder" {
    public function run() {
        queryExecute("
            INSERT INTO roles (name) VALUES ('admin'), ('user')
        ", {}, {datasource: variables.datasource});
    }
}
```

Use migrations for schema, seeders for data.

### Missing Foreign Key Indexes

**Bad:**
```cfml
public function up() {
    schema.create("posts", function(table) {
        table.id();
        table.bigInteger("user_id").notNull();
        // No index on user_id - slow joins!

        table.foreignKey("user_id").references("users", "id");
    });
}
```

**Good:**
```cfml
public function up() {
    schema.create("posts", function(table) {
        table.id();
        table.bigInteger("user_id").notNull().index();  // Index for performance

        table.foreignKey("user_id").references("users", "id");
    });
}
```

Always index foreign key columns.

### Wrong Order Dependencies

**Bad:**
```cfml
// 20251105120000_CreatePostsTable.cfc - Created first
schema.create("posts", function(table) {
    table.bigInteger("user_id");
    table.foreignKey("user_id").references("users", "id");  // users doesn't exist yet!
});

// 20251105120100_CreateUsersTable.cfc - Created second
schema.create("users", function(table) {
    table.id();
});
```

**Good:**
```cfml
// 20251105120000_CreateUsersTable.cfc - Created first
schema.create("users", function(table) {
    table.id();
});

// 20251105120100_CreatePostsTable.cfc - Created second
schema.create("posts", function(table) {
    table.bigInteger("user_id");
    table.foreignKey("user_id").references("users", "id");  // users exists now
});
```

Create referenced tables before tables with foreign keys.

## Example: Complete Migration Set

```cfml
// 20251105120000_CreateUsersTable.cfc
component extends="fuse.orm.Migration" {
    public function up() {
        schema.create("users", function(table) {
            table.id();
            table.string("email", 255).notNull().unique();
            table.string("name", 100).notNull();
            table.string("password", 255).notNull();
            table.boolean("active").default(1);
            table.timestamps();

            table.index("email");
        });
    }

    public function down() {
        schema.drop("users");
    }
}

// 20251105120100_CreatePostsTable.cfc
component extends="fuse.orm.Migration" {
    public function up() {
        schema.create("posts", function(table) {
            table.id();
            table.bigInteger("user_id").notNull();
            table.string("title", 200).notNull();
            table.text("body").notNull();
            table.string("status", 20).default("draft");
            table.integer("view_count").default(0);
            table.datetime("published_at");
            table.timestamps();

            table.foreignKey("user_id")
                .references("users", "id")
                .onDelete("CASCADE");

            table.index("user_id");
            table.index("status");
            table.index(["user_id", "status"]);
        });
    }

    public function down() {
        schema.drop("posts");
    }
}

// 20251105120200_CreateCommentsTable.cfc
component extends="fuse.orm.Migration" {
    public function up() {
        schema.create("comments", function(table) {
            table.id();
            table.bigInteger("post_id").notNull();
            table.bigInteger("user_id").notNull();
            table.text("body").notNull();
            table.boolean("approved").default(0);
            table.timestamps();

            table.foreignKey("post_id")
                .references("posts", "id")
                .onDelete("CASCADE");

            table.foreignKey("user_id")
                .references("users", "id")
                .onDelete("CASCADE");

            table.index("post_id");
            table.index("user_id");
        });
    }

    public function down() {
        schema.drop("comments");
    }
}
```

## Common Errors

### Migration Already Ran

**Error:** Migration skipped when trying to run it again.

**Cause:** Migration already executed and recorded in migrations table.

```bash
$ lucli migrate
# No pending migrations (migration already ran)
```

**Solution:** Rollback first if need to re-run, or create new migration:

```bash
# Option 1: Rollback and re-run
lucli rollback
lucli migrate

# Option 2: Create new migration for changes
lucli generate migration AddEmailToUsers email:string
```

Never edit already-run migrations in production.

### Column Type Mismatch

**Error:** Database error when creating column with incompatible type.

**Cause:** Using wrong column type for data.

```cfml
// Wrong: Storing large text in string
table.string("description");  // Limited to 255 chars
```

**Solution:** Use appropriate column type:

```cfml
table.text("description");  // For large text
table.integer("age");       // For numbers
table.boolean("active");    // For true/false
table.datetime("published_at");  // For timestamps
```

See [Column Types](#column-types) section.

### Rollback Method Missing or Incomplete

**Error:** Cannot rollback migration - down() method empty or missing.

**Cause:** Forgot to implement down() method.

```cfml
function down() {
    // Empty! Can't rollback
}
```

**Solution:** Implement reverse operation in down():

```cfml
function up() {
    schema.create("users", function(table) {
        table.id();
        table.string("name");
    });
}

function down() {
    schema.drop("users");  // Reverse of create
}
```

### Foreign Key Constraint Violation

**Error:** Migration fails when adding foreign key to existing data.

**Cause:** Existing rows have invalid foreign key values.

```cfml
// Fails if posts.user_id contains IDs not in users table
table.foreign("user_id")
    .references("id").on("users");
```

**Solution:** Clean up data first or make nullable:

```cfml
// Option 1: Make nullable during transition
table.integer("user_id").nullable();
table.foreign("user_id").references("id").on("users");

// Option 2: Clean up data in migration
queryExecute("DELETE FROM posts WHERE user_id NOT IN (SELECT id FROM users)");
```

### Migration Order Issues

**Error:** Migration fails because it depends on table that doesn't exist yet.

**Cause:** Migrations run alphabetically - dependent migration runs before prerequisite.

```cfml
// 20251106120000_CreatePosts.cfc
// References users table, but...

// 20251106130000_CreateUsers.cfc
// ...users created AFTER posts (wrong order)
```

**Solution:** Ensure timestamp order matches dependency order:

```bash
# Create prerequisite tables first
lucli generate migration CreateUsers     # Gets earlier timestamp
lucli generate migration CreatePosts     # Gets later timestamp

# Or manually adjust timestamps in filenames if needed
```

## API Reference

For detailed migration schema builder methods:

- [Schema Builder API](../reference/api-reference.md#querybuilder) - Column types, modifiers, indexes, foreign keys
- [Migration Commands](../reference/cli-reference.md#migrations) - lucli migrate, rollback, status

## Related Topics

- [Models & ORM](models-orm.md) - Use migrations to create model tables
- [CLI Reference](../reference/cli-reference.md) - Migration command details
- [Database Seeders](../advanced/seeders.md) - Populate tables with data
