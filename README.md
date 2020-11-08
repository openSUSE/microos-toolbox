# toolbox - bring your own tools with you

On systems using `transactional-update` it is not really possible - due to the read-only root filesystem - to install tools to analyze problems in the currently running system as a reboot is always required. This makes it next to impossible to debug such problems.
`toolbox` is a small script that launches a podman container in a rootless or rootfull state to let you bring in your favorite debugging or admin tools in such a system. You can also install and run GUI applications in your `toolbox` container. The root filesystem can be found at `/media/root`.

## Usage     
     
The following options are avialbe in `toolbox`:
* `-h` or `--help`: Shows the help message
* `-u` or `--user`: Run as the current user inside the container
* `-r` or `--root`: Runs podman via sudo as root
* `-t` or `--tag` <tag>: Add <tag> to the toolbox name
    
You may override the following variables by setting them in ${TOOLBOXRC}:
* REGISTRY: The registry to pull from. Default value is: `registry.opensuse.org`.
* IMAGE: The image and tag from the registry to pull. Default value is: `opensuse/toolbox`.
* TOOLBOX_NAME: The name to use for the local container. Default value is: `"${HOME}"/.toolboxrc`.
* TOOLBOX_SHELL: Standard shell if no other commands are given. Default value is: `/bin/bash`.

Example toolboxrc:
* `REGISTRY`=my.special.registry.example.com
* `IMAGE`=debug:latest
* `TOOLBOX_NAME`=special-debug-container
* `TOOLBOX_SHELL`=/bin/bash"

### Rootfull Usage Example

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

## Rootless Usage 

In case a proper user environment is what one wants (e.g., for development), the `-u` (or `--user`) option can be used:

### Rootless Usage Example

```
$ id -a
uid=1000(dario) gid=1000(dario) groups=1000(dario),...
$ ./toolbox -u
Spawning a container 'toolbox-dario-user' with image 'registry.opensuse.org/opensuse/toolbox'
a0a5a332ee6d2a8dff6d8fb68a9ac70aeaacc9d531cf82f610ae48bec9e93ea1
toolbox-dario-user
Setting up user 'dario' inside the container...
(NOTE that, if 'sudo' and related packages are not present in the image already,
this may take some time. But this will only happen now that the toolbox is being created)
Container started successfully. To exit, type 'exit'.
dario@toolbox:~>
...
dario@toolbox:~> id -a
uid=1000(dario) gid=1000(dario) groups=1000(dario)
dario@toolbox:~> echo $HOME
/home/dario
dario@toolbox:~> ls $HOME/.. -l
total 0
drwxr-xr-x 1 dario dario 2422 Feb 14 10:22 dario
```

The user will have (paswordless) `sudo` access so, e.g., packages can be installed, etc:

```
$ ./toolbox -u
Spawning a container 'toolbox-dario-user' with image 'registry.opensuse.org/opensuse/toolbox'
4a05e36edb55776ae5f32cb736529ba94bdea4a39a8e5d6258ca230f646da733
toolbox-dario-user
Setting up user 'dario' (with 'sudo' access) inside the container...
(NOTE that, if 'sudo' and related packages are not present in the image already,
this may take some time. But this will only happen now that the toolbox is being created)
Container started successfully. To exit, type 'exit'.
dario@toolbox:~>
...
dario@toolbox:~> sudo zypper install gcc
Loading repository data...
Reading installed packages...
Resolving package dependencies...

The following 17 NEW packages are going to be installed:
  binutils cpp cpp9 gcc gcc9 glibc-devel libasan5 libatomic1 libgomp1 libisl22 libitm1 liblsan0 libmpc3 libtsan0 libubsan1 libxcrypt-devel linux-glibc-devel

17 new packages to install.
Overall download size: 42.6 MiB. Already cached: 0 B. After the operation, additional 179.7 MiB will be used.
Continue? [y/n/v/...? shows all options] (y):
...
dario@toolbox:~> gcc
gcc: fatal error: no input files
compilation terminated.
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

### Multiple Toolboxes

It is possible to want to create multiple toolboxes, especially user ones. For instance, one may want to create a special user toolbox, inside which doing development of virtualization related projects. This is possible by adding a tag to a toolbox name, via the `toolbox --tag <tag>` option:

```
$ podman ps --all
CONTAINER ID  IMAGE                                                             COMMAND               CREATED             STATUS                         PORTS  NAMES
b20985e6de68  registry.opensuse.org/opensuse/toolbox:latest                     /bin/bash             57 seconds ago      Exited (0) 3 seconds ago              toolbox-dario-user
...
$ ./toolbox -u
Container 'toolbox-dario-user' already exists. Trying to start...
(To remove the container and start with a fresh toolbox, run: podman rm 'toolbox-dario-user')
toolbox-dario-user
Container started successfully. To exit, type 'exit'.
...
$ ./toolbox -u -t virt
Spawning a container 'toolbox-dario-user-virt' with image 'registry.opensuse.org/opensuse/toolbox'
0dbfbe02b0201bee9ae3a53c66db70ab621eae914c013e0b2e7a34837adde527
toolbox-dario-user-virt
Setting up user 'dario' (with 'sudo' access) inside the container...
(NOTE that, if 'sudo' and related packages are not present in the image already,
this may take some time. But this will only happen now that the toolbox is being created)
Container started successfully. To exit, type 'exit'.
dario@toolbox:~>
...
dario@toolbox:~> exit
CONTAINER ID  IMAGE                                                             COMMAND               CREATED         STATUS                    PORTS  NAMES
0dbfbe02b020  registry.opensuse.org/opensuse/toolbox:latest                     /bin/bash             8 minutes ago   Exited (0) 6 minutes ago         toolbox-dario-user-virt
b20985e6de68  registry.opensuse.org/opensuse/toolbox:latest                     /bin/bash             10 minutes ago  Exited (0) 7 minutes ago         toolbox-dario-user
```

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

## Troubleshooting

#### Podman can't pull/run images with user
If you want to run a rootless `toolbox` setup you might need to add a range of UID and GID for the user you want to run `toolbox` with. Before adding UID and GID ranges check if `/etc/subuid` and `/etc/subgid` are actually empty. If empty you can run this as root to populate them:      
```echo "podman_user:100000:65536" > /etc/subuid
echo "podman_user:100000:65536" > /etc/subgid```     
     
#### GUI application can't connect to display 
This happens if you run the container as root - with sudo for example - while you're logged in as user to the desktop environment. The easiest way is to use `toolbox -u` with your user to setup a `rootless toolbox`  container for such cases. 