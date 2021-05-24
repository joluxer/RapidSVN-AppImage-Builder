RapidSVN AppImage builder
=========================

This project uses a Gentoo Linux system as a build base for
RapidSVN. Finally the ready built project is bundled as an
AppImage for distribution.

It is recommended, to use some older Gentoo LiveDVD,
as the glibc dependencies are more relaxed for this case.

Build time dependencies
-----------------------

Basic build time dependencies are fullfilled by default on
Gentoo Linux, when the Linux box is ready for build packages.

* dev-vcs/git
* net-misc/wget
* sys-devel/gcc-config
* wxWidgets, tested with x11-libs/wxGTK
* dev-vcs/subversion
* dev-libs/apr, dev-libs/apr-util
* app-misc/pax-utils

Run time dependencies
---------------------

The final run time Linux system must provide some libraries, which
are excluded off the AppImage by intent, as the system dependencies
are quite strong:

* libapr, libaprutil
* libgtk-x11
* libgdk-x11
* libnotify
* some more, which are usually available on a decent modern GUI Linux

SVN is explicitely no external dependency, as the SVN libraries ship
within the AppImage, due to the strong dependencies of RapidSVN to them.

Subversion version, working copy format
---------------------------------------

RapidSVN has a strong dependency on the SVN libraries, so these are
packaged within the AppImage.

You can check the shipped SVN version in the "Help->About" dialog window.

Nevertheless this might interfere with the locally installed SVN version,
which might have a different working copy format, so check this before
making annoying experiencies while doing mixed access onto your working
copy using RapidSVN and svn command line utilities.

Such mixed access is possible, but only, when both tool versions
use the same working copy format.

If either one recommends you to upgrade your working copy,
you are accessing a working copy with an older WC format using a newer
SVN version.

If either one tells you about unknown or too new working copy format,
your are accessing a working copy with a newer WC format using an older
SVN version.
