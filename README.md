# toolbox - bring your own tools with you

On systems using `transactional-update` it is not really possible - due to the read-only root filesystem - to install tools to analyze problems in the currently running system as a reboot is always required. This makes it next to impossible to debug such problems.
`toolbox` is a small script that launches a podman container in a rootless or rootfull state to let you bring in your favorite debugging or admin tools in such a system.

You can also install and run GUI applications in your `toolbox` container. The root filesystem can be found at `/media/root`. In a "user toolbox" (i.e., one started with `toolbox -u`) the user's home directory is available in the usual place (`/home/$USER`).

## Usage     
     
The following options are avialbe in `toolbox`:
* `-h` or `--help`: Shows the help message
* `-u` or `--user`: Run as the current user inside the container
* `-R` or `--registry` `<registry>`: Explicitly specify the registry to use
* `-I` or `--image` `<image>`: Explicitly specify the image to pull
* `-r` or `--root`: Runs podman via sudo as root
* `-t` or `--tag` <tag>: Add <tag> to the toolbox name
    
You may override the following variables by setting them in `${HOME}/.toolboxrc`:
* `REGISTRY`: The registry to pull from. Default value is: `registry.opensuse.org`.
* `IMAGE`: The image and tag from the registry to pull. Default value is: `opensuse/toolbox`.
* `TOOLBOX_NAME`: The name to use for the local container. Default value is: `toolbox-${USER}`.
* `TOOLBOX_SHELL`: Standard shell if no other commands are given. Default value is: `/bin/bash`.

Example `.toolboxrc` file:
```
REGISTRY=my.special.registry.example.com
IMAGE=debug:latest
TOOLBOX_NAME=special-debug-container
TOOLBOX_SHELL=/bin/bash
```

If a config file is found, with `REGISTRY` and `IMAGE` defined, `${REGISTRY}/${IMAGE}` is used, overriding the default.
If `-R` and/or `-I` is/are used they override both the defaults and the content of `REGISTRY` and/or `IMAGE` from the config file.

### Rootless Usage

By default a toolbox is a rootless container. This means that being root inside the toolbox itself does not map with being root on the host,
e.g., as far as file permissions, access to special files, etc go.

#### Rootless Usage Example

```
$ id
uid=1000(dario) gid=100(users) groups=100(users),496(wheel),1000(dario)
$ toolbox
.toolboxrc file detected, overriding defaults...
Container 'toolbox-dario' already exists. Trying to start...
(To remove the container and start with a fresh toolbox, run: podman rm 'toolbox-dario')
toolbox-dario
Container started.
Entering container. To exit, type 'exit'.
...
toolbox-dario:/ # id
uid=0(root) gid=0(root) groups=0(root)
toolbox-dario:/ # ls -alF /media/root
total 88
drwxr-xr-x   1 65534 65534   256 Sep 12 10:33 ./
drwxr-xr-x   3 root  root     48 Jan 20 14:06 ../
drwxr-xr-x   1 65534 65534  1674 Dec 17 02:17 bin/
drwxr-xr-x   1 65534 65534   554 Jan 18 10:44 boot/
drwxr-xr-x  22 65534 65534  4300 Jan 19 22:22 dev/
...
toolbox-dario:/ # tcpdump -i em1
tcpdump: em1: You don't have permission to capture on that device
(socket: Operation not permitted)
...
toolbox-dario:/ # touch /media/root/etc/foo
touch: cannot touch '/media/root/etc/foo': Permission denied
```

#### Rootless Usage Example, With User Setup

In case a proper user environment is what one wants (e.g., for development), the `-u` (or `--user`) option can be used:

```
$ id -a
uid=1000(dario) gid=1000(dario) groups=1000(dario),...
$ toolbox -u
.toolboxrc file detected, overriding defaults...
Container 'toolbox-dario-user' already exists. Trying to start...
(To remove the container and start with a fresh toolbox, run: podman rm 'toolbox-dario-user')
toolbox-dario-user
Container started.
Entering container. To exit, type 'exit'.
dario@toolbox-dario-user:~> id
uid=1000(dario) gid=100(users) groups=100(users)
...
dario@toolbox-dario-user:~> echo $HOME
/home/dario
dario@toolbox-dario-user:~> ls -l /home
total 0
drwxr-xr-x 1 dario users 2290 Jan 20 14:33 dario
```

The user will have (paswordless) `sudo` access so, e.g., packages can be installed, etc:

```
$ ./toolbox -u
.toolboxrc file detected, overriding defaults...
Container 'toolbox-dario-user' already exists. Trying to start...
(To remove the container and start with a fresh toolbox, run: podman rm 'toolbox-dario-user')
toolbox-dario-user
Container started.
Entering container. To exit, type 'exit'.
...
dario@toolbox-dario-user:~> sudo zypper in gcc
Loading repository data...
Reading installed packages...
Resolving package dependencies...

The following 17 NEW packages are going to be installed:
  binutils cpp cpp9 gcc gcc9 glibc-devel libasan5 libatomic1 libgomp1 libisl22 libitm1 liblsan0 libmpc3 libtsan0 libubsan1 libxcrypt-devel linux-glibc-devel

17 new packages to install.
Overall download size: 42.6 MiB. Already cached: 0 B. After the operation, additional 179.7 MiB will be used.
Continue? [y/n/v/...? shows all options] (y):
...
dario@toolbox-dario-user:~> which gcc
/usr/bin/gcc
...
dario@toolbox-dario-user:~> sudo tcpdump -i em1
tcpdump: em1: You don't have permission to capture on that device
(socket: Operation not permitted)
```

### Rootful Usage

