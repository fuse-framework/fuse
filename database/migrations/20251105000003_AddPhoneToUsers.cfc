/**
 * Example migration: Modify existing table
 *
 * Demonstrates adding columns to an existing table
 */
component extends="fuse.orm.Migration" {

	/**
	 * Run migration
	 */
	public function up() {
		schema.table("users", function(table) {
			table.string("phone", 20);
			table.string("timezone", 50).default("UTC");
		});
	}

	/**
	 * Reverse migration
	 */
	public function down() {
		// Note: Column dropping not implemented in current spec
		// In production, you would drop the columns here
	}

}
