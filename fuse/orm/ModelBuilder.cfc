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

}
