# toolbox - bring your tools with you

On systems using `transactional-update` it is not really possible due to the read-only root filesystem to install tools to analyze problems in the currently running system, a reboot is always required. Which makes it next to impossible to debug such problems.
`toolbox` is a small script that launches a container to let you bring in your favorite debugging or admin tools in such a system. The root filesystem can be found at `/media/root`.

## Usage

```
$ /usr/bin/toolbox
Spawning a container 'toolbox-root' with image 'registry.opensuse.org/opensuse/toolbox'
51e475f05d8bb8a5bf110bbecd960383bf8cfade1569587edef92076215f0eba
toolbox-root
Container started successfully. To exit, type 'exit'.
sh-5.0# ls -alF /media/root
...
sh-5.0# tcpdump -i ens3
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on ens3, link-type EN10MB (Ethernet), capture size 65535 bytes
...
sh-5.0# zypper in vim
Loading repository data...
Reading installed packages...
Resolving package dependencies...

The following 5 NEW packages are going to be installed:
  libgdbm6 libgdbm_compat4 perl vim vim-data-common

5 new packages to install.
Overall download size: 9.0 MiB. Already cached: 0 B. After the operation,
additional 49.4 MiB will be used.
Continue? [y/n/v/...? shows all options] (y):
...
sh-5.0# vi /media/root/etc/passwd
```

## Advanced Usage

### Use a custom image

toolbox uses an openSUSE-based userspace environment called `opensuse/toolbox` by default, but this can be changed to any container image. Simply override environment variables in `$HOME/.toolboxrc`:

#### toolbox

```
# cat ~/.toolboxrc
REGISTRY=registry.opensuse.org
IMAGE=opensuse/toolbox:latest
```

### Root container as normal user

toolbox called by a normal user will start the toolbox container, too, but the root filesystem cannot be modified. Running toolbox with sudo has the disadvantage, that the .toolboxrc from root and not the user is used. To run the toolbox container with root rights, `toolbox --root` has to be used.

### Automatically enter toolbox on login

Set an `/etc/passwd` entry for one of the users to `/usr/bin/toolbox`:

```
useradd bob -m -s /usr/bin/toolbox
```

Now when SSHing into the system as that user, toolbox will automatically be started:

```
# ssh bob@hostname.example.com
Last login: Thu Oct  3 16:52:16 2019 from 192.168.107.1
.toolboxrc file detected, overriding defaults...
Container 'toolbox-bob' already exists. Trying to start...
(To remove the container and start with a fresh toolbox, run: podman rm 'toolbox-bob')
toolbox-bob
Container started successfully. To exit, type 'exit'.
sh-5.0#
```
