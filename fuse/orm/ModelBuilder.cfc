/**
 * ModelBuilder - Query builder with table name binding
 *
 * Extends QueryBuilder to provide table-specific query building for ORM models.
 * Stores table name so terminal methods (get, first, count) don't require tableName parameter.
 *
 * USAGE EXAMPLES:
 *
 * Basic model queries:
 *     var users = new fuse.orm.ModelBuilder("myDatasource", "users");
 *     var activeUsers = users.where({active: true}).orderBy("name").get();
 *     var firstUser = users.where({email: "test@example.com"}).first();
 *     var userCount = users.where({role: "admin"}).count();
 *
 * Eager loading:
 *     var users = User::includes("posts").get();
 *     var users = User::includes(["posts", "profile"]).where({active: true}).get();
 *     var users = User::includes("posts.comments").get();
 *     var users = User::joins("posts").where({status: "published"}).get();
 *     var users = User::preload("posts").get();
 *
 * Complex queries:
 *     var posts = new fuse.orm.ModelBuilder("myDatasource", "posts");
 *     var results = posts.select("title, created_at, status")
 *                        .where({
 *                            status: "published",
 *                            created_at: {gte: createDate(2024, 1, 1)}
 *                        })
 *                        .orderBy("created_at", "DESC")
 *                        .limit(10)
 *                        .get();
 *
 * Method chaining:
 *     All builder methods inherited from QueryBuilder return `this` for chaining.
 *     Terminal methods (get, first, count) execute the query and return results.
 *
 * Future enhancements (roadmap item #5 - ActiveRecord):
 *     The get() and first() methods will be overridden in ActiveRecord base class
 *     to return model instances instead of plain structs, enabling:
 *     - Instance methods like save(), update(), delete()
 *     - Attribute dirty tracking
 *     - Relationship loading
 *
 * Inherited capabilities from QueryBuilder:
 *     - All SELECT, WHERE, JOIN, ORDER BY functionality
 *     - Hash-based operator support (gte, in, isNull, etc.)
 *     - Raw SQL support via whereRaw()
 *     - Prepared statement binding
 */
component extends="QueryBuilder" {

	/**
	 * Initialize ModelBuilder with datasource and table name
	 *
	 * @datasource Datasource name for query execution
	 * @tableName Table name for FROM clause
	 * @return ModelBuilder instance for chaining
	 */
	public function init(required string datasource, required string tableName) {
		// Call parent init
		super.init(arguments.datasource);

		// Store table name
		variables.tableName = arguments.tableName;

		// Initialize eager loading state
		variables.eagerLoad = [];

		return this;
	}

	/**
	 * Build SQL string from internal state using stored table name
	 *
	 * @return Struct with sql and bindings keys
	 */
	public struct function toSQL() {
		// Delegate to parent toSQL with stored tableName
		return super.toSQL(variables.tableName);
	}

	/**
	 * Execute query and return all results
	 *
	 * Note: In future ActiveRecord implementation (roadmap item #5),
	 * this method will be overridden to return model instances instead of structs
	 *
	 * @return Array of structs (one per row)
	 */
	public array function get() {
		return super.get(variables.tableName);
	}

	/**
	 * Execute query and return first result
	 *
	 * Note: In future ActiveRecord implementation (roadmap item #5),
	 * this method will be overridden to return a model instance instead of struct
	 *
	 * @return Struct or null if no results
	 */
	public function first() {
		return super.first(variables.tableName);
	}

	/**
	 * Execute COUNT(*) query
	 *
	 * @return Numeric count
	 */
	public numeric function count() {
		return super.count(variables.tableName);
	}

	/**
	 * Eager load relationships using automatic strategy selection
	 * Accepts string, array, or dot notation for nested relationships
	 *
	 * @param relationships String or array of relationship names
	 * @return ModelBuilder instance for chaining
	 *
	 * @example includes("posts")
	 * @example includes(["posts", "profile"])
	 * @example includes("posts.comments")
	 */
	public function includes(required any relationships) {
		return addEagerLoad(arguments.relationships, "auto");
	}

	/**
	 * Eager load relationships using JOIN strategy
	 * Forces JOIN regardless of relationship type
	 *
	 * @param relationships String or array of relationship names
	 * @return ModelBuilder instance for chaining
	 *
	 * @example joins("posts")
	 * @example joins(["posts", "profile"])
	 */
	public function joins(required any relationships) {
		return addEagerLoad(arguments.relationships, "join");
	}

	/**
	 * Eager load relationships using separate query strategy
	 * Forces separate queries regardless of relationship type
	 *
	 * @param relationships String or array of relationship names
	 * @return ModelBuilder instance for chaining
	 *
	 * @example preload("posts")
	 * @example preload(["posts", "profile"])
	 */
	public function preload(required any relationships) {
		return addEagerLoad(arguments.relationships, "separate");
	}

	/**
	 * Add relationships to eager load configuration
	 * Internal helper for includes(), joins(), and preload()
	 *
	 * @param relationships String or array of relationship names
	 * @param strategy Strategy to use: "auto", "join", or "separate"
	 * @return ModelBuilder instance for chaining
	 */
	private function addEagerLoad(required any relationships, required string strategy) {
		// Normalize to array
		var relationshipArray = [];
		if (isArray(arguments.relationships)) {
			relationshipArray = arguments.relationships;
		} else {
			relationshipArray = [arguments.relationships];
		}

		// Create EagerLoader instance for validation
		var eagerLoader = new fuse.orm.EagerLoader();

		// Process each relationship
		for (var relationshipName in relationshipArray) {
			// Parse dot notation (returns array even for single level)
			var path = eagerLoader.parseRelationshipPath(relationshipName);

			// Validate first level relationship (fail fast)
			eagerLoader.validateRelationship(this, path[1]);

			// Store in eagerLoad array with strategy metadata
			arrayAppend(variables.eagerLoad, {
				name: relationshipName,
				strategy: arguments.strategy,
				nested: []
			});
		}

		return this;
	}

	/**
	 * Get variables scope for testing/introspection
	 *
	 * @return Struct of variables scope
	 */
	public struct function getVariablesScope() {
		return variables;
	}

}
