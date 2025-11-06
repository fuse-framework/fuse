/**
 * Person - Test fixture model demonstrating table name override
 *
 * Shows how to override default table name convention.
 * Default would be "persons", but we override to "people".
 */
component extends="fuse.orm.ActiveRecord" {
	// Override table name for irregular plural
	this.tableName = "people";

	// Uses default primary key: "id"
}
