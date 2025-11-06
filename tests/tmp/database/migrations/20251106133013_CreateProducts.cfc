/**
 * Migration: CreateProducts
 *
 * Creates products table
 */
component extends="fuse.orm.Migration" {

	/**
	 * Run migration
	 */
	public function up() {
		schema.create("products", function(table) {
			table.id();
			table.string("name");
			
		});
	}

	/**
	 * Reverse migration
	 */
	public function down() {
		schema.drop("products");
	}

}
