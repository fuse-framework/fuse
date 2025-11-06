/**
 * MainSeeder - Test fixture seeder for SeederTest
 *
 * Tests calling another seeder and passing datasource
 */
component extends="fuse.orm.Seeder" {

	public function run() {
		// Call TestSeeder
		call("TestSeeder");
		variables.childSeederCalled = true;
	}

	public boolean function wasChildSeederCalled() {
		return structKeyExists(variables, "childSeederCalled") && variables.childSeederCalled;
	}

	public string function getChildDatasource() {
		// Create TestSeeder to check its datasource
		childSeeder = new database.seeds.TestSeeder(variables.datasource);
		return childSeeder.getDatasource();
	}

}
