
## **Slacker: Tools for Work**

This repository contains handy tools for various tasks related to system administration and information gathering.

### **Change Port SSH**

This tool allows you to change the SSH port of your system. This can be useful for security reasons by adding an extra layer of obscurity to your server.

**Usage:**

```bash
bash change_port_ssh.sh 

```
---

### **Domain Info**

This tool provides information about a domain, including its IP address, DNS records, and other relevant details.

**Usage:**

```bash
bash domain_info.sh -d yourdomain
bash domain_info.sh -d yourdomain -s dnsresolver

```

Replace **`[domain_name]`** with the domain you want to gather information about.

---

### **Info Domain**

This tool requires compilation before use. Make sure you have the necessary dependencies installed by running the following commands:

```bash
pip3 install pyinstaller
pip3 install pyopenssl
pip3 install colorama
pip3 install dnspython

```

After installing the dependencies, compile the **`info_domain.py`** script:

```bash
pyinstaller --onefile info_domain.py
```

The compiled binary will be available in the **`dist`** directory. You can then move it to a directory included in your system's PATH for easy access.

**Note:** Ensure that Python is in your system's PATH before compiling.

---

### **Domain SSH**
Perform DNS lookup from a domain and initiate SSH connections to the associated IP servers.
```
Usage: ./domain_ssh.sh [-d <Domain>] [-c] [-h]

Options:
  -d <domain>           Perform DNS lookup for the specified domain.
  -c                    Custom user and port to SSH after performing DNS lookup.
  -h                    Display this help message.

Example:
  ./domain_ssh.sh -d example.com -c
 ```

---

### Windows Plesk Generate Fix License

You can run the script with the following options:

- `-d <domain_name>`: Specify the server domain name.
- `-h`: Display the help message.

If the `-d` option is not provided, the script will prompt you to enter the server domain name.

#### Example

```bash
./plesk_management.sh -d example.com
```

#### Without the `-d` option

```bash
./plesk_management.sh
```

---

## **Reseller Usage**

This script calculates and displays disk usage for each reseller (excluding 'root') on your system.

```bash
./reseller_usage.sh
```

Ex. Output : 
```bash
Example Output:
python
Copy code
Checking reseller example1
Checking reseller example2
...
Done

Reseller Disk Usage:
reseller1: 10.50 GB
reseller2: 5.75 GB
...
```

---

## **Reseller Size**

This script calculates usage statistics for accounts managed by a specific reseller in cPanel.
```bash
./reseller_size.sh <reseller> <mail|non-mail>
```
> Replace `<reseller>` with the name of the reseller and `<mail|non-mail>` with either 'mail' to calculate mail usage or 'non-mail' to calculate usage excluding mail.

### Example:

Calculate mail usage for a reseller named 'myreseller':
```bash
./reseller_size.sh myreseller mail
```

Calculate non-mail usage for a different reseller:
```bash
./reseller_size.sh anotherreseller non-mail
```

### Notes

- This script requires access to system files (`/etc/trueuserowners`, `/var/cpanel/users/`, etc.) typically found on cPanel systems.
- Results are displayed in gigabytes (GB) and exclude usage results smaller than 10 megabytes (MB).


### **flood_block**

This tool have function to block all ip addresses flood suspect with csf base domlog access.

**Usage:**

```bash
bash flood_block.sh /var/log/apache2/domlogs/[domain_name]-ssl_log

```

Replace **`[domain_name]`** with the domain target of flood.

---



### **Disclaimer**

These tools are provided as-is and without warranty. Use them responsibly and only on systems you are authorized to access.

**Author:** Dzubayyan Ahmad
