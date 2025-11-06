/**
 * Example migration: Create users table
 *
 * Demonstrates basic table creation with various column types
 */
component extends="fuse.orm.Migration" {

	/**
	 * Run migration
	 */
	public function up() {
		schema.create("users", function(table) {
			table.id();
			table.string("email").notNull().unique();
			table.string("name", 100).notNull();
			table.string("password", 255).notNull();
			table.boolean("active").default(1);
			table.timestamps();
		});
	}

	/**
	 * Reverse migration
	 */
	public function down() {
		schema.drop("users");
	}

}
