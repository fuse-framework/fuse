/**
 * SchemaBuilder - Fluent interface for database schema operations
 *
 * Provides methods for creating, modifying, and dropping tables:
 * - Table creation with callbacks
 * - Table modifications
 * - Table deletion and renaming
 *
 * USAGE EXAMPLES:
 *
 * Create a new table:
 *     var schema = new fuse.orm.SchemaBuilder("myDatasource");
 *     schema.create("users", function(table) {
 *         table.id();
 *         table.string("email").notNull().unique();
 *         table.string("name");
 *         table.timestamps();
 *     });
 *
 * Modify existing table:
 *     schema.table("users", function(table) {
 *         table.string("phone");
 *         table.index("email");
 *     });
 *
 * Drop table:
 *     schema.drop("users");
 *     schema.dropIfExists("temp_table");
 *
 * Rename table:
 *     schema.rename("old_name", "new_name");
 *
 * Pattern:
 *     All operations execute immediately via queryExecute().
 *     Callbacks receive TableBuilder instance for defining structure.
 */
component {

	/**
	 * Initialize SchemaBuilder
	 *
	 * @datasource Datasource name for query execution
	 * @return SchemaBuilder instance
	 */
	public function init(required string datasource) {
		variables.datasource = arguments.datasource;
		return this;
	}

	/**
	 * Create new table with callback
	 *
	 * @tableName Table name to create
	 * @callback Function receiving TableBuilder instance
	 */
	public function create(required string tableName, required function callback) {
		var table = new fuse.orm.TableBuilder(arguments.tableName, variables.datasource, "create");

		// Invoke callback with table builder
		arguments.callback(table);

		// Generate and execute SQL
		var sql = table.toSQL();
		executeSQL(sql);
	}

	/**
	 * Create table if it doesn't exist
	 *
	 * @tableName Table name to create
	 * @callback Function receiving TableBuilder instance
	 */
	public function createIfNotExists(required string tableName, required function callback) {
		var table = new fuse.orm.TableBuilder(arguments.tableName, variables.datasource, "create");

		// Invoke callback with table builder
		arguments.callback(table);

		// Generate SQL and add IF NOT EXISTS
		var sql = table.toSQL();
		sql = replace(sql, "CREATE TABLE", "CREATE TABLE IF NOT EXISTS", "one");
		executeSQL(sql);
	}

	/**
	 * Modify existing table with callback
	 *
	 * @tableName Table name to modify
	 * @callback Function receiving TableBuilder instance
	 */
	public function table(required string tableName, required function callback) {
		var table = new fuse.orm.TableBuilder(arguments.tableName, variables.datasource, "alter");

		// Invoke callback with table builder
		arguments.callback(table);

		// Generate and execute SQL
		var sql = table.toSQL();
		executeSQL(sql);
	}

	/**
	 * Drop table unconditionally
	 *
	 * @tableName Table name to drop
	 */
	public function drop(required string tableName) {
		var sql = "DROP TABLE " & arguments.tableName;
		executeSQL(sql);
	}

	/**
	 * Drop table if it exists
	 *
	 * @tableName Table name to drop
	 */
	public function dropIfExists(required string tableName) {
		var sql = "DROP TABLE IF EXISTS " & arguments.tableName;
		executeSQL(sql);
	}

	/**
	 * Rename table
	 *
	 * @oldName Current table name
	 * @newName New table name
	 */
	public function rename(required string oldName, required string newName) {
		var sql = "ALTER TABLE " & arguments.oldName & " RENAME TO " & arguments.newName;
		executeSQL(sql);
	}

	// Private methods

	/**
	 * Execute SQL statement(s)
	 *
	 * @sql SQL statement or multiple statements separated by semicolons
	 */
	private function executeSQL(required string sql) {
		// Split on semicolons for multiple statements
		var statements = listToArray(arguments.sql, ";");

		for (var statement in statements) {
			var trimmed = trim(statement);
			if (len(trimmed) > 0) {
				try {
					queryExecute(
						trimmed,
						{},
						{datasource: variables.datasource}
					);
				} catch (any e) {
					// Re-throw with more context
					throw(
						type = "Schema.ExecutionError",
						message = "Failed to execute DDL statement",
						detail = "SQL: #trimmed#. Original error: #e.message#"
					);
				}
			}
		}
	}

}
