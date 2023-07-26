#!/bin/bash
backup_dir="/var/backups/databases"
echo $backup_dir
postgres_path="/var/lib/postgresql"
echo $postgres_path

if [ -d "$backup_dir" ];  # Use -d to check if $backup_dir is a directory.
then
    sudo -H -u postgres bash -c 'cd $postgres_path && ./get_dump.sh'
else
    echo "There is no directory $backup_dir!!!"
    sudo mkdir -p $backup_dir
    sudo chown -R postgres. $backup_dir
    sudo -H -u postgres bash -c 'cd $postgres_path && ./get_dump.sh'
fi
