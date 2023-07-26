#!/bin/bash
backup_dir="/var/backups/databases/"
backup_date=$(date +%Y-%m-%d)
number_of_days=15
databases=$(psql -l -t | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d')

for i in $databases;
do
    if [ "$i" != "postgres" ] && [ "$i" != "template0" ] && [ "$i" != "template1" ] && [ "$i" != "template_postgis" ];
    then
        echo "Dumping $i to $backup_dir$i"_"$backup_date.sql"
        pg_dump -x --no-owner --no-privileges $i > "$backup_dir$i"_"$backup_date.sql"
	pg_dumpall > all_privileges_dump.sql
    fi
done

find "$backup_dir" -type f -name "*.sql" -mtime +$number_of_days -exec rm -f {} \;
