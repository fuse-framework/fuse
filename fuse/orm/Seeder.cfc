/**
 * Seeder - Base class for database seeders
 *
 * Provides foundation for programmable database seeding:
 * - Store datasource for use in seed logic
 * - Override run() to implement seed logic
 * - Use call() to invoke other seeders
 *
 * USAGE EXAMPLES:
 *
 * Basic seeder:
 *     component extends="fuse.orm.Seeder" {
 *         public function run() {
 *             queryExecute("
 *                 INSERT INTO users (name, email)
 *                 VALUES ('Admin', 'admin@test.com')
 *             ", [], {datasource: variables.datasource});
 *         }
 *     }
 *
 * Seeder with call() to other seeders:
 *     component extends="fuse.orm.Seeder" {
 *         public function run() {
 *             call("UserSeeder");
 *             call("PostSeeder");
 *         }
 *     }
 *
 * Idempotent seeder pattern:
 *     component extends="fuse.orm.Seeder" {
 *         public function run() {
 *             // Check if data exists first
 *             var count = queryExecute("
 *                 SELECT COUNT(*) as total FROM users
 *             ", [], {datasource: variables.datasource}).total;
 *
 *             if (count == 0) {
 *                 // Insert data
 *                 queryExecute("INSERT INTO users ...", [], {datasource: variables.datasource});
 *             }
 *         }
 *     }
 */
component {

	/**
	 * Initialize Seeder with datasource
	 *
	 * @datasource Datasource name for database operations
	 * @return Seeder instance for chaining
	 */
	public function init(required string datasource) {
		variables.datasource = arguments.datasource;
		return this;
	}

	/**
	 * Run seeder logic - override in subclasses
	 *
	 * This is an abstract method pattern. Subclasses should override
	 * this method to implement their specific seed logic.
	 */
	public void function run() {
		// Empty default implementation - subclasses override
	}

	/**
	 * Call another seeder by name
	 *
	 * Loads seeder component from database.seeds package and invokes
	 * its run() method. Passes current datasource to child seeder.
	 *
	 * @seederName Name of seeder class (e.g., "UserSeeder")
	 */
	public void function call(required string seederName) {
		// Load seeder from database.seeds package
		var seederPath = "database.seeds." & arguments.seederName;
		var seeder = createObject("component", seederPath).init(variables.datasource);

		// Invoke seeder's run() method
		seeder.run();
	}

	/**
	 * Get datasource name (for testing)
	 *
	 * @return Datasource name string
	 */
	public string function getDatasource() {
		return variables.datasource;
	}

}
