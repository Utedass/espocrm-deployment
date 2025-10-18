#!/bin/sh

# Remove status outputs if they exist
rm -f /restoration-status/success.txt
rm -f /restoration-status/failure.txt

echo "Backup script envoced" | tee -a /restoration-status/log.txt

# Check if archive file exists
if [ ! -f /archive/restore-point.tar.gz ]; then
    echo "Restore point archive /archive/restore-point.tar.gz not found!" | tee -a /restoration-status/log.txt
    touch /restoration-status/failure.txt
    exit 1
fi

# Extract /archive/restore-point.tar.gz into /archive/unpacked
mkdir -p /archive/unpacked
tar xzf /archive/restore-point.tar.gz --strip-components=1 -C /restore

# Check that the unpacked database dump exists
if [ ! -f /restore/db-dump/mariadb-dump.sql ]; then
    echo "Database dump /restore/db-dump/mariadb-dump.sql not found after extraction!" | tee -a /restoration-status/log.txt
    touch /restoration-status/failure.txt
    exit 1
fi

RETRIES=10
DELAY=2

for i in $(seq 1 $RETRIES); do
    mariadb-admin ping -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" --silent
    STATUS=$?
    if [ $STATUS -eq 0 ]; then
        echo "Connected." | tee -a /restoration-status/log.txt
        
        # Restore the database using the mariadb client
        mariadb --host=$DB_HOST --user=$DB_USER --password=$DB_PASSWORD $DB_DATABASE < /restore/db-dump/mariadb-dump.sql

        STATUS=$?
        if [ $STATUS -ne 0 ]; then
            echo "Database restore failed with status $STATUS." | tee -a /restoration-status/log.txt
            touch /restoration-status/failure.txt
            exit $STATUS
        fi

        echo "Database restored successfully." | tee -a /restoration-status/log.txt
        touch /restoration-status/success.txt
        exit 0
    fi

    # Check for authentication or syntax errors (not connection-related)
    ERROR_OUTPUT=$(mariadb-admin ping -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" 2>&1)
    if echo "$ERROR_OUTPUT" | grep -q -E "Access denied|unknown option|unknown variable"; then
        echo "Fatal error: $ERROR_OUTPUT" | tee -a /restoration-status/log.txt
        touch /restoration-status/failure.txt
        exit 1
    fi

    echo "Connection failed (attempt $i/$RETRIES). Retrying in $DELAY sec..." | tee -a /restoration-status/log.txt
    sleep $DELAY
done

echo "Failed to connect after $RETRIES attempts." | tee -a /restoration-status/log.txt
touch /restoration-status/failure.txt
exit 1

