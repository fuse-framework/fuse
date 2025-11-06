/**
 * Migration - Base class for database migrations
 *
 * Provides schema access and abstract up/down methods.
 * Child migrations extend this class and implement up() and down().
 */
component {

	/**
	 * Initialize Migration
	 *
	 * @datasource Datasource name
	 * @return Migration instance
	 */
	public function init(required string datasource) {
		variables.datasource = arguments.datasource;
		return this;
	}

	/**
	 * Get SchemaBuilder instance (lazy-initialized)
	 *
	 * @return SchemaBuilder instance
	 */
	public function getSchema() {
		if (!structKeyExists(variables, "schemaBuilder")) {
			variables.schemaBuilder = new fuse.orm.SchemaBuilder(variables.datasource);
		}
		return variables.schemaBuilder;
	}

	/**
	 * Abstract up method - override in child migrations
	 */
	public function up() {
		// Implemented by child migrations
	}

	/**
	 * Abstract down method - override in child migrations
	 */
	public function down() {
		// Implemented by child migrations
	}

}
