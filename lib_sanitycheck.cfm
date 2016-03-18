<cfset variables.sc_logfile = "sanitycheck">
<cfset variables.sc_password = "">
<cfset variables.sc_isInited = 0>
<cfparam name="variables.sc_requireSSL" default="0">

<cffunction name="sc_init" returntype="void" output="yes" access="public"
		hint="Sets up environment for script. Checks user's authorization if running interactively.">
	<cfset var v = structNew()>

	<cfif variables.sc_isInited>
		<cfreturn>
	</cfif>

	<cfif sc_isInteractive() and variables.sc_password eq "">
		<cfthrow message="Can't run interactively without having set a password with sc_setPassword()">
	</cfif>

	<style type="text/css">
		.passed {
			color: green;
		}
		.failed {
			color: red;
		}
	</style>

	<cfif sc_isInteractive() and (not(structKeyExists(form, 'sc_pass'))
			or form.sc_pass neq variables.sc_password)>

		<!--- Some clients require SSL for forms that contain passwords - Jared 12/31/10 --->
		<!--- To do: inspect protocol instead of port number - Jared 12/31/10 --->
		<cfif variables.sc_requireSSL AND CGI.SERVER_PORT NEQ 443>
			<h1 style="color:red;">On this site, sanitycheck is configured to require SSL</h1>
			<cfabort>
		</cfif>

		<form method="post">
			Password <input type="password" name="sc_pass" />
			<input type="submit" value="Go" /><br />
			(If you don't know what this is, look in sc_setPassword() in this file.)
		</form>
		<cfabort>
	</cfif>

	<cfset variables.sc_isInited = 1>
	<cfreturn>

</cffunction> <!--- sc_init --->


<cffunction name="sc_assertEqual" returntype="void" output="yes" access="public"
		hint="General purpose assertion">
	<cfargument name="string1" type="string" required="yes">
	<cfargument name="string2" type="string" required="yes">
	<cfset var v = structNew()>

	<cfset v.success = (string1 eq string2)>
	<cfif v.success>
		<cfset v.msg = "#string1# is equal to #string2#">
	<cfelse>
		<cfset v.msg = "#string1# is not equal to #string2#">
	</cfif>

	<cfset sc_FormatResult(string1 eq string2, v.msg)>

</cffunction> <!--- sc_assertEqual --->


<cffunction name="sc_CFVersion" returntype="void" output="yes" access="public"
		hint="Specify the minimum or exact required version of ColdFusion">
	<cfargument name="requiredVersion" type="string" required="yes">
	<cfset var v = structNew()>

	<cfif not(REFind('^[.\d]+\+?$', requiredVersion ))>
		<cfthrow message="requiredVersion must be one or more digits and dots, optionally followed by a plus">
	</cfif>

	<cfif requiredVersion contains "+">
		<cfset v.exactMatch = 0>
		<cfset v.numericVersion = replace(requiredVersion, '+', '')>
	<cfelse>
		<cfset v.exactMatch = 1>
		<cfset v.numericVersion = requiredVersion>
	</cfif>

	<cfset v.actualVersion = Replace(server.ColdFusion.ProductVersion, ',', '.', 'all')>
	<cfset v.actualMajorVersion = ListFirst(v.actualVersion, '.')>

	<cfset v.checkPassed = REFind('^' & v.numericVersion, v.actualVersion)
			or (not(v.exactMatch) and v.actualMajorVersion gt v.numericVersion)>

	<cfif v.checkPassed>
		<cfset v.msg = "Required version of ColdFusion (#requiredVersion#) was found">
	<cfelse>
		<cfset v.msg = "Required version of ColdFusion (#requiredVersion#) was not found. Actual version is #v.actualVersion#">
	</cfif>

	<cfset sc_FormatResult(v.checkPassed, v.msg)>

</cffunction> <!--- sc_CFVersion --->


<cffunction name="sc_customTagAvailable" returntype="void" output="yes" access="public"
		hint="Ensure that a custom tag is available.">
	<cfargument name="customTagName" type="string" required="yes" hint="Exclude the leading cf_">
	<cfset var v = structNew()>

	<cftry>
		<cfset v.checkPassed = true />
		<cfset v.msg = "Custom tag #customTagName# was found">
		<cfsilent>
			<cfmodule name="#customTagName#">
		</cfsilent>

		<cfcatch type="coldfusion.tagext.lang.ModuleTag$CannotOpenCfmlException">
			<!--- This is the error that Adobe ColdFusion throws --->
			<cfset v.checkPassed = false />
			<cfset v.msg = "Custom tag #customTagName# was not found">
		</cfcatch>

		<cfcatch type="any">
			<cfif cfcatch.message contains "is not defined in custom tag directory">
			<!--- This is the error that Railo/Lucee throws --->
				<cfset v.checkPassed = false />
				<cfset v.msg = "Custom tag #customTagName# was not found">
			</cfif>

			<!--- Other errors are likely to occur when invoking the custom tag
			(e.g. missing end tag, missing params, etc). We don't care about those,
			so just swallow them. --->
		</cfcatch>
	</cftry>

	<cfset sc_FormatResult(v.checkPassed, v.msg)>

</cffunction> <!--- sc_customTagAvailable --->


<cffunction name="sc_datasourceExists" returntype="void" output="yes" access="public"
		hint="Ensure that a datasource is defined.">
	<cfargument name="datasourceName" type="string" required="yes">
	<cfset var v = structNew()>

	<cftry>
		<!--- This should always throw an error due to the table name. We'll examine the error
			to determine if the datasource exists. - leon 8/26/09 --->
		<cfquery datasource="#datasourceName#" timeout="3">
			select * from thereIsNoTableWithThisName
		</cfquery>

		<cfcatch type="any">
			<cfif REFindNoCase("data ?source", cfcatch.message)>
				<cfset v.checkPassed = false>
				<cfset v.msg = "Datasource (#datasourceName#) does not exist">
			<cfelse>
				<cfset v.checkPassed = true>
				<cfset v.msg = "Datasource (#datasourceName#) exists">
			</cfif>
		</cfcatch>
	</cftry>

	<cfset sc_FormatResult(v.checkPassed, v.msg)>

</cffunction> <!--- sc_datasourceExists --->



<cffunction name="sc_defaultSMTPServerDefined" returntype="void" output="yes" access="public"
		hint="Ensure that ColdFusion has a default SMTP server (useful if your app doesn't specify one).">
	<cfset var v = structNew()>


	<cftry>
		<cfmail from="blackhole@singlebrook.com" to="blackhole@singlebrook.com" subject=""></cfmail>
		<cfset v.checkPassed = true>
		<cfset v.msg = "Default SMTP server is defined">
		<cfcatch type="any">
			<cfif cfcatch contains "SMTP server">
				<cfset v.checkPassed = false>
				<cfset v.msg = "Default SMTP server is not defined">
			<cfelse>
				<cfset v.checkPassed = false>
				<cfset v.msg = "An error occurred while checking for a default SMTP server (#cfcatch.message#)">
			</cfif>
		</cfcatch>
	</cftry>

	<cfset sc_FormatResult(v.checkPassed, v.msg)>

</cffunction> <!--- sc_defaultSMTPServerDefined --->


<cffunction name="sc_directoryExists" returntype="void" output="yes" access="public"
		hint="Ensure that a directory exists">
	<cfargument name="dirName" type="string" required="yes" hint="must be a full path appropriate for the current platform">
	<cfset var v = structNew()>

	<cftry>
		<cfif DirectoryExists(arguments.dirName)>
			<cfset v.checkPassed = true>
			<cfset v.msg = "Directory (#arguments.dirName#) exists">
		<cfelse>
			<cfset v.checkPassed = false>
			<cfset v.msg = "Directory (#arguments.dirName#) does not exist">
		</cfif>
		<cfcatch>
			<cfset v.checkPassed = false>
			<cfset v.msg = "Unable to verify that directory (#arguments.dirName#) exists because: #cfcatch.message#">
		</cfcatch>
	</cftry>

	<cfset sc_FormatResult(v.checkPassed, v.msg)>
</cffunction> <!--- sc_directoryExists --->


<cffunction name="sc_dirIsWritable_boolean" returntype="boolean" output="no" access="public"
		hint="Checks to see if a directory is writable by creating and then deleting a test file.">
	<cfargument name="dir" type="string" required="yes" hint="A fully-qualified directory path">

	<cfset var v = structNew()>
	<cfset v.tempFileName = "ws854y7f.tmp">

	<!--- Standardize slashes - leon 11/13/09 --->
	<cfset dir = replace(dir, '\', '/', 'all')>
	<!--- Trim trailing slash - leon 11/13/09 --->
	<cfset dir = REReplace(dir, '/$', '')>
	<!--- Make path absolute if it isn't already --->
	<cfset dir = ExpandPath(dir)>

	<cfset v.tempFilePath = "#dir#/#v.tempFileName#">

	<cftry>
		<cfif fileExists(v.tempFilePath)>
			<cffile action="delete" file="#v.tempFilePath#">
		</cfif>

		<cffile action="write" file="#v.tempFilePath#" output="Temp file created by sanitycheck.sc_dirIsWritable()">

		<cfif fileExists(v.tempFilePath)>
			<cffile action="delete" file="#v.tempFilePath#">
		</cfif>

		<cfset v.itsWritable = 1>

		<cfcatch type="any">
			<cfset v.itsWritable = 0>
		</cfcatch>
	</cftry>

	<cfreturn v.itsWritable>

</cffunction> <!--- sc_dirIsWritable_boolean --->



<cffunction name="sc_dirIsWritable" returntype="void" output="yes" access="public"
		hint="Checks to see if a directory is writable by creating and then deleting a test file.">
	<cfargument name="dir" type="string" required="yes" hint="A fully-qualified directory path">

	<cfif sc_dirIsWritable_boolean(dir)>
		<cfset sc_FormatResult(1, "Directory is writable (#dir#)")>
	<cfelse>
		<cfset sc_FormatResult(0, "Directory is not writable (#dir#)")>
	</cfif>

</cffunction> <!--- sc_dirIsWritable --->


<cffunction name="sc_executableExists" returntype="void" output="yes" access="public"
		hint="Ensure that an executable program can be called.">
	<cfargument name="fullPath" type="string" required="yes" hint="the fully-qualified path to the executable" />
	<cfargument name="args" type="string" required="no" default="Arguments to make executable exit quickly (e.g. '-c exit' for bash)" />
	<cfargument name="timeout" type="numeric" required="no" default="5" hint="in seconds" />
	<cfset var v = structNew() />

	<cftry>
		<cfexecute name="#fullPath#" timeout="#timeout#" arguments="#args#" variable="v.devNull" />
		<cfset v.checkPassed = true />
		<cfset v.msg = "Executable (#fullPath#) exists and is runnable" />
		<cfcatch type="any">
			<cfset v.checkPassed = false />
			<cfif cfcatch.detail contains "No such file">
				<cfset v.msg = "Executable (#fullPath#) does not exist" />
			<cfelseif cfcatch.detail contains "Permission denied">
				<cfset v.msg = "Executable (#fullPath#) exists, but is not runnable" />
			<cfelse>
				<cfset v.msg = "An unknown problem occurred checking the existence of executable (#fullPath#)" />
			</cfif>
		</cfcatch>
	</cftry>

	<cfset sc_FormatResult(v.checkPassed, v.msg)>

</cffunction> <!--- sc_fileExists --->


<cffunction name="sc_fileExists" returntype="void" output="yes" access="public"
		hint="Ensure that a file exists. Useful for config files that aren't kept in source control.">
	<cfargument name="fileName" type="string" required="yes" hint="a fully-qualified path" />
	<cfset var v = structNew()>

	<cfif fileExists(fileName)>
		<cfset v.checkPassed = true>
		<cfset v.msg = "File (#filename#) exists">
	<cfelse>
		<cfset v.checkPassed = false>
		<cfset v.msg = "File (#filename#) does not exist">
	</cfif>

	<cfset sc_FormatResult(v.checkPassed, v.msg)>

</cffunction> <!--- sc_fileExists --->



<cffunction name="sc_fileIsWritable" returntype="void" output="yes" access="public"
		hint="Checks to see if a file is writable by appending an empty string to it if it exists,
			or by checking the dir for writability if it doesn't.">
	<cfargument name="file" type="string" required="yes" hint="A fully-qualified file path">

	<cfset var v = structNew()>

	<!--- Standardize slashes - leon 11/13/09 --->
	<cfset file = replace(file, '\', '/', 'all')>

	<!--- Make sure we're dealing with an absolute file path - leon 6/11/10 --->
	<cfset file = expandPath(file)>

	<cfif fileExists(file)>
		<!--- Try to append an empty string to the file - leon 12/17/09 --->
		<cftry>
			<cffile action="append" file="#file#" output="">
			<cfset v.itsWritable = 1>
			<cfset v.msg = "File is writable (#file#)">
			<cfcatch type="any">
				<cfset v.itsWritable = 0>
				<cfset v.msg = "File exists, but is not writable (#file#)">
			</cfcatch>
		</cftry>
	<cfelse>
		<!--- File doesn't exist. See if the dir is writable. - leon 12/17/09 --->
		<cfset v.itsWritable = sc_dirIsWritable_boolean(REReplace(file, '/[^/]+$', ''))>
		<cfif v.itsWritable>
			<cfset v.msg = "File does not exist, but the dir is writable (#file#)">
		<cfelse>
			<cfset v.msg = "File does not exist, and dir is not writable (#file#)">
		</cfif>
	</cfif>

	<cfset sc_FormatResult(v.itsWritable, v.msg)>

</cffunction> <!--- sc_fileIsWritable --->



<cffunction name="sc_FormatResult" returntype="void" output="yes" access="public"
		hint="Outputs a styled message is running interactively or writes to a log otherwise.">
	<cfargument name="passed" type="boolean" required="yes">
	<cfargument name="message" type="string" required="yes">

	<cfset var v = structNew()>

	<cfset sc_init()>

	<cfif sc_isInteractive()>
		<cfoutput>
		<div class="#iif(passed, de('passed'), de('failed'))#">
			#message#
		</div>
		<cfflush>
		</cfoutput>
	<cfelse>
		<!--- Not interactive - leon 8/11/09 --->
		<cflog file="#variables.sc_logfile#" text="#iif(passed, de('PASS'), de('FAIL'))#: #message#">
	</cfif>


</cffunction> <!--- sc_FormatResult --->


<cffunction name="sc_isInteractive" returntype="boolean" output="no" access="public"
		hint="Checks to see if this script is being run directly or is being used as
			part of an Application.cfm or Application.cfc">
	<cfset var v = structNew()>

	<!--- <cfdump var="#GetCurrentTemplatePath()#">
	<cfdump var="#cgi.script_name#">
	<cfabort> - leon 8/11/09 --->

	<cfset v.templatePathWithNormalSlashes = replace(getCurrentTemplatePath(), '\', '/', 'all')>

	<cfif cgi.script_name contains listLast(v.templatePathWithNormalSlashes, '/')>
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>

</cffunction> <!--- sc_isInteractive --->


<!--- TODO: This method has a bug that has to do with the CF Missing Template Handler (MTH).
	If an MTH is configured, and the mapping doesn't exist, the ExpandPath
	calls return some strange result that includes the MTH path instead of returning the mapping
	appended to the document root. I can't figure out how to programmatically determine what the
	MTH is, so I'm sure how to check for this condition. The symptom of the bug is that this
	function passes even if the mapping doesn't exist. - leon --->
<cffunction name="sc_mappingExists" returntype="void" output="yes" access="public"
		hint="Ensure that a mapping is defined. This function is a little buggy. We highly recommend
		using application-specific mappings (defined in your Application.cfc) instead of system-wide
		ones, but that's only available in CF8 and up.">
	<cfargument name="mappingName" type="string" required="yes">
	<cfset var v = structNew()>

	<!--- Ensure mappingName begins with a slash --->
	<cfif Left(mappingName, 1) neq '/'>
		<cfset mappingName = '/' & mappingName>
	</cfif>

	<!--- Get the absolute path, trying to use the mapping.  Note that ExpandPath()
	uses the mappings defined in the ColdFusion Administrator.
	If the mapping is defined, we expect an abs. path to the DocumentRoot - Jared 1/19/10 --->
	<cfset v.absPathViaMapping = ExpandPath(mappingName)>

	<!--- If the mapping is not defined, ExpandPath() will return a path with the
	mapping appended to the DocumentRoot. For example: DocumentRoot/mapping - Jared 1/19/10 --->
	<cfset v.absPathErroneous = ExpandPath('/') & Right(mappingName, Len(mappingName) - 1)>

	<!--- Make all path separators the same regardless
	of the system.  Needed to make work with windows - dave 12/29/09 --->
	<cfset v.absPathErroneous = Replace( v.absPathErroneous, "\", "/", "all" )>
	<cfset v.absPathViaMapping = Replace( v.absPathViaMapping, "\", "/", "all" )>

	<!--- Main test case --->
	<cfif v.absPathViaMapping EQ v.absPathErroneous>
		<cfset v.checkPassed = false>
		<cfset v.msg = "Mapping (#mappingName#) does not exist">

	<!--- Else, success.  The mapping exists --->
	<cfelse>
		<cfset v.checkPassed = true>
		<cfset v.msg = "Mapping (#mappingName#) exists">
	</cfif>

	<cfset sc_FormatResult(v.checkPassed, v.msg)>

</cffunction> <!--- sc_mappingExists --->


<cffunction name="sc_scheduledTaskExists" returntype="void" output="yes" access="public"
		hint="Ensure that a scheduled task exists.">
	<cfargument name="taskURL" type="string" required="yes" hint="A root-relative URL for the task to be executed">
	<cfargument name="useHTTPS" type="boolean" required="no" default="no" hint="Turn on only if site requires SSL">

	<cfset var v = structNew()>

	<cfset v.fqURL = "http#iif(useHTTPS,de('s'),de(''))#://#cgi.server_name##taskURL#">

	<cftry>
		<cfobject type="java" action="Create" name="v.objFactory" class="coldfusion.server.ServiceFactory">

		<cfset v.arTasks = v.objFactory.CronService.listAll()>

		<cfset v.foundTask = 0>
		<cfloop from="1" to="#arrayLen(v.arTasks)#" index="v.i">
			<cfif v.arTasks[v.i].url eq v.fqURL>
				<cfset v.foundTask = 1>
				<cfbreak>
			</cfif>
		</cfloop>

		<cfset sc_formatResult(v.foundTask, "Scheduled task (#v.fqURL#) was #iif(v.foundTask,de(''),de('not'))# found")>

		<cfcatch type="any">
			<div>
				Could not check for existence of scheduled task. Please ensure that <cfoutput>#v.fqURL#</cfoutput> is scheduled.
			</div>
		</cfcatch>
	</cftry>

</cffunction> <!--- sc_scheduledTaskExists --->



<cffunction name="sc_setPassword" returntype="void" output="no" access="public"
		hint="Sets the access password for running the script interactively">
	<cfargument name="pwd" type="string" required="yes">
	<cfset var v = structNew()>

	<cfset sc_password = pwd>

</cffunction> <!--- sc_setPassword --->


<cffunction name="sc_siteHasSSL" returntype="void" output="yes" access="public"
		hint="Ensure that SSL is set up for your site.">

	<cfset var cfhttp = "">

	<cftry>
		<cfhttp url="https://#cgi.server_name#" timeout="10" throwonerror="no">
		<cfcatch type="any">
			<cfreturn sc_formatResult(false, "SSL not enabled. Could not access https://#cgi.server_name# - #cfcatch.message# - #cfcatch.detail#")>
		</cfcatch>
	</cftry>

	<cfif cfhttp.statusCode eq "200 OK">
		<cfreturn sc_formatResult(true, "SSL enabled")>
	<cfelseif cfhttp.statusCode contains "Connection Failure">
		<cfreturn sc_formatResult(false, "SSL error accessing https://#cgi.server_name# : #cfhttp.errorDetail#")>
	<cfelse>
		<cfthrow message="Unhandled statuscode (#cfhttp.statusCode#) in sc_siteHasSSL()">
	</cfif>

</cffunction> <!--- sc_siteHasSSL --->



<cffunction name="sc_tableExists" returntype="void" output="yes" access="public"
		hint="Check to see if a table exists in a datasource. Can be used as a rudimentary check of
		whether the database schema's been loaded.">
	<cfargument name="datasourceName" type="string" required="yes">
	<cfargument name="tableName" type="string" required="yes">
	<cfset var v = structNew()>

	<!--- Don't try to pull any data in case the table referenced is large - leon 3/29/10 --->
	<cftry>

		<!--- Test in MySQL, Postgres, SQLite, etc - leon 3/29/10 --->
		<cfquery datasource="#datasourceName#" timeout="3">
			select * from #tableName# limit 0
		</cfquery>
		<cfset v.checkPassed = true>
		<cfset v.msg = "Table (#tableName#) in datasource (#datasourceName#) exists">

		<cfcatch type="any">
			<cftry>

				<!--- Test in MSSQL - leon 3/29/10 --->
				<cfquery datasource="#datasourceName#" timeout="3">
					select top 0 * from #tableName#
				</cfquery>
				<cfset v.checkPassed = true>
				<cfset v.msg = "Table (#tableName#) in datasource (#datasourceName#) exists">

				<cfcatch type="any">
					<cftry>

						<!--- Test in Oracle - leon 3/29/10 --->
						<cfquery datasource="#datasourceName#" timeout="3">
							select * from #tableName# where rownum < 1
						</cfquery>
						<cfset v.checkPassed = true>
						<cfset v.msg = "Table (#tableName#) in datasource (#datasourceName#) exists">

						<cfcatch type="any">
							<!--- All have failed. The table doesn't exist. - leon 3/29/10 --->
							<cfset v.checkPassed = false>
							<cfset v.msg = "Table (#tableName#) in datasource (#datasourceName#) does not exist">
						</cfcatch>
					</cftry>
				</cfcatch>
			</cftry>
		</cfcatch>
	</cftry>

	<cfset sc_FormatResult(v.checkPassed, v.msg)>

</cffunction> <!--- sc_datasourceExists --->


<cffunction name="sc_httpContent" returntype="void" output="yes" access="public">
	<cfargument name="path" type="string" required="yes" hint="A root-relative URL">
	<cfargument name="secure" type="boolean" required="yes">
	<cfargument name="redirect" type="boolean" required="yes">
	<cfargument name="content" type="string" required="yes">

	<cfset var url = sc_buildURL(arguments.path, arguments.secure)>
	<cfset var success = false>
	<cfset var message = "URL (#arguments.path#) HTTP response body">
	<cfset var response = "">

	<cftry>
		<cfset response = sc_httpRequest(url, arguments.redirect)>

		<cfif response.fileContent CONTAINS arguments.content>
			<cfset success = true>
			<cfset message = message & " contains '#arguments.content#'">
		<cfelse>
			<cfset message = message & " does not contain '#arguments.content#'">
		</cfif>

		<cfcatch>
			<cfset message = message & " #cfcatch.message#">
		</cfcatch>
	</cftry>

	<cfreturn sc_formatResult(success, message)>
</cffunction> <!--- sc_httpContent --->


<!--- TODO: recreate the private methods that this method requires (sc_httpRequest) --->
<cffunction name="sc_httpStatus" returntype="void" output="yes" access="public">
	<cfargument name="path" type="string" required="yes" hint="A root-relative URL">
	<cfargument name="secure" type="boolean" required="yes">
	<cfargument name="redirect" type="boolean" required="yes">
	<cfargument name="status" type="numeric" required="yes">

	<cfset var url = sc_buildURL(arguments.path, arguments.secure)>
	<cfset var success = false>
	<cfset var message = "URL (#arguments.path#) should respond with #arguments.status#, got ">
	<cfset var response = "">
	<cfset var responseStatus = "">

	<cfif arguments.status LT 200 OR arguments.status GT 599>
		<cfthrow message="Invalid status code">
	</cfif>

	<cftry>
		<cfset response = sc_httpRequest(url, arguments.redirect)>
		<cfset responseStatus = Val(response.statusCode)>
		<cfparam name="responseStatus" type="range" min="200" max="599">

		<cfif responseStatus EQ arguments.status>
			<cfset success = true>
		</cfif>
		<cfset message = message & responseStatus>

		<cfcatch>
			<cfset message = message & " #cfcatch.message#">
		</cfcatch>
	</cftry>

	<cfreturn sc_formatResult(success, message)>
</cffunction> <!--- sc_httpStatus --->


<cffunction name="sc_urlOK" returntype="void" output="yes" access="public"
		hint="Ensure that a '200 OK' status code is returned for a given root-relative URL.
			This can be used to check whether a webserver-based rewrite/redirect is in place.">

	<cfargument name="theURL" type="string" required="yes" hint="A root-relative URL">
	<cfargument name="useHTTPS" type="boolean" required="no" default="no" hint="Turn on only if site requires SSL">

	<!--- TODO: This should be rewritten to use sc_httpStatus, but that method is
		unfortunately compatible only with CF9+ --->

	<cfset var v = structNew()>
	<cfset var cfhttp = "">

	<cfset v.fqURL = sc_buildURL(theURL, useHTTPS)>

	<cftry>
		<cfhttp url="#v.fqURL#" timeout="10" throwonerror="no">
		<cfcatch type="any">
			<cfreturn sc_formatResult(false, "URL is not OK (#v.fqURL# - #cfcatch.message# - #cfcatch.detail#")>
		</cfcatch>
	</cftry>

	<cfif cfhttp.statusCode eq "200 OK">
		<cfreturn sc_formatResult(true, "URL is OK (#v.fqURL#)")>
	<cfelseif cfhttp.statusCode contains "Connection Failure">
		<cfreturn sc_formatResult(false, "URL is not OK (#v.fqURL# - #cfhttp.errorDetail#")>
	<cfelseif cfhttp.statusCode eq "403 Forbidden">
		<cfreturn sc_formatResult(false, "URL returns '403 Forbidden' (#v.fqURL#)")>
	<cfelseif cfhttp.statusCode eq "404 Not Found">
		<cfreturn sc_formatResult(false, "URL returns '404 Not Found' (#v.fqURL#)")>
	<cfelse>
		<cfthrow message="Unhandled statuscode (#cfhttp.statusCode#) in sc_urlOK()">
	</cfif>

</cffunction> <!--- sc_urlOK --->


<cffunction name="sc_urlProtected" returntype="void" output="yes" access="public"
		hint="Ensure that a '401 Authorization Required' status code is returned for a given root-relative URL.
			This can be used to check whether a webserver-based authentication is in place and supported.">

	<cfargument name="theURL" type="string" required="yes" hint="A root-relative URL">
	<cfargument name="useHTTPS" type="boolean" required="no" default="no" hint="Turn on only if site requires SSL">

	<!--- TODO: This should be rewritten to use sc_httpStatus, but that method is
		unfortunately compatible only with CF9+ --->

	<cfset var v = structNew()>
	<cfset var cfhttp = "">
	<cfset v.fqURL = "http#iif(useHTTPS,de('s'),de(''))#://#cgi.server_name##theURL#">

	<cftry>
		<cfhttp url="#v.fqURL#" timeout="10" throwonerror="no">
		<cfcatch type="any">
			<cfreturn sc_formatResult(false, "URL is not protected (#v.fqURL# - #cfcatch.message# - #cfcatch.detail#")>
		</cfcatch>
	</cftry>

	<cfif cfhttp.statusCode eq "401 Authorization Required">
		<cfreturn sc_formatResult(true, "URL is Protected (#v.fqURL#)")>
	<cfelseif cfhttp.statusCode contains "Connection Failure">
		<cfreturn sc_formatResult(false, "URL is not OK (#v.fqURL# - #cfhttp.errorDetail#")>
	<cfelseif cfhttp.statusCode eq "200 OK">
		<cfreturn sc_formatResult(false, "URL is not protected - returned '200 OK' (#v.fqURL#)")>
	<cfelseif cfhttp.statusCode eq "403 Forbidden">
		<cfreturn sc_formatResult(false, "URL returns '403 Forbidden' (#v.fqURL#)")>
	<cfelseif cfhttp.statusCode eq "404 Not Found">
		<cfreturn sc_formatResult(false, "URL returns '404 Not Found' (#v.fqURL#)")>
	<cfelse>
		<cfthrow message="Unhandled statuscode (#cfhttp.statusCode#) in sc_urlOK()">
	</cfif>
</cffunction> <!--- sc_urlProtected --->


<cffunction name="sc_verityCollectionExists" returntype="void" output="yes" access="public"
		hint="Ensure that a Verity collection is defined.">
	<cfargument name="collectionName" type="string" required="yes">
	<cfset var rsCollections = "">

	<cftry>
		<cfcollection action="list" name="rsCollections">
		<cfcatch type="coldfusion.tagext.search.SearchServiceUnavailableException">
			<cfreturn sc_formatResult(false, "Verity Collection (#collectionName#) could not be found. The ColdFusion Search service is not available.")>
		</cfcatch>
	</cftry>

	<cfif listFindNoCase(valueList(rsCollections.name), collectionName)>
		<cfreturn sc_formatResult(true, "Verity Collection (#collectionName#) exists")>
	<cfelse>
		<cfreturn sc_formatResult(false, "Verity Collection (#collectionName#) does not exist")>
	</cfif>

</cffunction> <!--- sc_verityCollectionExists --->

<!---
===============================
Begin "private" utility methods
===============================
--->

<cffunction name="sc_httpRequest" output="no" access="public">
	<cfargument name="url" type="string" required="yes">
	<cfargument name="redirect" type="boolean" required="yes">
	<cfset var httpResult = "">
	<cfhttp url = "#arguments.url#"
		method = "get"
		redirect = "#arguments.redirect#"
		timeout = 10
		throwOnError = false
		result = httpResult>
	<cfreturn httpResult>
</cffunction> <!--- sc_httpRequest --->


<cffunction name="sc_buildURL" returntype="string" output="no" access="public">
	<cfargument name="path" type="string" required="yes">
	<cfargument name="useHTTPS" type="boolean" required="yes">
	<cfreturn "http#iif(arguments.useHTTPS,de('s'),de(''))#://#cgi.server_name##arguments.path#">
</cffunction> <!--- sc_buildURL --->
