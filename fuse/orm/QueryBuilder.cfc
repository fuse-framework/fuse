/**
 * QueryBuilder - Fluent interface for building SQL queries
 *
 * Provides a fluent interface for constructing SQL queries with support for:
 * - Column selection
 * - WHERE conditions with hash-based operators
 * - JOINs (INNER, LEFT OUTER, RIGHT OUTER)
 * - ORDER BY, GROUP BY, HAVING
 * - LIMIT and OFFSET
 * - Raw SQL escapes
 * - Prepared statement support with positional placeholders
 *
 * USAGE EXAMPLES:
 *
 * Basic query:
 *     var qb = new fuse.orm.QueryBuilder("myDatasource");
 *     var results = qb.select("id, name, email")
 *                     .where({active: true})
 *                     .orderBy("name")
 *                     .get("users");
 *
 * Hash-based operators:
 *     var users = qb.where({
 *         age: {gte: 18},              // age >= 18
 *         role: {in: ["admin", "mod"]}, // role IN ('admin', 'mod')
 *         deleted_at: {isNull: true}    // deleted_at IS NULL
 *     }).get("users");
 *
 * Supported hash operators:
 *     gte    - Greater than or equal (>=)
 *     gt     - Greater than (>)
 *     lte    - Less than or equal (<=)
 *     lt     - Less than (<)
 *     ne     - Not equal (<>)
 *     like   - LIKE pattern matching
 *     in     - IN list (requires array)
 *     notIn  - NOT IN list (requires array)
 *     between - BETWEEN range (requires 2-element array)
 *     isNull  - IS NULL check
 *     notNull - IS NOT NULL check
 *
 * Complex queries with joins:
 *     var posts = qb.select("users.name, posts.title, posts.created_at")
 *                   .join("posts", "users.id = posts.user_id")
 *                   .where({
 *                       "users.active": true,
 *                       "posts.status": "published"
 *                   })
 *                   .orderBy("posts.created_at", "DESC")
 *                   .limit(10)
 *                   .get("users");
 *
 * Raw SQL for complex conditions:
 *     var products = qb.where({category: "electronics"})
 *                      .whereRaw("price > cost * 1.5")
 *                      .get("products");
 *
 * Method chaining pattern:
 *     All builder methods (select, where, orderBy, etc.) return `this` for chaining.
 *     Terminal methods (get, first, count) execute the query and return results.
 *
 * Prepared statements:
 *     All values are automatically bound using positional ? placeholders.
 *     Bindings are passed to queryExecute() in the correct order.
 */
