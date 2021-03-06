Geany for macOS
===============
Geany for macOS is a project that contains all the necessary configuration
files, themes, scripts and instructions to create the Geany app bundle and 
a dmg installer image for macOS.

Binaries
--------
The macOS binaries can be downloaded from the Geany Releases page:

<https://www.geany.org/Download/Releases>

Configuration
-------------
In addition to standard Geany configuration, the macOS bundle creates
its own configuration file under `~/.config/geany/geany_mac.conf` upon
first start. In this configuration file it is for instance possible
to override the used theme (light/dark) when autodetection based on
system macOS theme is not desired.

Files and Directories
---------------------
A brief description of the contents of the project directory:

### Directories
*	*Launcher*: A binary launcher which is used to set up environment
	variables to run Geany.
*	*Mojave-light-solid*: Mojave GTK 3 Theme
*	*Papirus, Papirus-Dark*: Papirus GTK 3 icon theme with lots of unneeded
	icons removed to save space.
*	*iconbuilder.iconset*: source Geany icons for the bundle.
*	*modulesets-stable*: copy of the modulesets-stable directory from
	the [gtk-osx](https://gitlab.gnome.org/GNOME/gtk-osx/) project containing
	dependency specifications. Since the upstram project is in a constant
	state of flux and fails to build frequently, this allows us to make
	a snapshot of a working configuration for our build.
*	*patches*: various patches fixing dependencies to enable bundling.
*	*utils*: various utility scripts.

### Configuration files
*	*Info.plist*: macOS application configuration file containing some basic
	information such as application name, version, etc. but also additional
	configuration including file types the application can open.
*	*geany.bundle*: configuration file describing the contents of the app bundle.
*	*geany.entitlements*: runtime hardening entitlements file.
*	*geany.modules*: JHBuild modules file with Geany dependencies.
*	*settings.ini*: default theme configuration file for GTK 3. 

### Scripts
*	*bundle.sh*: script creating the app bundle. 
*	*create_dmg.sh*: script calling create-dmg to create the dmg installer
	image. 
*	*notarize.sh*: script for notarizing the dmg using Apple notary service. 
*	*sign.sh*: script signing the app bundle. 

General Instructions
--------------------
For more general instructions about building and bundling macOS applications
please visit

*	<https://gitlab.gnome.org/GNOME/gtk-osx/>
*	<https://gitlab.gnome.org/GNOME/gtk-mac-bundler/>

The HOWTO below contains just the portions necessary/relevant for
building and bundling Geany.

Prerequisities
--------------
*	macOS
*	Xcode and command-line tools

JHBuild Installation
--------------------
To create the bundle, you need to first install JHBuild and GTK as described below.

1.	Create a new account for jhbuild (not necessary but this makes sure
	jhbuild does not interfere with some other command-line tools installed
	on your system).

2.	Get `gtk-osx-setup.sh` by
	```
	curl -L -o gtk-osx-setup.sh https://gitlab.gnome.org/GNOME/gtk-osx/raw/master/gtk-osx-setup.sh
	```
	and run it:
	```
	sh gtk-osx-setup.sh
	```

3.	Run
	```
	export PATH=$PATH:"$HOME/.new_local/bin"
	```
	to set path to jhbuild installed in the previous step.

4.	Add the following lines to `~/.jhbuildrc-custom`:
	```
	setup_sdk(target="10.9", sdk_version="native", architectures=["x86_64"])
	setup_release()
	```
	With this settings, the build creates a 64-bit binary that works on
	macOS 10.9 and later. macOS 10.9 is the first version which uses 
	libc++ by default which is now required by Scintilla and VTE libraries
	because of C++11 support. By default, jhbuild compiles without 
	optimization flags. The `setup_release()` call enables optimizations.

5.	Install GTK and all of its dependencies by running the following
	command inside the `geany-osx` directory:
	```
	jhbuild bootstrap-gtk-osx && jhbuild -m "https://raw.githubusercontent.com/geany/geany-osx/master/modulesets-stable/gtk-osx.modules" build meta-gtk-osx-bootstrap meta-gtk-osx-gtk3
	```
	It is possible to skip the module specification part `-m <url>`
	in which case the upstream module specification is used instead
	of our snapshot.

Geany Build
-----------
1.	Run
	```
	export LC_ALL=en_US.UTF-8; export LANG=en_US.UTF-8; export PYTHON=python3
	```
	(docutils fails when you do not set these variables).

2.	To build Geany, plugins and all of their dependencies, run one of
	the following commands inside the `geany-osx` directory  depending on
	whether to use Geany sources from the latest release tarball or current
	git master:
	* **tarball**
		```
		jhbuild -m `pwd`/geany.modules build geany-bundle-release
		```
	* **git master**
		```
		jhbuild -m `pwd`/geany.modules build geany-bundle-git
		```

Bundling
--------
1.  To build the launcher binary, run
	```
	xcodebuild -project Launcher/geany/geany.xcodeproj
	```
	inside the `geany-osx` directory.

2.	Run
	```
	jhbuild shell
	```
	to start jhbuild shell. 

	*The rest of this section assumes you are running from within the jhbuild shell.*

3.	To bundle all available Geany themes, get them from

	<https://github.com/geany/geany-themes>

	and copy the `colorschemes` directory under `$PREFIX/share/geany`.

4.	Inside the `geany-osx` directory run the following command to create
	the app bundle:
	```
	./bundle.sh
	```

5.	Optionally, if you have a development account at Apple and want to
	sign the resulting bundle, get the list of signing identities by
	```
	security find-identity -p codesigning
	```
	and use the whole string within apostrophes which contains
	"Developer ID Application: ..." in the following command:
	```
	export SIGN_CERTIFICATE="Developer ID Application: ..."
	```
	Then, run
	```
	./sign.sh
	```

Distribution
------------
1.	Get the `create-dmg` script from

	<https://github.com/andreyvit/create-dmg.git>

	and put it to your `$PATH`.

2.	Create the dmg installation image by calling
	```
	./create_dmg.sh
	```
	from within the `geany-osx` directory. If the `SIGN_CERTIFICATE` variable is
	defined (see above), the image gets signed by the specified certificate.

3.	Optionally, to get the image notarized by
	[Apple notary service](https://developer.apple.com/documentation/security/notarizing_your_app_before_distribution),
	run
	```
	./notarize.sh <dmg_file> <apple_id>
	```
	where `<dmg_file>` is the dmg file generated above and `<apple_id>`
	is the Apple ID used for your developer account. The script then
	prompts for an [app-specific password](https://support.apple.com/en-us/HT204397)
	generated for your Apple ID.

Maintenance
-----------
This section describes some maintenance-related activities which do not
have to be performed during normal bundle/installer creation:

*	To get the `Info.plist` file associations in sync with 
	`filetype_extensions.conf`, copy the filetype extension portion from
	`filetype_extensions.conf` to the marked place in `utils/plist_filetypes.py`
	and run the script. Copy the output of the script to the marked
	place in `Info.plist`.

*	Before the release, update the Geany version and copyright years inside
	`Info.plist` and `create_dmg.sh`. Also update the `-release` targets in
	`geany.modules` file to point to the new release. Dependencies inside
	`geany.modules` can also be updated to newer versions.

*	Copy `modulesets-stable` from [gtk-osx](https://gitlab.gnome.org/GNOME/gtk-osx/)
	into this project to get the latest dependencies (if it builds) and
	possibly modify it (if something isn't working).

*	To make sure nothing is left from the previous build when making a
	new release, run
	```
	rm -rf .new_local Source gtk .cache/jhbuild
	```

---

Jiri Techet, 2020
