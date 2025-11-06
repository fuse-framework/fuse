/**
 * Migration: CreateUsers
 *
 * Creates users table
 */
component extends="fuse.orm.Migration" {

	/**
	 * Run migration
	 */
	public function up() {
		schema.create("users", function(table) {
			table.id();
			table.string("name");
			table.string("email");
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
