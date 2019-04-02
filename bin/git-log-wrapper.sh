#!/bin/env bash
# Author: Benjamin Hills <bhills@redhat.com>
#
# This script uses git log to list the number of lines changed by one or more
# # author(s) in a git repo. Run it with any amount of author names as
# # quoted strings as parameters and it will list the files changed, and lines
# # added and removed by one or more author(s).

pn="${0##*/}"

usage() {
				[ $# -ne 0 ] && echo "error: $pn: $*" >&2
				cat <<-EOF
				usage: $pn [-h] [-s START_DATE] [-d] author(s) -- List the number of files and lines changed by an author in a git repo

				where:
					-h  You're reading it
					-s  Starting date of calculation
					-d  debug output
					author(s)  The author(s) of the commits you want to calculate from

					example: $pn -s "1 Mar, 2019" "John Doe" "John Smith"

				EOF
				exit 1
}

date=
debug=

# Loop through the options, mostly to catch the date if they provide one
while getopts s:dh opt; do
    case "$opt" in
        h)  usage ;;
        s)  date="$OPTARG" ;;
        d)  debug=debug ;;
        *)  usage ;;
    esac
done
shift $((OPTIND - 1))

# Didn't provide any positional parameters
[ $# -gt 0 ] || usage 'input at least one author'

# Show debugging output if requested
[ -n "$debug" ] && set -x

total_changed=0
total_deletions=0
total_insertions=0

# Loop through each of the positional parameters provided
for author; do
		changed=0; deletions=0; insertions=0

		# Loop over output from "git log" for a single author
		while read added deleted _; do
			(( ++changed )) # each line is a file changed
			{ [[ $added = - ]] || [[ $deleted = - ]]; } && continue # skip binary files
			(( insertions += added ))
			(( deletions += deleted ))
		done < <(git log --numstat --format='' --author="$author" ${date:+--since="$date"})

		# Print results from that author
		printf '%s\n' "For author: $author ${date:+since "$date"}" \
									" Files changed: $changed" \
									" Deletions: $deletions" \
									" Insertions: $insertions"

		# Add to totals
		(( total_changed+=changed ))
		(( total_deletions+=deletions ))
		(( total_insertions+=insertions ))
done

# Print those totals
printf '%s\n' "Totals:" \
							" Files changed: $total_changed" \
							" Deletions: $total_deletions" \
							" Insertions: $total_insertions"

# Thanks to Charles Duffy on Stack Overflow for help with this code
# https://stackoverflow.com/questions/55425713/how-to-use-while-loop-inside-subshell-after-pipe
