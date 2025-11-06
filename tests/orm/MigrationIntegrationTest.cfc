component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Migration integration tests", function() {

			beforeEach(function() {
				variables.testDatasource = "test_fuse";

				// Clean up test tables
				try {
					queryExecute("DROP TABLE IF EXISTS test_users", {}, {datasource: variables.testDatasource});
					queryExecute("DROP TABLE IF EXISTS test_posts", {}, {datasource: variables.testDatasource});
					queryExecute("DROP TABLE IF EXISTS schema_migrations", {}, {datasource: variables.testDatasource});
				} catch (any e) {
					// Ignore errors on cleanup
				}
			});

			afterEach(function() {
				// Clean up test tables
				try {
					queryExecute("DROP TABLE IF EXISTS test_users", {}, {datasource: variables.testDatasource});
					queryExecute("DROP TABLE IF EXISTS test_posts", {}, {datasource: variables.testDatasource});
					queryExecute("DROP TABLE IF EXISTS schema_migrations", {}, {datasource: variables.testDatasource});
				} catch (any e) {
					// Ignore errors on cleanup
				}
			});

			it("should create table with all column types", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				schema.create("test_users", function(table) {
					table.id();
					table.string("name");
					table.string("email", 100);
					table.text("bio");
					table.integer("age");
					table.bigInteger("views");
					table.boolean("active");
					table.decimal("balance", 10, 2);
					table.datetime("last_login");
					table.date("birth_date");
					table.time("preferred_time");
					table.json("metadata");
					table.timestamps();
				});

				// Verify table exists and has columns
				var result = queryExecute(
					"SHOW COLUMNS FROM test_users",
					{},
					{datasource: variables.testDatasource}
				);

				expect(result.recordCount).toBeGT(10);
			});

			it("should create table with indexes", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				schema.create("test_users", function(table) {
					table.id();
					table.string("email").unique().index();
					table.string("username");
					table.index("username");
				});

				// Verify indexes exist
				var result = queryExecute(
					"SHOW INDEX FROM test_users",
					{},
					{datasource: variables.testDatasource}
				);

				expect(result.recordCount).toBeGT(0);
			});

			it("should create table with foreign keys", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				// Create parent table first
				schema.create("test_users", function(table) {
					table.id();
					table.string("name");
				});

				// Create child table with foreign key
				schema.create("test_posts", function(table) {
					table.id();
					table.bigInteger("user_id");
					table.string("title");
					table.foreignKey("user_id").references("test_users", "id").onDelete("CASCADE");
				});

				// Verify foreign key exists
				var result = queryExecute(
					"SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE TABLE_NAME = 'test_posts' AND REFERENCED_TABLE_NAME = 'test_users'",
					{},
					{datasource: variables.testDatasource}
				);

				expect(result.recordCount).toBe(1);
			});

			it("should modify existing table with ALTER", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				// Create table
				schema.create("test_users", function(table) {
					table.id();
					table.string("name");
				});

				// Modify table
				schema.table("test_users", function(table) {
					table.string("email");
				});

				// Verify new column exists
				var result = queryExecute(
					"SHOW COLUMNS FROM test_users WHERE Field = 'email'",
					{},
					{datasource: variables.testDatasource}
				);

				expect(result.recordCount).toBe(1);
			});

			it("should drop table successfully", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				// Create table
				schema.create("test_users", function(table) {
					table.id();
				});

				// Drop table
				schema.drop("test_users");

				// Verify table doesn't exist
				expect(function() {
					queryExecute("SELECT * FROM test_users", {}, {datasource: variables.testDatasource});
				}).toThrow();
			});

			it("should rename table successfully", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				// Create table
				schema.create("test_users", function(table) {
					table.id();
				});

				// Rename table
				schema.rename("test_users", "test_members");

				// Verify new name exists
				var result = queryExecute(
					"SELECT * FROM test_members",
					{},
					{datasource: variables.testDatasource}
				);

				expect(result).toBeQuery();

				// Clean up renamed table
				queryExecute("DROP TABLE test_members", {}, {datasource: variables.testDatasource});
			});

			it("should rollback transaction on migration error", function() {
				var migration = new fuse.orm.Migration(variables.testDatasource);

				try {
					transaction {
						migration.schema.create("test_users", function(table) {
							table.id();
							table.string("email");
						});

						// Force an error
						queryExecute("INVALID SQL", {}, {datasource: variables.testDatasource});

						transaction action="commit";
					}
					fail("Should have thrown an error");
				} catch (any e) {
					transaction action="rollback";
				}

				// Verify table wasn't created due to rollback
				expect(function() {
					queryExecute("SELECT * FROM test_users", {}, {datasource: variables.testDatasource});
				}).toThrow();
			});

			it("should track migration versions in schema_migrations", function() {
				var migrator = new fuse.orm.Migrator(variables.testDatasource);

				// Verify schema_migrations table was created
				var result = queryExecute(
					"SHOW TABLES LIKE 'schema_migrations'",
					{},
					{datasource: variables.testDatasource}
				);

				expect(result.recordCount).toBe(1);
			});

		});
	}

}
