/**
 * JoinStrategy - Executes eager loading using LEFT JOIN
 *
 * Used for belongsTo and hasOne relationships where JOIN doesn't cause row duplication.
 * Builds LEFT JOIN clause using existing QueryBuilder.leftJoin() method and handles
 * column prefixing to avoid naming collisions.
 *
 * USAGE EXAMPLE:
 *
 * Load belongsTo relationship:
 *     var strategy = new fuse.orm.strategies.JoinStrategy();
 *     var qb = Post::select("posts.*");
 *     var config = {
 *         type: "belongsTo",
 *         foreignKey: "user_id",
 *         className: "User",
 *         relatedTable: "users"
 *     };
 *     strategy.execute(qb, config, "user");
 *     // Adds: LEFT OUTER JOIN users ON users.id = posts.user_id
 *
 * Load hasOne relationship:
 *     var strategy = new fuse.orm.strategies.JoinStrategy();
 *     var qb = User::select("users.*");
 *     var config = {
 *         type: "hasOne",
 *         foreignKey: "user_id",
 *         className: "Profile",
 *         relatedTable: "profiles"
 *     };
 *     strategy.execute(qb, config, "profile");
 *     // Adds: LEFT OUTER JOIN profiles ON profiles.user_id = users.id
 */
component {

	/**
	 * Execute JOIN strategy for eager loading
	 *
	 * @param queryBuilder QueryBuilder instance to add JOIN to
	 * @param relationshipConfig Struct with type, foreignKey, className, relatedTable
	 * @param relationshipName Name of the relationship being loaded
	 * @return QueryBuilder instance with JOIN clause added
	 */
	public function execute(
		required any queryBuilder,
		required struct relationshipConfig,
		required string relationshipName
	) {
		var type = arguments.relationshipConfig.type;
		var foreignKey = arguments.relationshipConfig.foreignKey;
		var relatedTable = arguments.relationshipConfig.relatedTable;

		// Get primary table name from queryBuilder
		var qbScope = arguments.queryBuilder.getVariablesScope();
		var primaryTable = qbScope.tableName;

		// Build join condition based on relationship type
		var joinCondition = "";

		if (type == "belongsTo") {
			// belongsTo: primary_table.foreign_key = related_table.id
			// Example: posts.user_id = users.id
			joinCondition = "#relatedTable#.id = #primaryTable#.#foreignKey#";
		} else if (type == "hasOne") {
			// hasOne: related_table.foreign_key = primary_table.id
			// Example: profiles.user_id = users.id
			joinCondition = "#relatedTable#.#foreignKey# = #primaryTable#.id";
		}

		// Add LEFT JOIN to query builder
		arguments.queryBuilder.leftJoin(relatedTable, joinCondition);

		// Select columns from related table with prefix to avoid collisions
		// Format: related_table.column AS related_table__column
		var relatedColumns = getTableColumns(relatedTable, qbScope.datasource);
		for (var column in relatedColumns) {
			arguments.queryBuilder.select("#relatedTable#.#column# AS #relatedTable#__#column#");
		}

		return arguments.queryBuilder;
	}

	/**
	 * Get columns for a table from database schema
	 *
	 * @param tableName Name of the table
	 * @param datasource Datasource name
	 * @return Array of column names
	 */
	private array function getTableColumns(required string tableName, required string datasource) {
		try {
			var result = queryExecute(
				"SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ? ORDER BY ORDINAL_POSITION",
				[arguments.tableName],
				{datasource: arguments.datasource}
			);

			var columns = [];
			for (var row in result) {
				arrayAppend(columns, row.COLUMN_NAME);
			}

			return columns;
		} catch (any e) {
			// If schema query fails, return common columns
			return ["id"];
		}
	}

}