component {

	/**
	 * Initialize QueryBuilder
	 *
	 * @datasource Datasource name for query execution
	 * @return QueryBuilder instance for chaining
	 */
	public function init(required string datasource) {
		variables.datasource = arguments.datasource;

		// Initialize internal state arrays
		variables.selectedColumns = [];
		variables.whereClauses = [];
		variables.joinClauses = [];
		variables.orderByClauses = [];
		variables.groupByClauses = [];
		variables.havingClauses = [];
		variables.bindings = [];

		// Initialize limit/offset to 0 (0 means not set)
		variables.limitValue = 0;
		variables.offsetValue = 0;

		return this;
	}

	/**
	 * Select columns for query
	 *
	 * @columns Comma-separated string or array of column names
	 * @return QueryBuilder instance for chaining
	 */
	public function select(required columns) {
		var columnArray = [];

		if (isArray(arguments.columns)) {
			columnArray = arguments.columns;
		} else {
			// Parse comma-separated string
			var parts = listToArray(arguments.columns, ",");
			for (var part in parts) {
				arrayAppend(columnArray, trim(part));
			}
		}

		// Append to existing selections
		for (var col in columnArray) {
			arrayAppend(variables.selectedColumns, col);
		}

		return this;
	}

	/**
	 * Add WHERE conditions with hash-based operators
	 *
	 * @conditions Struct of column/value pairs
	 * @return QueryBuilder instance for chaining
	 */
	public function where(required struct conditions) {
		for (var column in arguments.conditions) {
			var value = arguments.conditions[column];

			// Check if value is operator hash
			if (isStruct(value)) {
				processOperatorHash(column, value);
			} else {
				// Simple equality
				arrayAppend(variables.whereClauses, column & " = ?");
				arrayAppend(variables.bindings, value);
			}
		}

		return this;
	}

	/**
	 * Add raw WHERE condition
	 *
	 * @sql Raw SQL string with ? placeholders
	 * @bindings Optional array of binding values
	 * @return QueryBuilder instance for chaining
	 */
	public function whereRaw(required string sql, array bindings = []) {
		// Wrap in parentheses
		arrayAppend(variables.whereClauses, "(" & arguments.sql & ")");

		// Append bindings
		for (var binding in arguments.bindings) {
			arrayAppend(variables.bindings, binding);
		}

		return this;
	}

	/**
	 * Add INNER JOIN
	 *
	 * @table Table name to join
	 * @condition Join condition (e.g., "users.id = posts.user_id")
	 * @return QueryBuilder instance for chaining
	 */
	public function join(required string table, required string condition) {
		arrayAppend(variables.joinClauses, {
			type: "INNER JOIN",
			table: arguments.table,
			condition: arguments.condition
		});

		return this;
	}

	/**
	 * Add LEFT OUTER JOIN
	 *
	 * @table Table name to join
	 * @condition Join condition
	 * @return QueryBuilder instance for chaining
	 */
	public function leftJoin(required string table, required string condition) {
		arrayAppend(variables.joinClauses, {
			type: "LEFT OUTER JOIN",
			table: arguments.table,
			condition: arguments.condition
		});

		return this;
	}

	/**
	 * Add RIGHT OUTER JOIN
	 *
	 * @table Table name to join
	 * @condition Join condition
	 * @return QueryBuilder instance for chaining
	 */
	public function rightJoin(required string table, required string condition) {
		arrayAppend(variables.joinClauses, {
			type: "RIGHT OUTER JOIN",
			table: arguments.table,
			condition: arguments.condition
		});

		return this;
	}

	/**
	 * Add ORDER BY clause
	 *
	 * @column Column name to sort by
	 * @direction Sort direction (ASC or DESC), defaults to ASC
	 * @return QueryBuilder instance for chaining
	 */
	public function orderBy(required string column, string direction = "ASC") {
		var dir = ucase(trim(arguments.direction));
		arrayAppend(variables.orderByClauses, arguments.column & " " & dir);

		return this;
	}

	/**
	 * Add GROUP BY clause
	 *
	 * @columns Comma-separated string or array of column names
	 * @return QueryBuilder instance for chaining
	 */
	public function groupBy(required columns) {
		var columnArray = [];

		if (isArray(arguments.columns)) {
			columnArray = arguments.columns;
		} else {
			// Parse comma-separated string
			var parts = listToArray(arguments.columns, ",");
			for (var part in parts) {
				arrayAppend(columnArray, trim(part));
			}
		}

		// Append to groupBy clauses
		for (var col in columnArray) {
			arrayAppend(variables.groupByClauses, col);
		}

		return this;
	}

	/**
	 * Add HAVING clause
	 *
	 * @condition Raw SQL condition for HAVING
	 * @return QueryBuilder instance for chaining
	 */
	public function having(required string condition) {
		arrayAppend(variables.havingClauses, arguments.condition);

		return this;
	}

	/**
	 * Set LIMIT
	 *
	 * @count Number of rows to limit
	 * @return QueryBuilder instance for chaining
	 */
	public function limit(required numeric count) {
		if (!isNumeric(arguments.count) || arguments.count < 0) {
			throw(
				type = "QueryBuilder.InvalidValue",
				message = "Limit must be a positive integer",
				detail = "Provided value: #arguments.count#"
			);
		}

		variables.limitValue = arguments.count;

		return this;
	}

	/**
	 * Set OFFSET
	 *
	 * @count Number of rows to offset
	 * @return QueryBuilder instance for chaining
	 */
	public function offset(required numeric count) {
		if (!isNumeric(arguments.count) || arguments.count < 0) {
			throw(
				type = "QueryBuilder.InvalidValue",
				message = "Offset must be a positive integer",
				detail = "Provided value: #arguments.count#"
			);
		}

		variables.offsetValue = arguments.count;

		return this;
	}

	/**
	 * Execute query and return all results
	 *
	 * @tableName Table name for FROM clause
	 * @return Array of structs (one per row)
	 */
	public array function get(required string tableName) {
		var sqlData = toSQL(arguments.tableName);

		var result = queryExecute(
			sqlData.sql,
			sqlData.bindings,
			{datasource: variables.datasource}
		);

		var rows = [];
		for (var row in result) {
			arrayAppend(rows, row);
		}

		return rows;
	}

	/**
	 * Execute query and return first result
	 *
	 * @tableName Table name for FROM clause
	 * @return Struct or null if no results
	 */
	public function first(required string tableName) {
		// Apply LIMIT 1
		var originalLimit = variables.limitValue;
		variables.limitValue = 1;

		var sqlData = toSQL(arguments.tableName);

		// Restore original limit
		variables.limitValue = originalLimit;

		var result = queryExecute(
			sqlData.sql,
			sqlData.bindings,
			{datasource: variables.datasource}
		);

		if (result.recordCount == 0) {
			return null;
		}

		// Return first row as struct
		for (var row in result) {
			return row;
		}
	}

	/**
	 * Execute COUNT(*) query
	 *
	 * @tableName Table name for FROM clause
	 * @return Numeric count
	 */
	public numeric function count(required string tableName) {
		// Save and replace selected columns with COUNT(*)
		var originalColumns = variables.selectedColumns;
		variables.selectedColumns = ["COUNT(*) as count"];

		var sqlData = toSQL(arguments.tableName);

		// Restore original columns
		variables.selectedColumns = originalColumns;

		var result = queryExecute(
			sqlData.sql,
			sqlData.bindings,
			{datasource: variables.datasource}
		);

		if (result.recordCount == 0) {
			return 0;
		}

		return result.count;
	}

	/**
	 * Build SQL string from internal state
	 *
	 * @tableName Table name for FROM clause
	 * @return Struct with sql and bindings keys
	 */
	public struct function toSQL(required string tableName) {
		var sql = [];

		// SELECT clause
		if (arrayLen(variables.selectedColumns) == 0) {
			arrayAppend(sql, "SELECT *");
		} else {
			arrayAppend(sql, "SELECT " & arrayToList(variables.selectedColumns, ", "));
		}

		// FROM clause
		arrayAppend(sql, "FROM " & arguments.tableName);

		// JOIN clauses
		for (var join in variables.joinClauses) {
			arrayAppend(sql, join.type & " " & join.table & " ON " & join.condition);
		}

		// WHERE clause
		if (arrayLen(variables.whereClauses) > 0) {
			arrayAppend(sql, "WHERE " & arrayToList(variables.whereClauses, " AND "));
		}

		// GROUP BY clause
		if (arrayLen(variables.groupByClauses) > 0) {
			arrayAppend(sql, "GROUP BY " & arrayToList(variables.groupByClauses, ", "));
		}

		// HAVING clause
		if (arrayLen(variables.havingClauses) > 0) {
			arrayAppend(sql, "HAVING " & arrayToList(variables.havingClauses, " AND "));
		}

		// ORDER BY clause
		if (arrayLen(variables.orderByClauses) > 0) {
			arrayAppend(sql, "ORDER BY " & arrayToList(variables.orderByClauses, ", "));
		}

		// LIMIT clause (only add if > 0)
		if (variables.limitValue > 0) {
			arrayAppend(sql, "LIMIT " & variables.limitValue);
		}

		// OFFSET clause (only add if > 0)
		if (variables.offsetValue > 0) {
			arrayAppend(sql, "OFFSET " & variables.offsetValue);
		}

		return {
			sql: arrayToList(sql, " "),
			bindings: variables.bindings
		};
	}

	// Private methods

	/**
	 * Process operator hash for WHERE clause
	 *
	 * @column Column name
	 * @operatorHash Struct with single operator key
	 */
	private function processOperatorHash(required string column, required struct operatorHash) {
		var operators = structKeyArray(arguments.operatorHash);

		// Validate exactly one operator
		if (arrayLen(operators) != 1) {
			throw(
				type = "QueryBuilder.InvalidOperator",
				message = "Operator hash must contain exactly one operator",
				detail = "Column '#arguments.column#' has #arrayLen(operators)# operators"
			);
		}

		var operator = operators[1];
		var value = arguments.operatorHash[operator];

		switch (lcase(operator)) {
			case "gte":
				arrayAppend(variables.whereClauses, arguments.column & " >= ?");
				arrayAppend(variables.bindings, value);
				break;
			case "gt":
				arrayAppend(variables.whereClauses, arguments.column & " > ?");
				arrayAppend(variables.bindings, value);
				break;
			case "lte":
				arrayAppend(variables.whereClauses, arguments.column & " <= ?");
				arrayAppend(variables.bindings, value);
				break;
			case "lt":
				arrayAppend(variables.whereClauses, arguments.column & " < ?");
				arrayAppend(variables.bindings, value);
				break;
			case "ne":
				arrayAppend(variables.whereClauses, arguments.column & " <> ?");
				arrayAppend(variables.bindings, value);
				break;
			case "like":
				arrayAppend(variables.whereClauses, arguments.column & " LIKE ?");
				arrayAppend(variables.bindings, value);
				break;
			case "in":
				if (!isArray(value)) {
					throw(
						type = "QueryBuilder.InvalidValue",
						message = "IN operator requires array value",
						detail = "Column '#arguments.column#' IN value is not an array"
					);
				}
				var placeholders = [];
				for (var i = 1; i <= arrayLen(value); i++) {
					arrayAppend(placeholders, "?");
					arrayAppend(variables.bindings, value[i]);
				}
				arrayAppend(variables.whereClauses, arguments.column & " IN (" & arrayToList(placeholders, ", ") & ")");
				break;
			case "notin":
				if (!isArray(value)) {
					throw(
						type = "QueryBuilder.InvalidValue",
						message = "NOT IN operator requires array value",
						detail = "Column '#arguments.column#' NOT IN value is not an array"
					);
				}
				var placeholders = [];
				for (var i = 1; i <= arrayLen(value); i++) {
					arrayAppend(placeholders, "?");
					arrayAppend(variables.bindings, value[i]);
				}
				arrayAppend(variables.whereClauses, arguments.column & " NOT IN (" & arrayToList(placeholders, ", ") & ")");
				break;
			case "between":
				if (!isArray(value) || arrayLen(value) != 2) {
					throw(
						type = "QueryBuilder.InvalidValue",
						message = "BETWEEN operator requires two-element array",
						detail = "Column '#arguments.column#' BETWEEN value must be array with 2 elements"
					);
				}
				arrayAppend(variables.whereClauses, arguments.column & " BETWEEN ? AND ?");
				arrayAppend(variables.bindings, value[1]);
				arrayAppend(variables.bindings, value[2]);
				break;
			case "isnull":
				arrayAppend(variables.whereClauses, arguments.column & " IS NULL");
				break;
			case "notnull":
				arrayAppend(variables.whereClauses, arguments.column & " IS NOT NULL");
				break;
			default:
				throw(
					type = "QueryBuilder.InvalidOperator",
					message = "Unknown operator '#operator#'",
					detail = "Supported operators: gte, gt, lte, lt, ne, like, in, notIn, between, isNull, notNull"
				);
		}
	}

}
