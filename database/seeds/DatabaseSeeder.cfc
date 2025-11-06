/**
 * DatabaseSeeder - Main database seeder
 *
 * This is the default seeder invoked by the Seed command.
 * Use call() to invoke other seeders in the desired order.
 *
 * BEST PRACTICES:
 *
 * 1. Idempotency - Seeders should be safe to run multiple times
 *    Check if data exists before inserting to avoid duplicates
 *
 * 2. Composition - Use call() to invoke other seeders
 *    This keeps seed logic organized and reusable
 *
 * 3. Datasource - Access via variables.datasource
 *    This is set automatically when seeder is initialized
 *
 * EXAMPLE USAGE:
 *
 * Run all seeds:
 *     lucli fuse.cli.commands.Seed
 *
 * Run specific seeder:
 *     lucli fuse.cli.commands.Seed --class=UserSeeder
 */
component extends="fuse.orm.Seeder" {

	/**
	 * Run database seeders
	 *
	 * Override this method to call other seeders in the desired order.
	 * Each call() invocation loads and runs another seeder from database.seeds package.
	 */
	public function run() {
		// Example: Uncomment and customize these calls
		// call("UserSeeder");
		// call("PostSeeder");
		// call("CommentSeeder");
	}

}
