import argparse
import dns.resolver
import socket
import ssl
import requests
from colorama import init, Fore

init(autoreset=True)

def get_host_from_ip(ip):
    try:
        host = socket.gethostbyaddr(ip)
        return host[0]
    except socket.herror:
        return "Tidak dapat menemukan nama host"

def print_colored(text, color=Fore.WHITE):
    print(color + text)

def print_separator():
    print(Fore.BLUE + "=" * 40)

def get_public_ip():
    try:
        response = requests.get('https://httpbin.org/ip')
        return response.json().get('origin', 'Tidak dapat mendapatkan IP publik')
    except Exception as e:
        return f'Tidak dapat mendapatkan IP publik: {e}'

def check_dns_records(domain, custom_server=None):
    resolver = dns.resolver.Resolver()

    if custom_server:
        resolver.nameservers = [custom_server]

    print_colored(f"\nChecking DNS Records for {domain}\n", Fore.CYAN)

    try:
        a_records = resolver.resolve(domain, 'A')
        print_colored("A Records:", Fore.YELLOW)
        for record in a_records:
            host_name = get_host_from_ip(record.address)
            print_colored(f"  IP: {record.address}, Hostname: {host_name}", Fore.GREEN)

        print_separator()

        mx_records = resolver.resolve(domain, 'MX')
        print_colored("MX Records:", Fore.YELLOW)
        for record in mx_records:
            print_colored(f"  {record}", Fore.GREEN)

        print_separator()

        txt_records = resolver.resolve(domain, 'TXT')
        print_colored("TXT Records:", Fore.YELLOW)
        for record in txt_records:
            print_colored(f"  {record}", Fore.GREEN)

        print_separator()

        ns_records = resolver.resolve(domain, 'NS')
        print_colored("NS Records:", Fore.YELLOW)
        for record in ns_records:
            print_colored(f"  {record}", Fore.GREEN)

        print_separator()

        print_colored("SSL Information:", Fore.YELLOW)
        try:
            context = ssl.create_default_context()
            with socket.create_connection((domain, 443)) as sock:
                with context.wrap_socket(sock, server_hostname=domain) as ssock:
                    cert = ssock.getpeercert()
                    print_colored(f"  Domain: {domain}", Fore.GREEN)
                    print_colored(f"    Subject: {cert['subject'][0][0]}", Fore.GREEN)
                    print_colored(f"    Issuer: {cert['issuer'][0][0]}", Fore.GREEN)
                    print_colored(f"    Expires: {cert['notAfter']}", Fore.GREEN)

        except Exception as e:
            print_colored(f"    SSL Information: {e}", Fore.RED)

        print_separator()

        public_ip = get_public_ip()
        print_colored(f"Public IP of the requester: {public_ip}", Fore.YELLOW)

    except dns.resolver.NXDOMAIN:
        print_colored(f"Domain {domain} tidak ditemukan.", Fore.RED)
    except dns.exception.DNSException as e:
        print_colored(f"Terjadi kesalahan: {e}", Fore.RED)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="DNS and SSL Record Checker")
    parser.add_argument("-d", "--domain", type=str, required=True, help="Nama domain yang akan diperiksa")
    parser.add_argument("-s", "--server", type=str, default="8.8.8.8", help="DNS server kustom (default: 8.8.8.8)")

    args = parser.parse_args()

    check_dns_records(args.domain, args.server)
