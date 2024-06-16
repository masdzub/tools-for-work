
## **Slacker: Tools for Work**

This repository contains handy tools for various tasks related to system administration and information gathering.

### **Change Port SSH**

This tool allows you to change the SSH port of your system. This can be useful for security reasons by adding an extra layer of obscurity to your server.

**Usage:**

```bash
bash change_port_ssh.sh 

```

### **Domain Info**

This tool provides information about a domain, including its IP address, DNS records, and other relevant details.

**Usage:**

```bash
bash domain_info.sh -d yourdomain
bash domain_info.sh -d yourdomain -s dnsresolver

```

Replace **`[domain_name]`** with the domain you want to gather information about.

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
=======
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

### **Disclaimer**

These tools are provided as-is and without warranty. Use them responsibly and only on systems you are authorized to access.

**Author:** Dzubayyan Ahmad
