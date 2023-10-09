import argparse
import dns.resolver
import socket
import ssl
from colorama import init, Fore

init(autoreset=True)  # Mengaktifkan mode otomatis reset warna

def get_host_from_ip(ip):
    try:
        host = socket.gethostbyaddr(ip)
        return host[0]  # Mengembalikan nama host
    except socket.herror:
        return "Tidak dapat menemukan nama host"

def print_colored(text, color=Fore.WHITE):
    print(color + text)

def print_separator():
    print(Fore.BLUE + "=" * 40)

def check_dns_records(domain, custom_server=None):
    resolver = dns.resolver.Resolver()

    # Mengatur DNS server kustom jika disediakan
    if custom_server:
        resolver.nameservers = [custom_server]

    print_colored(f"\nChecking DNS Records for {domain}\n", Fore.CYAN)

    try:
        # Pengecekan A record
        a_records = resolver.resolve(domain, 'A')
        print_colored("A Records:", Fore.YELLOW)
        for record in a_records:
            host_name = get_host_from_ip(record.address)
            print_colored(f"  IP: {record.address}, Hostname: {host_name}", Fore.GREEN)

        print_separator()

        # Pengecekan MX record
        mx_records = resolver.resolve(domain, 'MX')
        print_colored("MX Records:", Fore.YELLOW)
        for record in mx_records:
            print_colored(f"  {record}", Fore.GREEN)

        print_separator()

        # Pengecekan TXT record
        txt_records = resolver.resolve(domain, 'TXT')
        print_colored("TXT Records:", Fore.YELLOW)
        for record in txt_records:
            print_colored(f"  {record}", Fore.GREEN)

        print_separator()

        # Pengecekan NS record
        ns_records = resolver.resolve(domain, 'NS')
        print_colored("NS Records:", Fore.YELLOW)
        for record in ns_records:
            print_colored(f"  {record}", Fore.GREEN)

        print_separator()

        # Informasi SSL
        print_colored("SSL Information:", Fore.YELLOW)
        for record in a_records:
            try:
                context = ssl.create_default_context()
                with socket.create_connection((record.address, 443)) as sock:
                    with context.wrap_socket(sock, server_hostname=domain) as ssock:
                        cert = ssock.getpeercert()
                        print_colored(f"  IP: {record.address}", Fore.GREEN)
                        print_colored(f"    Subject: {cert['subject'][0][0]}", Fore.GREEN)
                        print_colored(f"    Issuer: {cert['issuer'][0][0]}", Fore.GREEN)
                        print_colored(f"    Expires: {cert['notAfter']}", Fore.GREEN)

            except Exception as e:
                print_colored(f"    SSL Information: {e}", Fore.RED)

    except dns.resolver.NXDOMAIN:
        print_colored(f"Domain {domain} tidak ditemukan.", Fore.RED)
    except dns.exception.DNSException as e:
        print_colored(f"Terjadi kesalahan: {e}", Fore.RED)

if __name__ == "__main__":
    # Mengatur argumen baris perintah
    parser = argparse.ArgumentParser(description="DNS and SSL Record Checker")
    parser.add_argument("-d", "--domain", type=str, required=True, help="Nama domain yang akan diperiksa")
    parser.add_argument("-s", "--server", type=str, default="8.8.8.8", help="DNS server kustom (default: 8.8.8.8)")

    # Mengambil argumen dari baris perintah
    args = parser.parse_args()

    # Memanggil fungsi untuk memeriksa DNS dan SSL records
    check_dns_records(args.domain, args.server)
