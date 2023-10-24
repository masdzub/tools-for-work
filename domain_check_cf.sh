#!/bin/bash

# ANSI color codes
GREEN='\033[1;32m'
CYAN='\033[1;36m'
RESET='\033[0m'

# Nama file yang berisi daftar domain
input_file="list_domains.txt"

# Buat nama file untuk hasil
output_file="cf_domains.txt"

# Periksa apakah berkas output sudah ada
if [ ! -f "$output_file" ]; then
    touch "$output_file"
else
    rm "$output_file"
    touch "$output_file"
fi


# Menghitung jumlah domain total dalam file
total_domains=$(wc -l < "$input_file")
processed_domains=0

# Panjang progres bar
bar_length=50

# Judul
echo -e "${GREEN}=== Pencarian Domain Cloudflare ===${RESET}"

# Loop melalui setiap baris dalam file
while IFS= read -r domain; do
    processed_domains=$((processed_domains + 1))

    # Menghitung persentase sejauh mana proses telah berjalan
    percentage_complete=$((processed_domains * 100 / total_domains))

    # Menghitung panjang progres bar
    bars="$(
      for ((i=0; i<bar_length; i++)); do
        if [[ $i -lt $((percentage_complete * bar_length / 100)) ]]; then
          echo -n "█"
        else
          echo -n " "
        fi
      done
    )"

    # Gunakan perintah host untuk mencari informasi DNS tentang domain
    host_output=$(host -t NS "$domain")

    # Periksa apakah hasilnya mengandung "cloudflare"
    if [[ $host_output == *cloudflare* ]]; then
        # Jika iya, tambahkan domain ke berkas hasil
        echo "$domain" >> "$output_file"
    fi

    # Membersihkan baris sebelum mencetak pesan status baru
    tput cuu1

    # Tampilkan pesan status dengan progres bar dan warna
    echo -e "Proses: [${CYAN}$bars${RESET}] ${GREEN}$percentage_complete%${RESET}"
done < "$input_file"

# Pesan penutup
echo -e "\n${GREEN}Pencarian selesai. Hasilnya disimpan dalam $output_file${RESET}"
