#!/bin/bash

# Tool for check MySQL size 
# (c) 2023 Dzub DomaiNesia

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Fungsi bantuan untuk menampilkan pesan tentang cara menggunakan skrip
usage() {
    echo -e "${RED}Usage: $0 [-a] [-u <schema>] [-d <database>]${NC}\n"
    echo "Options:"
    echo -e "  ${GREEN}-a${NC} : Check size of all databases"
    echo -e "  ${GREEN}-u${NC} : Check size of a specific user/schema"
    echo "       Usage: $0 -u <user/schema>"
    echo -e "  ${GREEN}-d${NC} : Check sizes of all tables in a specific database"
    echo "       Usage: $0 -d <database>"
    exit 1
}

# Fungsi untuk memeriksa ukuran semua database
check_all_db_size() {
    mysql -e "SELECT table_schema AS \`Database\`,
    ROUND(SUM(data_length + index_length) / (1024 * 1024), 2) AS \`Size (MB)\`
    FROM information_schema.tables
    GROUP BY table_schema
    ORDER BY SUM(data_length + index_length) DESC;"
}

# Fungsi untuk memeriksa ukuran dari user/schema tertentu
check_db_size_user() {
    local schema=$1
    mysql -e "SELECT table_schema AS \`Database\`, 
            ROUND(SUM(data_length + index_length) / (1024 * 1024), 2) AS \`Size (MB)\`
            FROM information_schema.tables
            WHERE table_schema LIKE '${schema}%'
            GROUP BY table_schema
            ORDER BY \`Size (MB)\` DESC;"
}

# Fungsi untuk memeriksa ukuran semua tabel dalam database tertentu
check_db_table_user() {
    local database=$1
    mysql -e "SELECT table_name AS 'Table', 
            ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)' 
            FROM information_schema.tables 
            WHERE table_schema = '${database}' 
            ORDER BY (data_length + index_length) DESC;"
}

# Memeriksa jumlah argumen yang diberikan
if [ $# -eq 0 ]; then
    usage
fi

# Memproses opsi yang diberikan
while getopts ":au:d:" opt; do
    case $opt in
        a) echo -e "${YELLOW}Checking size of all databases:${NC}" ; check_all_db_size ;;
        u) echo -e "${YELLOW}Checking size of user/schema '${OPTARG}':${NC}" ; check_db_size_user "$OPTARG" ;;
        d) echo -e "${YELLOW}Checking sizes of all tables in database '${OPTARG}':${NC}" ; check_db_table_user "$OPTARG" ;;
        *) usage ;;
    esac
done

shift $((OPTIND -1))
