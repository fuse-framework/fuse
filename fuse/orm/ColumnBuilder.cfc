/**
 * ColumnBuilder - Fluent interface for building column definitions
 *
 * Provides a fluent interface for chaining column modifiers:
 * - NOT NULL constraint
 * - UNIQUE constraint
 * - DEFAULT values
 * - INDEX flag
 *
 * USAGE EXAMPLES:
 *
 * Basic column with constraints:
 *     var column = new fuse.orm.ColumnBuilder("email", "VARCHAR(255)", "myDatasource");
 *     column.notNull().unique().index();
 *     var sql = column.toSQL(); // "email VARCHAR(255) NOT NULL UNIQUE"
 *
 * Column with default value:
 *     var column = new fuse.orm.ColumnBuilder("status", "VARCHAR(50)", "myDatasource");
 *     column.notNull().default("active");
 *     var sql = column.toSQL(); // "status VARCHAR(50) NOT NULL DEFAULT 'active'"
 *
 * Method chaining pattern:
 *     All modifier methods (notNull, unique, default, index) return `this` for chaining.
 *     Terminal method toSQL() generates the SQL fragment for the column.
 */
component {

	/**
	 * Initialize ColumnBuilder
	 *
	 * @name Column name
	 * @type Column type (e.g., VARCHAR(255), INT, BIGINT)
	 * @datasource Datasource name for query execution
	 * @return ColumnBuilder instance for chaining
	 */
	public function init(required string name, required string type, required string datasource) {
		variables.datasource = arguments.datasource;
		variables.name = arguments.name;
		variables.type = arguments.type;

		// Initialize constraint flags
		variables.isNotNull = false;
		variables.isUnique = false;
		variables.hasDefault = false;
		variables.defaultValue = "";
		variables.hasIndex = false;

		return this;
	}

	/**
	 * Add NOT NULL constraint
	 *
	 * @return ColumnBuilder instance for chaining
	 */
	public function notNull() {
		variables.isNotNull = true;
		return this;
	}

	/**
	 * Add UNIQUE constraint
	 *
	 * @return ColumnBuilder instance for chaining
	 */
	public function unique() {
		variables.isUnique = true;
		return this;
	}

	/**
	 * Set DEFAULT value
	 *
	 * @value Default value for the column
	 * @return ColumnBuilder instance for chaining
	 */
	public function default(required any value) {
		variables.hasDefault = true;
		variables.defaultValue = arguments.value;
		return this;
	}

	/**
	 * Mark column for index creation
	 *
	 * @return ColumnBuilder instance for chaining
	 */
	public function index() {
		variables.hasIndex = true;
		return this;
	}

	/**
	 * Generate SQL fragment for column definition
	 *
	 * @return String SQL fragment
	 */
	public string function toSQL() {
		var sql = [];

		// Column name and type
		arrayAppend(sql, variables.name & " " & variables.type);

		// NOT NULL constraint
		if (variables.isNotNull) {
			arrayAppend(sql, "NOT NULL");
		}

		// UNIQUE constraint
		if (variables.isUnique) {
			arrayAppend(sql, "UNIQUE");
		}

		// DEFAULT value
		if (variables.hasDefault) {
			var quotedValue = quoteValue(variables.defaultValue);
			arrayAppend(sql, "DEFAULT " & quotedValue);
		}

		return arrayToList(sql, " ");
	}

	/**
	 * Get column name
	 *
	 * @return String column name
	 */
	public string function getName() {
		return variables.name;
	}

	/**
	 * Check if column should have index
	 *
	 * @return Boolean true if index flag is set
	 */
	public boolean function hasIndex() {
		return variables.hasIndex;
	}

	// Private methods

	/**
	 * Quote value for SQL based on type
	 *
	 * @value Value to quote
	 * @return String quoted value
	 */
	private string function quoteValue(required any value) {
		// Numeric values don't need quotes
		if (isNumeric(arguments.value)) {
			return arguments.value;
		}

		// Boolean values
		if (isBoolean(arguments.value)) {
			return arguments.value ? "1" : "0";
		}

		// String values need single quotes
		// Escape single quotes by doubling them
		var escaped = replace(arguments.value, "'", "''", "all");
		return "'" & escaped & "'";
	}

}
