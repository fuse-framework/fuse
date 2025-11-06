/**
 * ForeignKeyBuilder - Fluent interface for foreign key constraints
 *
 * Provides methods for defining foreign key relationships with cascade actions.
 *
 * USAGE EXAMPLES:
 *
 * Basic foreign key:
 *     var fk = new fuse.orm.ForeignKeyBuilder("user_id", "posts");
 *     fk.references("users", "id");
 *     var sql = fk.toSQL(); // Returns CONSTRAINT SQL
 *
 * Foreign key with cascade:
 *     var fk = new fuse.orm.ForeignKeyBuilder("user_id", "posts");
 *     fk.references("users", "id").onDelete("CASCADE").onUpdate("CASCADE");
 *     var sql = fk.toSQL();
 */
component {

	/**
	 * Initialize ForeignKeyBuilder
	 *
	 * @column Column name for foreign key
	 * @tableName Table name containing the foreign key
	 * @return ForeignKeyBuilder instance
	 */
	public function init(required string column, required string tableName) {
		variables.column = arguments.column;
		variables.tableName = arguments.tableName;
		variables.refTable = "";
		variables.refColumn = "";
		variables.onDeleteAction = "RESTRICT";
		variables.onUpdateAction = "RESTRICT";
		variables.validActions = ["CASCADE", "RESTRICT", "SET NULL", "NO ACTION"];
		return this;
	}

	/**
	 * Set reference table and column
	 *
	 * @table Reference table name
	 * @column Reference column name
	 * @return ForeignKeyBuilder instance for chaining
	 */
	public function references(required string table, required string column) {
		variables.refTable = arguments.table;
		variables.refColumn = arguments.column;
		return this;
	}

	/**
	 * Set ON DELETE action
	 *
	 * @action Action: CASCADE, RESTRICT, SET NULL, NO ACTION
	 * @return ForeignKeyBuilder instance for chaining
	 */
	public function onDelete(required string action) {
		var upperAction = ucase(arguments.action);
		if (!arrayFindNoCase(variables.validActions, upperAction)) {
			throw(
				type = "Schema.InvalidDefinition",
				message = "Invalid ON DELETE action",
				detail = "Action '#arguments.action#' is not valid. Valid actions are: #arrayToList(variables.validActions, ', ')#"
			);
		}
		variables.onDeleteAction = upperAction;
		return this;
	}

	/**
	 * Set ON UPDATE action
	 *
	 * @action Action: CASCADE, RESTRICT, SET NULL, NO ACTION
	 * @return ForeignKeyBuilder instance for chaining
	 */
	public function onUpdate(required string action) {
		var upperAction = ucase(arguments.action);
		if (!arrayFindNoCase(variables.validActions, upperAction)) {
			throw(
				type = "Schema.InvalidDefinition",
				message = "Invalid ON UPDATE action",
				detail = "Action '#arguments.action#' is not valid. Valid actions are: #arrayToList(variables.validActions, ', ')#"
			);
		}
		variables.onUpdateAction = upperAction;
		return this;
	}

	/**
	 * Generate CONSTRAINT SQL
	 *
	 * @return String CONSTRAINT SQL
	 */
	public string function toSQL() {
		// Validate that references() was called
		if (len(variables.refTable) == 0 || len(variables.refColumn) == 0) {
			throw(
				type = "Schema.InvalidDefinition",
				message = "Foreign key reference not defined",
				detail = "You must call references(table, column) before generating SQL for foreign key '#variables.column#'"
			);
		}

		var constraintName = "fk_" & variables.tableName & "_" & variables.column;

		return "CONSTRAINT " & constraintName & " FOREIGN KEY (" & variables.column & ") " &
		       "REFERENCES " & variables.refTable & "(" & variables.refColumn & ") " &
		       "ON DELETE " & variables.onDeleteAction & " " &
		       "ON UPDATE " & variables.onUpdateAction;
	}

}
