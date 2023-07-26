#!/bin/bash
backup_dir="/var/backups/databases"
postgres_path="/var/lib/postgresql"
sudo chown -R postgres. "/home/deploy/restore_dump.sh"
sudo mv "/home/deploy/restore_dump.sh" "$postgres_path/"
if [ -d "$backup_dir" ];
then
        if [ -z "$(ls -A $backup_dir)" ];
        then
                echo "****There is no SQL Dump!!!****"
        else
                sudo -H -u postgres bash -c 'cd $postgres_path && ./restore_dump.sh'
                sudo rm -rf $backup_dir/*
        fi
else
        echo "There is no $backup_dir!!!"
fi
