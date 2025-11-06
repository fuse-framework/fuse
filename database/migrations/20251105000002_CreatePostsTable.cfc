/**
 * Example migration: Create posts table with foreign key
 *
 * Demonstrates foreign key constraints and various column types
 */
component extends="fuse.orm.Migration" {

	/**
	 * Run migration
	 */
	public function up() {
		schema.create("posts", function(table) {
			table.id();
			table.bigInteger("user_id").notNull();
			table.string("title", 200).notNull();
			table.text("body").notNull();
			table.string("status", 20).default("draft");
			table.integer("view_count").default(0);
			table.datetime("published_at");
			table.timestamps();

			// Add foreign key with cascade delete
			table.foreignKey("user_id")
				.references("users", "id")
				.onDelete("CASCADE");

			// Add indexes
			table.index("user_id");
			table.index("status");
			table.index(["user_id", "status"]);
		});
	}

	/**
	 * Reverse migration
	 */
	public function down() {
		schema.drop("posts");
	}

}
