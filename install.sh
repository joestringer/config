#!/bin/sh

# Link config files from current directory, excluding unnecessary files.
for f in `find . -maxdepth 1 \
        \! \( \
            -path '*.' \
            -o -path '*.config' \
            -o -path '*.git' \
            -o -path '*.gitignore' \
            -o -path '*install.sh*' \
        \)`; do
    ln -s $PWD/`echo $f | cut -c3-` ~
done

# Do .config/ separately to allow local configuration.
mkdir -p ~/.config/
for f in `find .config/* -maxdepth 0`; do
    ln -s $PWD/$f ~/.config
done
