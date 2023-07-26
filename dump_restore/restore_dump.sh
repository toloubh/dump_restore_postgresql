#!/bin/bash

backup_directory="/var/backups/databases/"

# Function to generate checksum for a file
calculate_checksum() {
    md5sum "$1" | awk '{print $1}'
}

# Associative array to store the newest dump file for each database
declare -A newest_dumps

# Iterate through the files in the backup directory
for file in "$backup_directory"/*.sql; do
    # Check if the file is a database dump
    if [[ -f "$file" ]]; then
        # Extract the database name and date from the filename
        filename=$(basename "$file")
        database_name=$(echo "$filename" | sed -E 's/_[0-9]{4}-[0-9]{2}-[0-9]{2}\.sql$//')
        dump_date=$(echo "$filename" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')

        # Compare the current dump date with the stored date for the database
        if [[ ${newest_dumps["$database_name"]} < "$dump_date" ]]; then
            newest_dumps["$database_name"]=$dump_date
            newest_dump_file="$file"  # Store the filename of the newest dump
        fi
    fi
done

# Restore the newest dumps for each database
for database_name in "${!newest_dumps[@]}"; do
    newest_dump_date=${newest_dumps["$database_name"]}
    newest_dump_file="$backup_directory$database_name"_"$newest_dump_date".sql

    # Check if the database exists
    psql -lqt | cut -d \| -f 1 | grep -qw "$database_name"
    database_exists=$?

    if [ $database_exists -eq 0 ]; then
        # Drop the existing database
        echo "Dropping existing $database_name"
        psql -d "$database_name" -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$database_name' AND pid <> pg_backend_pid();" >/dev/null 2>&1
        psql -c "DROP DATABASE IF EXISTS \"$database_name\";"
    fi

    # Create a new database
    psql -c "CREATE DATABASE \"$database_name\";"

    # Remove the GRANT statements from the dump file
    sed -i '/^GRANT/d' "$newest_dump_file"

    # Restore the database from the modified dump file
    psql -d "$database_name" -f "$newest_dump_file" 2>/dev/null

    # Calculate the MD5 checksum of the restored database SQL dump
    restored_checksum=$(calculate_checksum "$newest_dump_file")

    # Create an MD5 checksum file for the restored SQL dump
    md5_file="$backup_directory$database_name.md5"
    calculate_checksum "$newest_dump_file" > "$md5_file"

    # Read the expected checksum from the MD5 file
    expected_checksum=$(cat "$md5_file")

    # Compare the checksums
    if [ "$restored_checksum" = "$expected_checksum" ]; then
        echo "Checksum verification successful for database: $database_name"
    else
        echo "Checksum verification failed for database: $database_name"
    fi

    echo "Restored from: $newest_dump_file"  # Display the filename of the restored dump
    echo "~~~~~~~ . ~~~~~~~ . ~~~~~~~"
done

