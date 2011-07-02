sanitycheck for ColdFusion
==========================

Overview
--------
sanitycheck is a library that allows ColdFusion developers to write "executable documentation" of their application's dependencies. This means that the dependencies are listed in one place, in a human-readable format, and can also be run to see which dependencies are being met. sanitycheck is compatible with ColdFusion 6 and up.

We've found it to be most useful when we're:

  * setting up new local copies of an application
  * moving an application to a new host/server

Please see docs/license.txt for usage terms.

Setup for Interactive Use
-------------------------
  1. Pull this repo in to your site at /sanitycheck/sanitycheck. Use of svn:externals or git submodules is recommended so that you can easily get future updates to sanitycheck. See the end of this file for detailed instructions.

  2. Create /sanitycheck/Application.cfm with a single space in it. It could
just be blank, but some versions of CF don't like 0-byte files.

  3. Create /sanitycheck/sanitycheck.cfm. A very simple version might look something like this:

        <cfinclude template="sanitycheck/lib_sanitycheck.cfm">
        <cfset sc_setPassword("bigSecret")>
        <cfset sc_CFVersion("7+")>
        <cfset sc_mappingExists("lib")>

  4. Create /sanitycheck/index.cfm containing:

        <cflocation url="sanitycheck.cfm" addtoken="no">

  5. Go to http://yourapp/sanitycheck and enter the password you defined in sc_setPassword() to see which of your dependencies pass.
          
Setup for Automated Use
-----------------------
This is rough and pretty untested. Use at your own risk!

  1. Complete the *Setup for Interactive Use* above
  2. Add the following to your Application.cfm or Application.cfc, preferably in the area where your application is initialized. This will cause sanitycheck to be run in the background and it's output logged.

        <cfif cgi.script_name does not contain "sanitycheck.cfm">
          <cfinclude template="sanitycheck/sanitycheck.cfm">
        </cfif>

Function Reference
------------------
All functions are prefixed with "sc_" as a way of avoiding namespace collision. This list include only functions you might want to call in your sanitycheck.cfm.

**sc_CFVersion(requiredVersion)**
> Specify the minimum or exact required version of ColdFusion. requiredVersion must be one or more digits and dots, optionally followed by a plus.

**sc_datasourceExists(datasourceName)**
> Ensure that a datasource is defined.

**sc_defaultSMTPServerDefined()**
> Ensure that ColdFusion has a default SMTP server (useful if your app doesn't specify one).

**sc_directoryExists(dirName)**
> Ensure that a directory exists. *dirName* must be a full path appropriate for the current platform. You can use expandPath() in your call to this (and other file/directory functions) for portability.

**sc_dirIsWritable(dir)**
> Checks to see if a directory is writable. *dir* is a fully-qualified directory path.

**sc_executableExists(fullPath, args, timeout)**
> Ensure that an executable program can be called. *fullPath* is the fully-qualified path to the executable. The optional *args* is arguments to make executable exit quickly (e.g. '-c exit' for bash). The optional *timeout* is in seconds.

**sc_fileExists(fileName)**
> Ensure that a file exists. Useful for config files that aren't kept in source control. *fileName* is a fully-qualified path.

**sc_fileIsWritable(file)**
> Checks to see if a file is writable by appending an empty string to it if it exists, or by checking the dir for writability if it doesn't. *file* is a fully-qualified file path.

**sc_mappingExists(mappingName)**
> Ensure that a mapping is defined. *mappingName* is just what it says. This function is a little buggy. We highly recommend using application-specific mappings (defined in your Application.cfc) instead of system-wide ones, but that's only available in CF8 and up.

**sc_scheduledTaskExists(taskURL, useHTTPS)**
> Ensure that a scheduled task exists. *taskURL* is a root-relative URL for the task to be executed. The optional *useHTTPS* is a boolean that you should turn on if your app requires SSL.

**sc_setPassword(pwd)**
> Sets the access password for running the script interactively. *pwd* is the password.

**sc_siteHasSSL()**
> Ensure that SSL is set up for your site.

**sc_tableExists(datasourceName, tableName)**
> Check to see if a table *tableName* exists in datasource *datasourceName*. Can be used as a rudimentary check of whether the database schema's been loaded.

**sc_urlOK(theURL, useHTTPS)**
> Ensure that a '200 OK' status code is returned for the root-relative URL *theURL*. This can be used to check whether a webserver-based rewrite/redirect is in place. The optional *useHTTPS* is a boolean that you should turn on if your app requires SSL.

**sc_verityCollectionExists(collectionName)**
> Ensure that the Verity collection *collectionName* is defined.

Pulling in sanitycheck with git submodule
-----------------------------------------
    cd your-git-project
    mkdir sanitycheck
    git add sanitycheck
    git submodule add git://github.com/singlebrook/sanitycheck.git sanitycheck/sanitycheck

Pulling in sanitycheck with svn:externals
-----------------------------------------
    cd your-svn-project
    mkdir sanitycheck
    svn add sanitycheck
    cd sanitycheck
    svn propset svn:externals "sanitycheck http://svn.github.com/singlebrook/sanitycheck.git" .
    svn commit # I can't seem to update successfully without committing first
    svn update
