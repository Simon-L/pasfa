#! /bin/bash

# Path to your database file
dbfile=$1

# Text file containing raw queries
# Here's how you add a paste forcing a shortid
# INSERT INTO pasfa_pastes (pid,name,content,created_at,expires_at,shortid,meta) VALUES
# 	 (13370335,'foobar.dsp','import("stdfaust.lib");
# // MAKE SURE TO DOUBLE YOUR SINGLE QUOTES!!!
# process = _;
# ','2023-12-01 05:05:09','Sat Dec 02 2023 05:05:09.000000000','ABCD','{}');
# INSERT INTO pasfa_shortids (shortid,pid) VALUES
# 	 ('ABCD',13370335);
sqlfile=$2

bkpdb="${dbfile}.backup.$(date +%F_%R)"
cp ${dbfile} ${bkpdb}

sqlite3 ${dbfile} -init ${sqlfile} "" ""
echo "ran: sqlite3 ${dbfile} -init ${sqlfile} \"\" \"\""