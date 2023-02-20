#!/bin/bash

# Check if backup.conf exists
if [ ! -f backup.conf ]; then
    echo "backup.conf not found. Creating backup configuration file..."
    read -p "Enter MySQL username: " MYSQL_USER
    read -p "Enter MySQL password: " MYSQL_PASSWORD
    read -p "Enter backup directory: " BACKUP_DIR
    read -p "Enter S3 access key: " S3_ACCESS_KEY
    read -p "Enter S3 secret key: " S3_SECRET_KEY
    read -p "Enter S3 endpoint: " S3_ENDPOINT
    read -p "Enter S3 bucket name: " S3_BUCKET
    read -p "Enter backup API URL: " BACKUP_API_URL

    # Save the configuration to backup.conf
    echo "MYSQL_USER=\"$MYSQL_USER\"" >> backup.conf
    echo "MYSQL_PASSWORD=\"$MYSQL_PASSWORD\"" >> backup.conf
    echo "BACKUP_DIR=\"$BACKUP_DIR\"" >> backup.conf
    echo "S3_ACCESS_KEY=\"$S3_ACCESS_KEY\"" >> backup.conf
    echo "S3_SECRET_KEY=\"$S3_SECRET_KEY\"" >> backup.conf
    echo "S3_ENDPOINT=\"$S3_ENDPOINT\"" >> backup.conf
    echo "S3_BUCKET=\"$S3_BUCKET\"" >> backup.conf
    echo "BACKUP_API_URL=\"$BACKUP_API_URL\"" >> backup.conf

    echo "backup.conf created successfully."
fi

# Load the configuration file
source backup.conf

# Check for required plugins and install them if they are missing
if ! command -v s3cmd &> /dev/null; then
    echo "s3cmd not found. Installing s3cmd..."
    sudo apt-get update
    sudo apt-get install -y s3cmd
fi

if ! command -v curl &> /dev/null; then
    echo "curl not found. Installing curl..."
    sudo apt-get update
    sudo apt-get install -y curl
fi

# Set the timezone to Bangkok
sudo timedatectl set-timezone Asia/Bangkok

# Set the timestamp and backup directory
TIMESTAMP=$(date +%F-%H-%M)
BACKUP_DIR="$BACKUP_DIR/$TIMESTAMP"
mkdir -p $BACKUP_DIR

# Get the hostname
HOSTNAME=$(hostname)

# Display a message to indicate that the backup process has started
echo "Starting backup process for host $HOSTNAME..."

# Get a list of databases on the MySQL server
DATABASES=$(mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)")

# Dump each database to a separate backup file
for DB in $DATABASES; do
    BACKUP_FILE="$BACKUP_DIR/$DB-$TIMESTAMP.sql.gz"
    echo "Backing up database $DB to file $BACKUP_FILE..."
    mysqldump --user=$MYSQL_USER --password=$MYSQL_PASSWORD $DB | gzip > $BACKUP_FILE
done

# Set the S3 object key to include the hostname and date
S3_OBJECT_PREFIX="$HOSTNAME/$(date +"%Y/%m/%d")"
echo "Uploading backup files to S3 object prefix $S3_OBJECT_PREFIX..."

# Upload the backup files to S3
for FILE in $BACKUP_DIR/*.gz; do
    # Get the size of the backup file
    BACKUP_SIZE=$(du -h $FILE | awk '{print $1}')
    # Set the S3 object key to include the database name and date
    S3_OBJECT_KEY="$S3_OBJECT_PREFIX/$(basename $FILE)"
    echo "Uploading backup file $FILE to S3 object key $S3_OBJECT_KEY..."
    s3cmd --progress --access_key=$S3_ACCESS_KEY --secret_key=$S3_SECRET_KEY --host=$S3_ENDPOINT --host-bucket="%s.$S3_ENDPOINT" put $FILE s3://$S3_BUCKET/$S3_OBJECT_KEY > /dev/null
    # Call the API to notify of completion
   curl -s -X POST -d "file=$S3_OBJECT_KEY&size=$BACKUP_SIZE&hostname=$HOSTNAME&timestamp=$TIMESTAMP&database=$DB" $BACKUP_API_URL > /dev/null
done

# Set the S3 object key to delete
S3_OBJECT_DELETE="$HOSTNAME/$(date -d '5 day ago' +"%Y/%m/%d")"

# Delete the S3 objects in the S3_OBJECT_DELETE prefix
if s3cmd ls "s3://$S3_BUCKET/$S3_OBJECT_DELETE" > /dev/null 2>&1; then
    echo "Deleting objects in S3 prefix $S3_OBJECT_DELETE..."
    s3cmd del --recursive "s3://$S3_BUCKET/$S3_OBJECT_DELETE"
else
    echo "S3 prefix $S3_OBJECT_DELETE does not exist, no objects to delete."
fi
echo "Backup process completed successfully."
