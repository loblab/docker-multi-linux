# Docker based multiple Linux environment

Want to
- learn multiple Linux? 
- compare the difference between Ubuntu/Debian/CentOS/ArchLinux....?
- test your programs cross Linux?
...
Here is the toolset to 
- setup/backup/restore multiple Linux systems, 
- run/test commands/scripts cross Linux.
Based on Docker, small and fast.

- Platform: Linux/Mac with Docker engine
- Tested: Debian 9.2, macOS Sierra 10.12.6, Docker 17.09.0-ce
- Ver: 0.2
- Updated: 11/11/2017
- Created: 11/5/2017
- Author: loblab

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

## History

- 0.2 (11/11/2017): Rewrite to one script: 'mlx.sh'; add 'xpm' tool in container; many improvements
- 0.1 (11/8/2017) : Support basic functions: init, backup, restore
