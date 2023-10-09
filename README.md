# Tools for Work

## **Tools for Work**

This repository contains handy tools for various tasks related to system administration and information gathering.

### **Change Port SSH**

This tool allows you to change the SSH port of your system. This can be useful for security reasons by adding an extra layer of obscurity to your server.

**Usage:**

```bash
bashCopy code
bash change_port_ssh.sh 

```


### **Domain Info**

This tool provides information about a domain, including its IP address, DNS records, and other relevant details.

**Usage:**

```bash
bashCopy code
bash domain_info.sh -d yourdomain
bash domain_info.sh -d yourdomain -s dnsresolver

```

Replace **`[domain_name]`** with the domain you want to gather information about.

### **Info Domain**

This tool requires compilation before use. Make sure you have the necessary dependencies installed by running the following commands:

```bash
bashCopy code
pip3 install pyinstaller
pip3 install pyopenssl
pip3 install colorama
pip3 install dnspython

```

After installing the dependencies, compile the **`info_domain.py`** script:

```bash
bashCopy code
pyinstaller --onefile info_domain.py

```

The compiled binary will be available in the **`dist`** directory. You can then move it to a directory included in your system's PATH for easy access.

**Note:** Ensure that Python is in your system's PATH before compiling.

### **Disclaimer**

These tools are provided as-is and without warranty. Use them responsibly and only on systems you are authorized to access.

**Author:** Dzubayyan Ahmad

**License:** This project is licensed under the [MIT License](https://chat.openai.com/c/LICENSE).