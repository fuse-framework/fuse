/**
 * LegacyUser - Test fixture model demonstrating primary key override
 *
 * Shows how to work with legacy tables using non-standard primary keys.
 */
component extends="fuse.orm.ActiveRecord" {
	// Override primary key for legacy table
	this.primaryKey = "user_id";

	// Uses default table name: "legacyusers"
}
