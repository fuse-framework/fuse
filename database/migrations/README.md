# Database Migrations

Place migration files in this directory using the naming convention:

```
YYYYMMDDHHMMSS_DescriptiveName.cfc
```

Example: `20251105143000_CreateUsersTable.cfc`

## Migration File Template

```cfm
component extends="fuse.orm.Migration" {

	function up() {
		schema.create("table_name", function(table) {
			table.id();
			table.string("name");
			table.timestamps();
		});
	}

	function down() {
		schema.drop("table_name");
	}

}
```

## Running Migrations

```cfm
migrator = new fuse.orm.Migrator(application.datasource);
migrator.migrate();        // Run pending migrations
migrator.rollback();       // Rollback last migration
migrator.rollback(3);      // Rollback last 3 migrations
migrator.status();         // Check migration status
migrator.reset();          // Rollback all migrations
migrator.refresh();        // Reset and re-run all migrations
```
