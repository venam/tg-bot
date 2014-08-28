#!/bin/bash
# Basic dictionary
#
# Features:
# * Severe input coercion.
# * Cache system.
# * Case insensitive.
# * Colorized output
# * Try not to store useless data

if (( $# != 1 ))
then
echo "Please consider providing a word(one) to search."
exit 1
fi

if grep -qe '[^[:alpha:]]' <<< "$1" #severe input coercion
then
echo "Please express your word using letters only."
exit 1
fi

# only reach here if the input is a word

if [[ -v XDG_CACHE_HOME ]]
then
cache_dir="$XDG_CACHE_HOME/my-dict"
else
cache_dir="$HOME/.my-dict" #you asked for it
fi

mkdir --parents "$cache_dir" #no errors

word=$(tr "A-Z" "a-z" <<< "$1") #case insensitive

data_base_entry="$cache_dir/$word"

if [[ ! -a $data_base_entry ]] #if database entry doesn't exist
then #be carefull
#create the file first in case we fail at curl
if ! touch $data_base_entry
then
echo "Can't touch file: \"$data_base_entry\"."
exit 1
fi
if ! curl "dict://dict.org/d:$word:*" >> "$data_base_entry"
then # curl failed
rm "$data_base_entry" #no errors, because it should exist by now
echo "Failed to retrieve definition from dict.org."
exit 1
fi
#what if we didn't find anything?
if grep -q "552 no match" "$data_base_entry" # Try not to store useless data
then
rm "$data_base_entry" #no errors, because it should exist by now
echo "No match found. \"$word\""
exit 1
fi
fi

#anyway
# Riviera's trick ( presented by dualbus )
cat "$data_base_entry"
#grep -i --color -e "$word" -e "^" "$data_base_entry"
