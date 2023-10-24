#!/bin/bash

# ANSI color codes
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# Nama file yang berisi daftar domain
file_domain="list_domains.txt"

# Buat nama file untuk hasil
file_hasil="cf_domains.txt"

# Periksa apakah berkas output sudah ada
if [ ! -f "$file_hasil" ]; then
    touch "$file_hasil"
else
    rm "$file_hasil"
    touch "$file_hasil"
fi


# Menghitung jumlah domain total dalam file
jumlah_domain=$(wc -l < "$file_domain")
jumlah_domain_yang_diproses=0

# Panjang progres bar
bar_length=50

# Judul
echo -e "${GREEN}=== Pencarian Domain Cloudflare ===${RESET}"

# Loop melalui setiap baris dalam file
while IFS= read -r domain; do
    jumlah_domain_yang_diproses=$((jumlah_domain_yang_diproses + 1))

    # Menghitung persentase sejauh mana proses telah berjalan
    persentase_lengkap=$((jumlah_domain_yang_diproses * 100 / jumlah_domain))

    # Menghitung panjang progres bar
    bars="$(
      for ((i=0; i<bar_length; i++)); do
        if [[ $i -lt $((persentase_lengkap * bar_length / 100)) ]]; then
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
        echo "$domain" >> "$file_hasil"
    fi

    # Membersihkan baris sebelum mencetak pesan status baru
    tput cuu1

    # Tampilkan pesan status dengan progres bar dan warna
    echo -e "Proses: [${CYAN}$bars${RESET}] ${GREEN}$persentase_lengkap%${RESET}"
done < "$file_domain"

# Pesan penutup
echo -e "\n${YELLOW}Pencarian selesai. Hasilnya disimpan dalam $file_hasil${RESET}\n"