# General #

This release is mainly focused on User Interface improvements. Package List page of the wizard is enhanced by 3 views for you to selected which packages you want to compile and install.

## Details ##

**Folder view** allows you to see packages by their physical locations on the disk.<br />
![http://wiki.delphipi.googlecode.com/hg/img/0.55/folder_view.png](http://wiki.delphipi.googlecode.com/hg/img/0.55/folder_view.png)<br />
<br />

Classic **list view** allows you to see all packages at once so you can easily see what packages have missing dependencies (visualized with red fore color)<br />
![http://wiki.delphipi.googlecode.com/hg/img/0.55/list_view.png](http://wiki.delphipi.googlecode.com/hg/img/0.55/list_view.png)<br />
<br />

**Delphi version view** groups packages by matching package names with common suffixes, therefore you can see what packages belong to what delphi version and decide to include in the compilation process.<br />
![http://wiki.delphipi.googlecode.com/hg/img/0.55/delphi_version_view.png](http://wiki.delphipi.googlecode.com/hg/img/0.55/delphi_version_view.png)<br />
<br />

## Minor Improvements ##
  * An toolbar is placed over the package list for easy access to common operations
  * Wizard will remember what packages you have selected as you navigate between pages back and forth.

## Known Issues ##
  * Performance of the package list page is very poor for now, there is still room for optimization. It will get better in the next releases.
  * Packages might be grouped under wrong Delphi versions, I might have to change the current algorithm that is used for Version detection.

Please leave a comment for problems and suggestions.