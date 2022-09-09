# cs1260 M1 Environment Setup Instructions
This contains a script that sets up local development environment for cs1260 for M1 Mac users. This can be adapted to different courses as well by using different Dockerfiles. This needs to be done since cs1260 expects a x86_64 environment. 

## Set Up
The easiest way to set this up is to create a directory for the course somewhere. This is where your assignments will be stored and synced up between your Docker container and your computer's operating system. From this directory, run: 
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jchen/cs1260-m1-env/main/setup.sh)"
```
This takes a bit of time (10-15 minutes) so let it run through entirely. At the end of this process you should have a working Docker container running x86_64 Debian (with the necessary course packages). 