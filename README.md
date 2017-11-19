# Docker based multiple Linux environment

Want to

- learn multiple Linux? 
- compare the difference between Ubuntu/Debian/CentOS/ArchLinux...?
- test your programs cross Linux?
- ...

Here is a toolset to

- setup multiple Linux systems in 1 command,
- backup/restore in 1 command,
- run/test commands/scripts cross Linux in 1 command.

Based on Docker, small and fast.

- Platform: Linux/Mac with Docker engine
- Tested: Debian 9.2, macOS Sierra 10.12.6, Docker 17.09.0-ce
- Ver: 0.5
- Updated: 11/19/2017
- Created: 11/5/2017
- Author: loblab

![Multiple Linux](https://raw.githubusercontent.com/loblab/docker-multi-linux/master/screenshot1.png)

## Quick start

- You should have docker engine installed. Ref [official guide](https://docs.docker.com/engine/installation/).
- Optional review/modify the configurations: 'config()' in 'mlx.sh', and mirror site in 'container/init.sh'.

```bash
./mlx.sh install         # Install this script as 'mlx'
mlx help                 # Help info
mlx init                 # Init multiple Linux systems
mlx logs | grep Done     # Check init progress 
mlx backup init          # Backup all systems, as 'init'
mlx se lsb_release -a    # Check version of each system
mlx pe xpm install wget  # Install wget on all systems
mlx backup snapshot1     # Backup all systems, as 'snapshot1'
mlx restore init         # Restore all systems, to 'init' status
docker attach debian9    # Do something in the systems ...
<Ctrl-P>, <Ctrl-Q>       # Quit a container, don't use 'exit'
mlx restore              # Restore all systems from current images, i.e. 'init' status
```

![Run on multiple Linux](https://raw.githubusercontent.com/loblab/docker-multi-linux/master/screenshot2.png)

## Tips

- You can use you home directory in every container, it auto mounted
- Working directory in containers is current directory in host
- If you 'exited' a container, the container will stop, you have to start it again, e.g. docker start debian9
- mlx se: for short/simple commands, output to screen
- mlx pe: for time cost jobs, output to log files as running in parallel
- mlx download: use it only when you need to force update the system images

User and sudo:

- mlx seu whoami: exec as normal user (not root)
- mlx seu sudo whoami: the normal user can sudo without password

Quotation marks: 

- mlx se pwd; hostname: 'hostname' exec in host (not container)
- mlx se "pwd; hostname": 'hostname' exec in containers
- mlx se echo $PATH: print PATH of host
- mlx se 'echo $PATH': print PATH of containers

## History

- 0.5 (11/19/2017): Rewrite container scripts as sh (instead of bash); support alpine Linux.
- 0.4 (11/18/2017): Extra options (e.g. publish ports) in init/restore. See config().
- 0.3 (11/13/2017): New features: exec as normal user (seu, peu); and sudo without password.
- 0.2 (11/11/2017): Rewrite to one script: 'mlx.sh'; add 'xpm' tool in container; many improvements.
- 0.1 (11/8/2017) : Support basic functions: init, backup, restore.

