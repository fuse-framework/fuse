/**
 * User - Test fixture model for ActiveRecord tests
 *
 * Demonstrates default conventions:
 * - Table name defaults to "users" (plural of User)
 * - Primary key defaults to "id"
 *
 * USAGE EXAMPLES:
 *
 * Static finders:
 *     var user = User::find(1);
 *     var users = User::where({active: true}).get();
 *     var allUsers = User::all().orderBy("name").get();
 *
 * Instance methods:
 *     var user = new User(datasource);
 *     user.name = "John Doe";
 *     user.email = "john@example.com";
 *     user.save();
 */
component extends="fuse.orm.ActiveRecord" {
	// Uses default conventions:
	// - this.tableName = "users" (auto-generated)
	// - this.primaryKey = "id" (auto-generated)

	/**
	 * Helper method for tests to set variables scope values
	 * Allows tests to inject validation configs and state
	 *
	 * @param key Variable name to set
	 * @param value Value to set
	 */
	public void function setVariablesScope(required string key, required any value) {
		variables[arguments.key] = arguments.value;
	}
}
