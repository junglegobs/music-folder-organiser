#!/bin/bash

# First argument is the music folder which you want to move songs into while the second is the folder which has the songs to be sorted

getArtist() {
	ffprobe -loglevel error -show_entries format "$1" 2>&1 | sed -E -n 's|^TAG:artist=(.*)$|\1|Ip';
	# The arguments to ffprobe are there to get the output into a more useable format
	# The "$1" is simply passing the first argument of getArtistFF to ffprobe
	# The 2>&1 redirects stderr to stdout - why you would want to do this iunno, so errors are not printed to the command line?
	# sed -E means you run a pattern? the -n means sed to print to stdout only if it finds something
	# The \1 indicates there's only one `capture group` to be searched for (???)
	# The p at the end of sed just indicates that it's the end of the pattern
	# The I flag indicates to ignore the case of the letter (because sometimes artist is ARTIST)
	# Semi-colon for bash means end of command essentially
}

getAlbum() {
        ffprobe -loglevel error -show_entries format "$1" 2>&1 | sed -E -n 's|^TAG:album=(.*)$|\1|Ip';
}

getAlbumArtist() {
        ffprobe -loglevel error -show_entries format "$1" 2>&1 | sed -E -n 's|^TAG:album_artist=(.*)$|\1|Ip';
}

# WARNING: There are no checks done with this script really, so use this at your own risk.

# Check if music directory to organise passed as argument
if [ $# -eq 0 ]; then
    echo "No arguments supplied. Please specify folder to be sorted."
	exit 100
fi
musicdir=$(readlink -e $1) # Full path to directory

# Check if really a directory
if [[ ! -d "$musicdir" ]]; then
    echo "Mwomp mwomp! Not a directory."
    exit 101
fi 

# Check if second argument passed. If so, this is the directory
if [ $# -eq 2 ]; then
	musicdirold=$(readlink -e $2)
else
	musicdirold=$musicdir"_OLD" # Rename the directory being sorted
	rsync -a "$musicdir" "$musicdirold" # I've decided to use the backup option all the time just in case! Note that the names are such that the files are hidden sometimes.
fi

# Loop over entire directory to move files
find "$musicdirold" -type f | while read line; do
	if [[ $line == *".mp3" || $line == *".wav" || $line == *".aac" || $line == *".flac" || $line == *".aif"* || $line == *".m4a"* || $line == *".MP3"* ]]
	then
		artist=$(getArtist "$line")
		albumartist=$(getAlbumArtist "$line")
		album=$(getAlbum "$line")
		if [[ -z $artist ]]; then
			artist="Unknown Artist"
		fi
		if [[ -z $albumartist ]]; then
			albumartist=$artist # So that there's not lots of different folders with various different artists
		fi
		if [[ -z $album ]]; then
			album="Unknown Album"
		fi
		mkdir -p "$musicdir/$albumartist/$album"
		rsync -a "$line" "$musicdir/$albumartist/$album" # Rsync because mv is scary
		echo $line
	fi
done

# Clear empty directories and move remaining folders
if [[ -d "$musicdirold" ]]; then # Check if exists first
    musicdirbackups=$musicdir"_BACKUPS" 
    rsync -a "$musicdirold" "$musicdirbackups" # Move to a backup folder without overwriting any existing shit
    find "$musicdirbackups" -empty -type d -delete # Clear empty directories
fi
