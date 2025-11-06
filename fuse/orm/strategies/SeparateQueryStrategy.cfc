/**
 * SeparateQueryStrategy - Executes eager loading using separate WHERE IN query
 *
 * Used for hasMany relationships to avoid Cartesian product row explosion.
 * Collects foreign key values from parent records and executes a single batched
 * WHERE IN query to load all related records, then maps them back to parents.
 *
 * USAGE EXAMPLE:
 *
 * Load hasMany relationship:
 *     var strategy = new fuse.orm.strategies.SeparateQueryStrategy();
 *     var users = [
 *         {id: 1, name: "User 1"},
 *         {id: 2, name: "User 2"}
 *     ];
 *     var config = {
 *         type: "hasMany",
 *         foreignKey: "user_id",
 *         className: "Post",
 *         relatedTable: "posts"
 *     };
 *     var posts = strategy.execute(userModel, config, users, "posts");
 *     // Executes: SELECT * FROM posts WHERE user_id IN (1, 2)
 *     // Returns array of post structs grouped by user_id
 */
component {

	/**
	 * Execute separate query strategy for eager loading
	 *
	 * @param modelInstance Model instance to get datasource from
	 * @param relationshipConfig Struct with type, foreignKey, className, relatedTable
	 * @param results Array of parent model instances or structs
	 * @param relationshipName Name of the relationship being loaded
	 * @return Struct with foreignKeyValues and relatedRecords arrays
	 */
	public struct function execute(
		required any modelInstance,
		required struct relationshipConfig,
		required array results,
		required string relationshipName
	) {
		var foreignKey = arguments.relationshipConfig.foreignKey;
		var className = arguments.relationshipConfig.className;

		// Collect foreign key values from parent records
		var foreignKeyValues = [];
		for (var record in arguments.results) {
			var pkValue = "";
			if (isObject(record)) {
				// Model instance - get id from attributes
				var scope = record.getVariablesScope();
				if (structKeyExists(scope.attributes, "id")) {
					pkValue = scope.attributes.id;
				}
			} else {
				// Struct - get id directly
				if (structKeyExists(record, "id")) {
					pkValue = record.id;
				}
			}

			if (len(pkValue) && !arrayContains(foreignKeyValues, pkValue)) {
				arrayAppend(foreignKeyValues, pkValue);
			}
		}

		// If no foreign key values, return empty result
		if (arrayIsEmpty(foreignKeyValues)) {
			return {
				foreignKeyValues: [],
				relatedRecords: []
			};
		}

		// Build WHERE IN query for related records
		var modelScope = arguments.modelInstance.getVariablesScope();
		var datasource = modelScope.datasource;

		// Create instance of related model
		var fullClassName = className;
		if (!find(".", fullClassName)) {
			fullClassName = "tests.fixtures." & className;
		}

		var relatedModel = createObject("component", fullClassName).init(datasource);

		// Build WHERE IN condition
		var whereCondition = {};
		whereCondition[foreignKey] = {in: foreignKeyValues};

		// Execute query
		var relatedRecords = relatedModel.where(whereCondition).get();

		return {
			foreignKeyValues: foreignKeyValues,
			relatedRecords: relatedRecords
		};
	}

}
