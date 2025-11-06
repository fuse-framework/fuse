<cfsetting enablecfoutputonly="true">
<cfscript>
	// Create TestBox instance for module tests only
	testbox = new testbox.system.TestBox(
		directory = {
			mapping = "tests.core",
			recurse = false,
			filter = function(path) {
				return findNoCase("ModuleSystemTest", path) > 0;
			}
		}
	);

	// Run tests and get results
	results = testbox.run(reporter="simple");

	// Output results
	writeOutput(results);
</cfscript>
