/**
 * TableBuilder - Fluent interface for defining table structure
 *
 * Provides methods for defining columns, indexes, and foreign keys:
 * - 11 column type methods (id, string, text, integer, etc.)
 * - Timestamps helper for created_at/updated_at
 * - Index operations
 * - Foreign key constraints
 *
 * USAGE EXAMPLES:
 *
 * Create table with columns:
 *     var table = new fuse.orm.TableBuilder("users", "myDatasource", "create");
 *     table.id();
 *     table.string("email").notNull().unique();
 *     table.timestamps();
 *     var sql = table.toSQL(); // Returns CREATE TABLE statement
 *
 * Add columns to existing table:
 *     var table = new fuse.orm.TableBuilder("users", "myDatasource", "alter");
 *     table.string("phone");
 *     var sql = table.toSQL(); // Returns ALTER TABLE ADD COLUMN statement
 *
 * Method chaining pattern:
 *     Column type methods return ColumnBuilder for chaining modifiers.
 *     Terminal method toSQL() generates the full DDL statement.
 */
component {

	/**
	 * Initialize TableBuilder
	 *
	 * @tableName Table name
	 * @datasource Datasource name for query execution
	 * @mode Operation mode: "create" or "alter"
	 * @return TableBuilder instance
	 */
	public function init(required string tableName, required string datasource, required string mode) {
		// Validate table name
		if (!isValidIdentifier(arguments.tableName)) {
			throw(
				type = "Schema.InvalidDefinition",
				message = "Invalid table name",
				detail = "Table name '#arguments.tableName#' contains invalid characters. Use only alphanumeric characters and underscores."
			);
		}

		variables.tableName = arguments.tableName;
		variables.datasource = arguments.datasource;
		variables.mode = arguments.mode;

		// Initialize tracking arrays
		variables.columns = [];
		variables.indexes = [];
		variables.foreignKeys = [];

		return this;
	}

	/**
	 * Add primary key column (BIGINT UNSIGNED AUTO_INCREMENT)
	 *
	 * @return ColumnBuilder instance for chaining
	 */
	public function id() {
		var column = new fuse.orm.ColumnBuilder("id", "BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY", variables.datasource);
		arrayAppend(variables.columns, column);
		return column;
	}

	/**
	 * Add VARCHAR column
	 *
	 * @name Column name
	 * @length Maximum length (default 255)
	 * @return ColumnBuilder instance for chaining
	 */
	public function string(required string name, numeric length = 255) {
		validateColumnName(arguments.name);
		var column = new fuse.orm.ColumnBuilder(arguments.name, "VARCHAR(#arguments.length#)", variables.datasource);
		arrayAppend(variables.columns, column);
		return column;
	}

	/**
	 * Add TEXT column
	 *
	 * @name Column name
	 * @return ColumnBuilder instance for chaining
	 */
	public function text(required string name) {
		validateColumnName(arguments.name);
		var column = new fuse.orm.ColumnBuilder(arguments.name, "TEXT", variables.datasource);
		arrayAppend(variables.columns, column);
		return column;
	}

	/**
	 * Add INT column
	 *
	 * @name Column name
	 * @return ColumnBuilder instance for chaining
	 */
	public function integer(required string name) {
		validateColumnName(arguments.name);
		var column = new fuse.orm.ColumnBuilder(arguments.name, "INT", variables.datasource);
		arrayAppend(variables.columns, column);
		return column;
	}

	/**
	 * Add BIGINT column
	 *
	 * @name Column name
	 * @return ColumnBuilder instance for chaining
	 */
	public function bigInteger(required string name) {
		validateColumnName(arguments.name);
		var column = new fuse.orm.ColumnBuilder(arguments.name, "BIGINT", variables.datasource);
		arrayAppend(variables.columns, column);
		return column;
	}

	/**
	 * Add BOOLEAN column
	 *
	 * @name Column name
	 * @return ColumnBuilder instance for chaining
	 */
	public function boolean(required string name) {
		validateColumnName(arguments.name);
		var column = new fuse.orm.ColumnBuilder(arguments.name, "BOOLEAN", variables.datasource);
		arrayAppend(variables.columns, column);
		return column;
	}

	/**
	 * Add DECIMAL column
	 *
	 * @name Column name
	 * @precision Total number of digits (default 10)
	 * @scale Decimal places (default 2)
	 * @return ColumnBuilder instance for chaining
	 */
	public function decimal(required string name, numeric precision = 10, numeric scale = 2) {
		validateColumnName(arguments.name);
		var column = new fuse.orm.ColumnBuilder(arguments.name, "DECIMAL(#arguments.precision#,#arguments.scale#)", variables.datasource);
		arrayAppend(variables.columns, column);
		return column;
	}

	/**
	 * Add DATETIME column
	 *
	 * @name Column name
	 * @return ColumnBuilder instance for chaining
	 */
	public function datetime(required string name) {
		validateColumnName(arguments.name);
		var column = new fuse.orm.ColumnBuilder(arguments.name, "DATETIME", variables.datasource);
		arrayAppend(variables.columns, column);
		return column;
	}

	/**
	 * Add DATE column
	 *
	 * @name Column name
	 * @return ColumnBuilder instance for chaining
	 */
	public function date(required string name) {
		validateColumnName(arguments.name);
		var column = new fuse.orm.ColumnBuilder(arguments.name, "DATE", variables.datasource);
		arrayAppend(variables.columns, column);
		return column;
	}

	/**
	 * Add TIME column
	 *
	 * @name Column name
	 * @return ColumnBuilder instance for chaining
	 */
	public function time(required string name) {
		validateColumnName(arguments.name);
		var column = new fuse.orm.ColumnBuilder(arguments.name, "TIME", variables.datasource);
		arrayAppend(variables.columns, column);
		return column;
	}

	/**
	 * Add JSON column
	 *
	 * @name Column name
	 * @return ColumnBuilder instance for chaining
	 */
	public function json(required string name) {
		validateColumnName(arguments.name);
		var column = new fuse.orm.ColumnBuilder(arguments.name, "JSON", variables.datasource);
		arrayAppend(variables.columns, column);
		return column;
	}

	/**
	 * Add created_at and updated_at timestamp columns
	 */
	public function timestamps() {
		// created_at with DEFAULT CURRENT_TIMESTAMP
		var createdAt = new fuse.orm.ColumnBuilder("created_at", "DATETIME DEFAULT CURRENT_TIMESTAMP", variables.datasource);
		arrayAppend(variables.columns, createdAt);

		// updated_at with DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
		var updatedAt = new fuse.orm.ColumnBuilder("updated_at", "DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP", variables.datasource);
		arrayAppend(variables.columns, updatedAt);
	}

	/**
	 * Add index on column(s)
	 *
	 * @columns String column name or array of column names
	 */
	public function index(required columns) {
		var columnArray = isArray(arguments.columns) ? arguments.columns : [arguments.columns];

		// Generate index name: idx_{tablename}_{column1}_{column2}
		var indexName = "idx_" & variables.tableName & "_" & arrayToList(columnArray, "_");

		arrayAppend(variables.indexes, {
			name: indexName,
			columns: columnArray
		});
	}

	/**
	 * Start foreign key definition
	 *
	 * @column Column name for foreign key
	 * @return ForeignKeyBuilder instance for chaining
	 */
	public function foreignKey(required string column) {
		validateColumnName(arguments.column);
		var fkBuilder = new fuse.orm.ForeignKeyBuilder(arguments.column, variables.tableName);
		arrayAppend(variables.foreignKeys, fkBuilder);
		return fkBuilder;
	}

	/**
	 * Generate DDL SQL statement
	 *
	 * @return String SQL statement
	 */
	public string function toSQL() {
		if (variables.mode == "create") {
			return generateCreateStatement();
		} else {
			return generateAlterStatement();
		}
	}

	/**
	 * Get columns array for testing
	 *
	 * @return Array of ColumnBuilder instances
	 */
	public array function getColumns() {
		return variables.columns;
	}

	// Private methods

	/**
	 * Validate identifier (table/column name)
	 *
	 * @name Identifier to validate
	 * @return Boolean true if valid
	 */
	private boolean function isValidIdentifier(required string name) {
		// Allow alphanumeric and underscore only
		return reFind("^[a-zA-Z0-9_]+$", arguments.name) > 0;
	}

	/**
	 * Validate column name and throw on error
	 *
	 * @name Column name to validate
	 */
	private function validateColumnName(required string name) {
		if (!isValidIdentifier(arguments.name)) {
			throw(
				type = "Schema.InvalidDefinition",
				message = "Invalid column name",
				detail = "Column name '#arguments.name#' contains invalid characters. Use only alphanumeric characters and underscores."
			);
		}
	}

	/**
	 * Generate CREATE TABLE statement
	 *
	 * @return String CREATE TABLE SQL
	 */
	private string function generateCreateStatement() {
		var sql = ["CREATE TABLE " & variables.tableName & " ("];
		var parts = [];

		// Add columns
		for (var column in variables.columns) {
			arrayAppend(parts, column.toSQL());
		}

		// Add foreign keys
		for (var fk in variables.foreignKeys) {
			arrayAppend(parts, fk.toSQL());
		}

		arrayAppend(sql, arrayToList(parts, ", "));
		arrayAppend(sql, ")");

		var result = arrayToList(sql, "");

		// Add indexes after table creation
		for (var idx in variables.indexes) {
			result &= "; CREATE INDEX " & idx.name & " ON " & variables.tableName & " (" & arrayToList(idx.columns, ", ") & ")";
		}

		// Also check for column-level indexes
		for (var column in variables.columns) {
			if (column.hasIndex()) {
				var indexName = "idx_" & variables.tableName & "_" & column.getName();
				result &= "; CREATE INDEX " & indexName & " ON " & variables.tableName & " (" & column.getName() & ")";
			}
		}

		return result;
	}

	/**
	 * Generate ALTER TABLE ADD COLUMN statement(s)
	 *
	 * @return String ALTER TABLE SQL
	 */
	private string function generateAlterStatement() {
		var statements = [];

		// Add columns
		for (var column in variables.columns) {
			arrayAppend(statements, "ALTER TABLE " & variables.tableName & " ADD COLUMN " & column.toSQL());
		}

		// Add indexes
		for (var idx in variables.indexes) {
			arrayAppend(statements, "CREATE INDEX " & idx.name & " ON " & variables.tableName & " (" & arrayToList(idx.columns, ", ") & ")");
		}

		// Add column-level indexes
		for (var column in variables.columns) {
			if (column.hasIndex()) {
				var indexName = "idx_" & variables.tableName & "_" & column.getName();
				arrayAppend(statements, "CREATE INDEX " & indexName & " ON " & variables.tableName & " (" & column.getName() & ")");
			}
		}

		// Add foreign keys
		for (var fk in variables.foreignKeys) {
			arrayAppend(statements, "ALTER TABLE " & variables.tableName & " ADD " & fk.toSQL());
		}

		return arrayToList(statements, "; ");
	}

}
