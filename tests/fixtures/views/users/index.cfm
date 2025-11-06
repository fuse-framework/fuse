<h1>Users List</h1>
<ul>
<cfoutput>
<cfloop array="#users#" index="user">
	<li>#user#</li>
</cfloop>
</cfoutput>
</ul>