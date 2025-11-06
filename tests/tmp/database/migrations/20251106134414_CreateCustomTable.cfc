/**
 * Migration: CreateCustomTable
 *
 * Creates my_custom_table table
 */
component extends="fuse.orm.Migration" {

	/**
	 * Run migration
	 */
	public function up() {
		schema.create("my_custom_table", function(table) {
			table.id();
			table.string("name");
			table.timestamps();
		});
	}

	/**
	 * Reverse migration
	 */
	public function down() {
		schema.drop("my_custom_table");
	}

}
