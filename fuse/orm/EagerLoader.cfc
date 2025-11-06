/**
 * EagerLoader - Orchestrates eager loading strategies for relationships
 *
 * Determines optimal loading strategy (JOIN vs separate query) based on relationship type
 * and handles parsing of nested relationship paths with dot notation.
 *
 * USAGE EXAMPLES:
 *
 * Basic strategy selection:
 *     var loader = new fuse.orm.EagerLoader();
 *     var strategy = loader.selectStrategy("posts", {type: "hasMany"});
 *     // Returns "separate"
 *
 * Parse nested relationships:
 *     var path = loader.parseRelationshipPath("posts.comments.author");
 *     // Returns ["posts", "comments", "author"]
 *
 * Validate relationships:
 *     loader.validateRelationship(userInstance, "posts");
 *     // Throws ActiveRecord.InvalidRelationship if invalid
 *
 * Load relationships:
 *     var users = User::includes("posts").get();
 *     loader.load(users, eagerLoadConfig);
 *
 * Strategy selection rules:
 * - belongsTo: JOIN (parent may not exist, no row duplication)
 * - hasOne: JOIN (related may not exist, no row duplication)
 * - hasMany: Separate queries (avoids Cartesian product row explosion)
 */
component {

	/**
	 * Select loading strategy based on relationship type
	 *
	 * @param relationshipName Name of the relationship
	 * @param relationshipMetadata Struct with type, foreignKey, className
	 * @return String "join" or "separate"
	 */
	public string function selectStrategy(required string relationshipName, required struct relationshipMetadata) {
		var type = arguments.relationshipMetadata.type;

		if (type == "belongsTo" || type == "hasOne") {
			return "join";
		} else if (type == "hasMany") {
			return "separate";
		}

		// Fallback for unknown types
		return "separate";
	}

	/**
	 * Parse dot notation relationship path into array hierarchy
	 *
	 * @param dotNotation Relationship path with dots (e.g., "posts.comments.author")
	 * @return Array of relationship names in order
	 *
	 * @example parseRelationshipPath("posts") returns ["posts"]
	 * @example parseRelationshipPath("posts.comments") returns ["posts", "comments"]
	 */
	public array function parseRelationshipPath(required string dotNotation) {
		return listToArray(arguments.dotNotation, ".");
	}

	/**
	 * Validate relationship exists on model
	 * Throws error immediately if relationship name is invalid (fail fast)
	 *
	 * @param modelClass Model instance with relationships
	 * @param relationshipName Name of relationship to validate
	 * @throws ActiveRecord.InvalidRelationship if relationship doesn't exist
	 */
	public void function validateRelationship(required any modelClass, required string relationshipName) {
		var scope = arguments.modelClass.getVariablesScope();

		if (!structKeyExists(scope, "relationships") || !structKeyExists(scope.relationships, arguments.relationshipName)) {
			throw(
				type = "ActiveRecord.InvalidRelationship",
				message = "Invalid relationship '#arguments.relationshipName#'",
				detail = "Relationship '#arguments.relationshipName#' is not defined on #getMetadata(arguments.modelClass).name#. Available relationships: #structKeyList(scope.relationships ?: {})#"
			);
		}
	}

	/**
	 * Load eager loaded relationships for model instances
	 * Orchestrates the loading strategy execution and result hydration
	 *
	 * @param results Array of model instances with relationships to load
	 * @param eagerLoadConfig Array of eager load configurations with name, strategy, nested
	 * @param modelInstance Model instance to get metadata from
	 * @return Array of model instances with loadedRelationships populated
	 */
	public array function load(
		required array results,
		required array eagerLoadConfig,
		required any modelInstance
	) {
		// Process each eager load configuration
		for (var config in arguments.eagerLoadConfig) {
			var relationshipName = config.name;
			var requestedStrategy = config.strategy;

			// Parse relationship path (handles dot notation)
			var path = parseRelationshipPath(relationshipName);

			// Check if this is a nested relationship
			if (arrayLen(path) > 1) {
				// Handle nested loading
				loadNested(arguments.results, path, requestedStrategy, arguments.modelInstance);
			} else {
				// Handle single-level loading
				var firstLevelRelationship = path[1];

				// Get relationship metadata
				var modelScope = arguments.modelInstance.getVariablesScope();
				if (!structKeyExists(modelScope.relationships, firstLevelRelationship)) {
					continue;
				}

				var relationshipConfig = modelScope.relationships[firstLevelRelationship];

				// Add relatedTable to config (infer from className)
				relationshipConfig.relatedTable = inferTableName(relationshipConfig.className);

				// Determine strategy (auto-select or use override)
				var strategy = requestedStrategy;
				if (strategy == "auto") {
					strategy = selectStrategy(firstLevelRelationship, relationshipConfig);
				}

				// Execute strategy
				if (strategy == "join") {
					// JOIN strategy already executed in query - skip here
					// Hydration happens in get()/first() override
				} else {
					// Execute separate query strategy
					var separateStrategy = new fuse.orm.strategies.SeparateQueryStrategy();
					var strategyResult = separateStrategy.execute(
						arguments.modelInstance,
						relationshipConfig,
						arguments.results,
						firstLevelRelationship
					);

					// Hydrate results with relationship data
					hydrateRelationships(
						arguments.results,
						strategyResult.relatedRecords,
						firstLevelRelationship,
						relationshipConfig
					);
				}
			}
		}

		return arguments.results;
	}

	/**
	 * Load nested relationships recursively
	 * Handles dot notation like "posts.comments.author"
	 *
	 * @param results Array of parent model instances
	 * @param path Array of relationship names in hierarchy
	 * @param strategy Strategy override or "auto"
	 * @param modelInstance Model instance for datasource
	 */
	public void function loadNested(
		required array results,
		required array path,
		required string strategy,
		required any modelInstance
	) {
		// Base case: empty path
		if (arrayIsEmpty(arguments.path) || arrayIsEmpty(arguments.results)) {
			return;
		}

		// Get first level relationship name
		var currentRelationship = arguments.path[1];
		var remainingPath = arraySlice(arguments.path, 2);

		// Get relationship metadata from first result
		var firstResult = arguments.results[1];
		var resultScope = firstResult.getVariablesScope();

		if (!structKeyExists(resultScope.relationships, currentRelationship)) {
			return;
		}

		var relationshipConfig = resultScope.relationships[currentRelationship];
		relationshipConfig.relatedTable = inferTableName(relationshipConfig.className);

		// Determine strategy for this level
		var currentStrategy = arguments.strategy;
		if (currentStrategy == "auto") {
			currentStrategy = selectStrategy(currentRelationship, relationshipConfig);
		}

		// Load this level using separate query strategy
		// (JOIN strategy doesn't apply to nested relationships in this implementation)
		var separateStrategy = new fuse.orm.strategies.SeparateQueryStrategy();
		var strategyResult = separateStrategy.execute(
			arguments.modelInstance,
			relationshipConfig,
			arguments.results,
			currentRelationship
		);

		// Hydrate current level
		hydrateRelationships(
			arguments.results,
			strategyResult.relatedRecords,
			currentRelationship,
			relationshipConfig
		);

		// If there are more levels in the path, recursively load them
		if (!arrayIsEmpty(remainingPath)) {
			// Collect all loaded relationships at this level
			var loadedRelationships = [];
			for (var parentRecord in arguments.results) {
				var parentScope = parentRecord.getVariablesScope();

				if (structKeyExists(parentScope.loadedRelationships, currentRelationship)) {
					var relatedData = parentScope.loadedRelationships[currentRelationship];

					// Handle both single instances (belongsTo/hasOne) and arrays (hasMany)
					if (isArray(relatedData)) {
						for (var relatedRecord in relatedData) {
							if (!isNull(relatedRecord)) {
								arrayAppend(loadedRelationships, relatedRecord);
							}
						}
					} else if (!isNull(relatedData)) {
						arrayAppend(loadedRelationships, relatedData);
					}
				}
			}

			// Recursively load next level
			if (!arrayIsEmpty(loadedRelationships)) {
				loadNested(loadedRelationships, remainingPath, arguments.strategy, arguments.modelInstance);
			}
		}
	}

	/**
	 * Hydrate model instances with loaded relationship data
	 *
	 * @param results Array of parent model instances
	 * @param relatedRecords Array of related model instances or structs
	 * @param relationshipName Name of the relationship
	 * @param relationshipConfig Relationship metadata struct
	 */
	public void function hydrateRelationships(
		required array results,
		required array relatedRecords,
		required string relationshipName,
		required struct relationshipConfig
	) {
		var type = arguments.relationshipConfig.type;
		var foreignKey = arguments.relationshipConfig.foreignKey;

		// Group related records by foreign key for efficient lookup
		var groupedRecords = {};

		if (type == "hasMany") {
			// hasMany: group by foreignKey (user_id -> [posts])
			for (var relatedRecord in arguments.relatedRecords) {
				var fkValue = "";
				if (isObject(relatedRecord)) {
					var relatedScope = relatedRecord.getVariablesScope();
					if (structKeyExists(relatedScope.attributes, foreignKey)) {
						fkValue = relatedScope.attributes[foreignKey];
					}
				} else {
					if (structKeyExists(relatedRecord, foreignKey)) {
						fkValue = relatedRecord[foreignKey];
					}
				}

				if (len(fkValue)) {
					if (!structKeyExists(groupedRecords, fkValue)) {
						groupedRecords[fkValue] = [];
					}
					arrayAppend(groupedRecords[fkValue], relatedRecord);
				}
			}

			// Populate each parent with array of related records
			for (var parentRecord in arguments.results) {
				var parentScope = parentRecord.getVariablesScope();
				var parentId = parentScope.attributes.id;

				if (structKeyExists(groupedRecords, parentId)) {
					parentScope.loadedRelationships[arguments.relationshipName] = groupedRecords[parentId];
				} else {
					parentScope.loadedRelationships[arguments.relationshipName] = [];
				}
			}
		} else if (type == "belongsTo" || type == "hasOne") {
			// belongsTo/hasOne: single record or null
			// Build lookup map by id for related records
			var relatedMap = {};
			for (var relatedRecord in arguments.relatedRecords) {
				var relatedId = "";
				if (isObject(relatedRecord)) {
					var relatedScope = relatedRecord.getVariablesScope();
					if (structKeyExists(relatedScope.attributes, "id")) {
						relatedId = relatedScope.attributes.id;
					}
				} else {
					if (structKeyExists(relatedRecord, "id")) {
						relatedId = relatedRecord.id;
					}
				}

				if (len(relatedId)) {
					relatedMap[relatedId] = relatedRecord;
				}
			}

			// Populate each parent with single related record
			for (var parentRecord in arguments.results) {
				var parentScope = parentRecord.getVariablesScope();

				if (type == "belongsTo") {
					// belongsTo: lookup by parent's foreignKey value
					var fkValue = parentScope.attributes[foreignKey];
					if (structKeyExists(relatedMap, fkValue)) {
						parentScope.loadedRelationships[arguments.relationshipName] = relatedMap[fkValue];
					} else {
						parentScope.loadedRelationships[arguments.relationshipName] = null;
					}
				} else {
					// hasOne: lookup by parent's id
					var parentId = parentScope.attributes.id;
					// Find related record where foreignKey matches parentId
					var found = false;
					for (var relatedRecord in arguments.relatedRecords) {
						var relatedFk = "";
						if (isObject(relatedRecord)) {
							var rs = relatedRecord.getVariablesScope();
							if (structKeyExists(rs.attributes, foreignKey)) {
								relatedFk = rs.attributes[foreignKey];
							}
						} else {
							if (structKeyExists(relatedRecord, foreignKey)) {
								relatedFk = relatedRecord[foreignKey];
							}
						}

						if (relatedFk == parentId) {
							parentScope.loadedRelationships[arguments.relationshipName] = relatedRecord;
							found = true;
							break;
						}
					}

					if (!found) {
						parentScope.loadedRelationships[arguments.relationshipName] = null;
					}
				}
			}
		}
	}

	/**
	 * Infer table name from class name
	 * Converts PascalCase class name to lowercase plural table name
	 *
	 * @param className Class name (e.g., "Post", "User")
	 * @return Table name (e.g., "posts", "users")
	 */
	private string function inferTableName(required string className) {
		var tableName = lcase(arguments.className);

		// Simple pluralization: append 's'
		if (right(tableName, 1) != "s") {
			tableName = tableName & "s";
		}

		return tableName;
	}

}
