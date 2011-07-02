sanitycheck for ColdFusion
==========================

Overview
--------
sanitycheck is a library that allows ColdFusion developers to write "executable documentation" of their application's dependencies. This means that the dependencies are listed in one place, in a human-readable format, and can also be run to see which dependencies are being met.

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
Coming soon.

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
    svn commit # I can't seem to update successfully without commiting first
    svn update
