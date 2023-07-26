#!/bin/bash

# Backup directory path
backup_dir="/var/backups/databases/"

# Current backup date
backup_date=$(date +%Y-%m-%d)

# Number of days to retain backups
number_of_days=15

# Get a list of all databases (excluding system databases)
databases=$(psql -l -t | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d')

for db_name in $databases; do
    # Exclude system databases from the backup
    if [ "$db_name" != "postgres" ] && [ "$db_name" != "template0" ] && [ "$db_name" != "template1" ] && [ "$db_name" != "template_postgis" ]; then
        echo "Dumping $db_name to $backup_dir$db_name"_"$backup_date.sql"
        pg_dump -x --no-owner --no-privileges $db_name > "$backup_dir$db_name"_"$backup_date.sql"
        # Uncomment the following line if you want to enable backup restoration on the same server
        # pg_dump $db_name > "$backup_dir$db_name"_"$backup_date.sql"
    fi
done

# Backup all privileges (users, roles, etc.) of the entire PostgreSQL cluster
pg_dumpall > "$backup_dir"all_privileges_dump.sql

# Clean up backups older than the specified number of days
find "$backup_dir" -type f -name "*.sql" -mtime +$number_of_days -exec rm -f {} \;
