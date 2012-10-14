#!/bin/sh

# Update all awstats sites there is a config file for
# This script runs awstats -update for all sites a config file
# exists in the awstats config dir. It runs the update process in parallel
# for several sites at once. Give the command line argument "-q" to suppress
# all but error output.

# (c) 2010 under GPL v2 by Adrian Zaugg.


# awstats main script
AWSTATS_BIN="/usr/lib/cgi-bin/awstats.pl"

# awstats configuration directory
CONF_DIR="/etc/awstats"

# normal awstats config files have this extension
CONF_EXT="conf"

# File to exclude
# Exclude this file, which isn't a config file for awstats, but
# also resides in the config directory. Note: Only
# files with an extension $CONF_EXT are considered anyway. 
CONF_TEMPLATE="awstats.default"

# Run with this priority (0: normal - 19: friendly)
NICENESS=16

# Maximum awstats update processes to run at once
MAX_PROCESSES=2

# Wait that many seconds when MAX_PROCESSES are running 
# to retry starting new update processes
RETRY=2



# ----don't edit below this line-----

# default to babbly, -q suppress output
SPEAK=true
if [ "$1" = "-q" ]; then
        SPEAK=false
fi

count_proc() {
        # count how many instances are already running
        COUNT_PROC=$(ps -o command -u "$(id -u)" | egrep -cwe '^(/bin/sh|/usr/bin/perl)* *'"$AWSTATS_BIN")
}

do_update() {
        # call awstats
        if $SPEAK; then
                nice -n "$NICENESS" "$AWSTATS_BIN" -update -config="$site" &
        else
                # Print errors only
                nice -n "$NICENESS" "$AWSTATS_BIN" -update -config="$site" > /dev/null &
        fi
}


# call awstats for each configured domain
COUNT_PROC=0
CURRENT_DIR="$(pwd)"
cd "$CONF_DIR"
for conf in *.$CONF_EXT; do

        notstarted=true

        # control number uf update processes
        while [ $notstarted = true ]; do
                count_proc
                if [ $COUNT_PROC -lt $MAX_PROCESSES ]; then
                        # exclude the template file
                        if [ "$conf" != "$CONF_TEMPLATE" ]; then
                                site="$(echo "$conf" | sed -e "s/^awstats\.\(.*\)\.conf$/\1/")"
                                $SPEAK && echo "`date "+%Y-%m-%d %H:%M:%S"`: Starting update for $site (already running: $COUNT_PROC)."
                                do_update
                        fi
                        notstarted=false
                        let "site_count += 1"
                        break;
                fi

                sleep "$RETRY"
        done

done
cd "$CURRENT_DIR"

# wait for all processes to finish
count_proc
if [ $COUNT_PROC -gt 0 ]; then
        $SPEAK && echo "`date "+%Y-%m-%d %H:%M:%S"`: All jobs started - $COUNT_PROC process(es) still runnning. Waiting..." 

        # wait for processes to finish
        while [ $COUNT_PROC -gt 0 ]; do
                sleep "$RETRY"
                count_proc
        done
fi

$SPEAK && echo "`date "+%Y-%m-%d %H:%M:%S"`: Finished. Statistics for $site_count sites updated."
exit 0

