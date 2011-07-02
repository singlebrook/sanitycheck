To use sanitycheck, pull it in to your site at /sanitycheck/sanitycheck.
This is a bit odd, but since we need to use svn:externals and have a separate
(blank) Application.cfm for sanitycheck, it seems to be the best way.
(The two sanitycheck folders can also live in a subdirectory if it's for a 
specific app.)


Create /sanitycheck/Application.cfm with a single space in it. It could
just be blank, but some versions of CF don't like 0-byte files.


Create /sanitycheck/sanitycheck.cfm. It might look something like this:

	<cfinclude template="sanitycheck/lib_sanitycheck.cfm">
	
	<cfset sc_setPassword("bigSecret")>
	
	<cfset sc_CFVersion("6+")>
	
	<cfset sc_mappingExists("lib")>


Add the following to your Application.cfm or Application.cfc, preferably
in the area where your application is initialized. This will cause the sanitycheck to be run in the background and it's output logged.

	<cfif cgi.script_name does not contain "sanitycheck.cfm">
		<cfinclude template="sanitycheck/sanitycheck.cfm">
	</cfif>


If you like, create /sanitycheck/index.cfm containing:

	<cflocation url="sanitycheck.cfm" addtoken="no">