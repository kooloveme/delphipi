# Changes in DelphiPI versions #
**DelphiPI 0.63**
  * fixed [issue 42](https://code.google.com/p/delphipi/issues/detail?id=42)
**DelphiPI 0.60**
  * Delphi XE2 support

**DelphiPI 0.57**
  * Minor bug fixes and improvements
  * fixed [issue 35](https://code.google.com/p/delphipi/issues/detail?id=35)

**DelphiPI 0.56**
  * Compiled with STRINGCHECK OFF compiler option for better string performance
  * Package names are inferred from file names rather than package content, because some packages don't have this value set.
  * Added new sub strings for better Delphi version detection of packages. _(I am going to change this detection method with a better algorithm soon)_

**DelphiPI 0.55**
  * Tree, List and Delphi Version views for package list
  * fixed many UI bugs
  * This is a major step before I change user interface to what I have in my mind
  * fixed [issue 28](https://code.google.com/p/delphipi/issues/detail?id=28)
  * fixed [issue 29](https://code.google.com/p/delphipi/issues/detail?id=29)

**DelphiPI 0.55**
  * Tree, List and Delphi Version views for package list
  * fixed many UI bugs
  * This is a major step before I change user interface to what I have in my mind
**DelphiPI 0.52**
  * fixed [issue 28](https://code.google.com/p/delphipi/issues/detail?id=28)
  * fixed [issue 29](https://code.google.com/p/delphipi/issues/detail?id=29)
**DelphiPI 0.51**
  * Compiler directives can be set separately
**DelphiPI 0.50**
  * Compiled with Delphi 2010
  * Better logging
  * Minor fixes about compiler parameters
  * DCU output paths can be set separately
  * Compiled with JCL 2.0.1
  * Should support Delphi 2010
**DelphiPI 0.46**
  * Compiled with JCL 2.0.1
  * Should support Delphi 2010
**DelphiPI 0.45**
  * Fixed [issue 23](https://code.google.com/p/delphipi/issues/detail?id=23)
**DelphiPI 0.44**
  * Fixed an annoying bug: [issue 22](https://code.google.com/p/delphipi/issues/detail?id=22)
**DelphiPI 0.43**
  * Minor Bug Fixes: [issue 20](https://code.google.com/p/delphipi/issues/detail?id=20), [issue 21](https://code.google.com/p/delphipi/issues/detail?id=21)
**DelphiPI 0.42**
  * Fixed [issue 14](https://code.google.com/p/delphipi/issues/detail?id=14)
  * Packages that may not compile due to missing packages are displayed in red color
  * Compilation process can be canceled
  * Now user can see a full and brief compilation logs
  * Tested against Delphi 7, Delphi 2007 and Delphi 2009
**DelphiPI 0.40**
  * Bug fixes
  * Delphi 2009 compatibility
  * Compilation log is made more easy to read and follow
**DelphiPI 0.33**
  * Added internationalization support. Supported languages are: English and Turkish. New translations can be added.
  * Package selection page is improved in a way that user can select or unselect packages by using a file mask. The presentation of the packages are changed to a treeview so that you can see the folder structure.
  * Added support for setting custom output folders for BPL and DCP files.
  * Added a summary page to see which source folders added to IDE, which packages are compiled and which are failed.
  * Wizard is now resizable.
**DelphiPI 0.22**
  * Minor bug fixes
**DelphiPI 0.21**
  * User interface is made wizard like to make it easy to understand what is going on and going to be.
  * A new feature is added to register help files (.hlp) into openhelp of IDE which is present in Delphi7 and previous versions.

**DelphiPI 0.16**
  * fixes an issue about dcc32.exe accessviolation exception caused by path entries longer than 128 chars.