#!/bin/sh

iconutil -c icns ./iconbuilder.iconset --output Geany.icns
~/.local/bin/gtk-mac-bundler geany.bundle
cp -R Papirus Papirus-Dark ./Geany.app/Contents/Resources/share/icons
