DB_FILE="${FLY_BASE}/fly.db"


# Create db, if it doesn't exist.
if [ ! -f "$DB_FILE" ]
then
    echo 'Creating SQLite database.'
    DB_STRUCTURE="CREATE TABLE data (name TEXT UNIQUE, path TEXT, created NUMERIC);";
    echo "$DB_STRUCTURE" > /tmp/fly_db_structure
    sqlite3 "$DB_FILE" < /tmp/fly_db_structure;
    rm -f /tmp/fly_db_structure;
fi

Db.insert() {
    sqlite3 "$DB_FILE" "INSERT INTO $1 ($2) VALUES ($3)"
}