In fact, toolbox called by a normal user will start the toolbox container but the root filesystem of the host cannot be modified, special devices cannot be accessed, etc.
Running toolbox with sudo has the disadvantage, that the `.toolboxrc` in the `root` user home directory, and not the user's, is used.
To run the toolbox container with root rights, `toolbox --root` (or `-r`) has to be used.

#### Rootfull Usage Example

```
$ id
uid=1000(dario) gid=100(users) groups=100(users),496(wheel),1000(dario)
$ toolbox -r
.toolboxrc file detected, overriding defaults...
Spawning a container 'toolbox-dario' with image 'registry.opensuse.org/opensuse/toolbox'
08a8b984be2430a5d2cb38d55b26a93ddda3e5e5d183fbb75ac7287421a3f8be
toolbox-dario
Container created.
Entering container. To exit, type 'exit'.
...
toolbox-dario:/ # id
uid=0(root) gid=0(root) groups=0(root)
toolbox-dario:/ # ls -alF /media/root
total 88
drwxr-xr-x   1 root root   256 Sep 12 10:33 ./
drwxr-xr-x   1 root root     8 Jan 20 13:51 ../
drwxr-xr-x   1 root root  1674 Dec 17 02:17 bin/
drwxr-xr-x   1 root root   554 Jan 18 10:44 boot/
drwxr-xr-x  22 root root  4300 Jan 19 22:22 dev/
...
toolbox-dario:/ # tcpdump -i em1
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on em1, link-type EN10MB (Ethernet), capture size 262144 bytes
13:54:52.843421 IP 192.168.0.9.46690 > 192.168.0.255.32412: UDP, length 21
13:54:52.843655 IP 192.168.0.9.59404 > 192.168.0.255.32414: UDP, length 21
...
toolbox-dario:/ # touch /media/root/etc/foo
toolbox-dario:/ # ls -la /media/root/etc/foo
-rw-r--r-- 1 root root 0 Jan 20 14:09 /media/root/etc/foo
```

## Advanced Usage

### Running a command/program inside a toolbox

By default, toolbox drops the user into a shell, inside the container. It is possible, instead, to launch a specific command or program inside of the container:

```
$ toolbox -u sudo zypper in figlet
.toolboxrc file detected, overriding defaults...
Container 'toolbox-dario-user' already exists. Trying to start...
(To remove the container and start with a fresh toolbox, run: podman rm 'toolbox-dario-user')
toolbox-dario-user
Container started.
Entering container. To exit, type 'exit'.
Loading repository data...
Reading installed packages...
Resolving package dependencies...

The following NEW package is going to be installed:
  figlet

1 new package to install.
Overall download size: 3.0 MiB. Already cached: 0 B. After the operation, additional 75.2 MiB will be used.
Continue? [y/n/v/...? shows all options] (y):
...
...
$ toolbox -u figlet Hey from toolbox!
.toolboxrc file detected, overriding defaults...
Container 'toolbox-dario-user' already exists. Trying to start...
(To remove the container and start with a fresh toolbox, run: podman rm 'toolbox-dario-user')
toolbox-dario-user
Container started.
Entering container. To exit, type 'exit'.
 _   _               __
| | | | ___ _   _   / _|_ __ ___  _ __ ___  
| |_| |/ _ \ | | | | |_| '__/ _ \| '_ ` _ \ 
|  _  |  __/ |_| | |  _| | | (_) | | | | | |
|_| |_|\___|\__, | |_| |_|  \___/|_| |_| |_|
            |___/
 _              _ _               _
| |_ ___   ___ | | |__   _____  _| |
| __/ _ \ / _ \| | '_ \ / _ \ \/ / |
| || (_) | (_) | | |_) | (_) >  <|_|
 \__\___/ \___/|_|_.__/ \___/_/\_(_)
```

Of course, the command to run could even be a shell. However, for using a different shell than the default one inside of the toolbox, it is also possible to change the value of the `TOOLBOX_SHELL` variable within the config file.

### Use a custom image

toolbox uses an openSUSE-based userspace environment called `opensuse/toolbox` by default, but this can be changed to any container image. Simply override environment variables in `$HOME/.toolboxrc`:

#### toolbox

```
# cat ~/.toolboxrc
REGISTRY=registry.opensuse.org
IMAGE=opensuse/toolbox:latest
```

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
dario@toolbox-dario-user:~>
...
dario@toolbox-dario-user:~> exit
...
$ ./toolbox -u -t virt
Spawning a container 'toolbox-dario-user-virt' with image 'registry.opensuse.org/opensuse/toolbox'
0dbfbe02b0201bee9ae3a53c66db70ab621eae914c013e0b2e7a34837adde527
toolbox-dario-user-virt
Setting up user 'dario' (with 'sudo' access) inside the container...
(NOTE that, if 'sudo' and related packages are not present in the image already,
this may take some time. But this will only happen now that the toolbox is being created)
Container started successfully. To exit, type 'exit'.
dario@toolbox-dario-user-virt:~>
...
dario@toolbox-dario-user-virt:~> exit
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
toolbox-bob:/ #
```

## Troubleshooting

### Podman can't pull/run images with user
If you want to run a rootless `toolbox` setup you might need to add a range of UID and GID for the user you want to run `toolbox` with. Before adding UID and GID ranges check if `/etc/subuid` and `/etc/subgid` are actually empty. If empty you can run this as root to populate them:   

```
echo "podman_user:100000:65536" > /etc/subuid
echo "podman_user:100000:65536" > /etc/subgid
```

### GUI application can't connect to display 

This happens if you run the container as root - with sudo for example - while you're logged in as user to the desktop environment. The easiest way is to use `toolbox -u` with your user to setup a "rootless toolbox"  container for such cases.
