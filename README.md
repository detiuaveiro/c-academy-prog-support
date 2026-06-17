# C-Academy Programming Support

Supporting material for the C-Academy programming track: setup scripts, code
examples, and utilities.

## Repository layout

```
.
├── bin/        # setup scripts and utilities
│   └── setup.sh
├── examples/   # code examples (added as the course progresses)
└── README.md
```

## Development environment

The course runs inside an **Ubuntu 26.04 LTS** virtual machine. Setup has two
parts: creating the VM on your own machine (manual), then provisioning the
tools inside it (automated).

### 1. Create the VM (host machine)

1. Download and install **VirtualBox**: https://www.virtualbox.org/wiki/Downloads
2. Install the **Extension Pack** from the same page.
3. Download the **Ubuntu 26.04 Desktop ISO** (Intel/AMD 64-bit):
   https://ubuntu.com/download
4. Create a new VM in VirtualBox and point it at the Ubuntu ISO, then install.

### 2. Provision the VM (inside Ubuntu)

Open a terminal in the VM. The recommended way is to download the script,
read it, then run it:

```bash
curl -fsSLO https://raw.githubusercontent.com/detiuaveiro/c-academy-prog-support/main/bin/setup.sh
less setup.sh        # take a look before running
bash setup.sh
```

Or, the one-liner (only run code you trust this way):

```bash
curl -fsSL https://raw.githubusercontent.com/detiuaveiro/c-academy-prog-support/main/bin/setup.sh | bash
```

The script installs and verifies:

- **Python** — `python3`, `python3-venv`, `python3-pip` (Python 3.14, the
  Ubuntu 26.04 default)
- **Java** — `default-jdk`, `maven`
- **Tools** — `git`, `vim`
- **VS Code** — plus the Python and Java extensions

It is idempotent (safe to re-run) and does not pin package versions — the LTS
archive already locks the relevant series.

#### Troubleshooting: Java certificates

If Maven or the JDK fail with TLS/certificate errors, repair the Java CA store:

```bash
sudo dpkg --purge --force-depends ca-certificates-java
sudo apt-get install ca-certificates-java
```

## Verifying your setup

```bash
python3 --version       # Python 3.14.x
python3 -m venv testenv # should create a venv without errors
java -version
mvn -version
git --version
echo "$JAVA_HOME"     # path under /usr/lib/jvm (set in /etc/environment)
```

> `JAVA_HOME` is written to `/etc/environment` by the setup script, so it
> applies system-wide on your next login. To use it in the current shell
> without logging out: `source /etc/environment && export JAVA_HOME`.
