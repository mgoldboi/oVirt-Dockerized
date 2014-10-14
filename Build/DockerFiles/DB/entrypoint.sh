#!/bin/bash

export LANG=C 
export LC_ALL=C 
export PGDATA=/var/lib/pgsql/data

if [ ! -e /var/lib/pgsql/data/.initdb.done ]; 
then
	mkdir -p "$PGDATA" && chown postgres:postgres "$PGDATA" && chmod go-rwx "$PGDATA" ; [ -x /sbin/restorecon ] && /sbin/restorecon "$PGDATA"
	su postgres -c "/usr/bin/initdb --pgdata=$PGDATA --auth=ident"
	mkdir "$PGDATA/pg_log" && chown postgres:postgres "$PGDATA/pg_log" && chmod go-rwx "$PGDATA/pg_log"

	echo "host all all 0.0.0.0/0 trust" >> /var/lib/pgsql/data/pg_hba.conf
	# FIXME we shall not trust all!

	echo "listen_addresses='*'" >> /var/lib/pgsql/data/postgresql.conf

	touch /var/lib/pgsql/data/.initdb.done
fi 

su postgres -c "/usr/bin/postgres -D /var/lib/pgsql/data -p 5432"

