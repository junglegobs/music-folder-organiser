#!/bin/bash

# Clean up
rm -r library/
rm -r add2library/

# Make new folders
mkdir library
mkdir add2library
cp -r songs_backup_do_not_delete/* add2library/

# Run the test
../musicorg.sh ./library ./add2library
