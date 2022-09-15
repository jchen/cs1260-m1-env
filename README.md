# cs1260 M1 Environment Setup Instructions
This contains a script that sets up local development environment for cs1260 for M1 Mac users. This can be adapted to different courses as well by using different Dockerfiles. This needs to be done since cs1260 expects a x86_64 environment. 

## Set Up
The easiest way to set this up is to create a directory for the course somewhere. This is where your assignments will be stored and synced up between your Docker container and your computer's operating system. From this directory, run: 
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jchen/cs1260-m1-env/main/setup.sh)"
```
This takes a bit of time (10-15 minutes) so let it run through entirely. At the end of this process you should have a working Docker container running x86_64 Debian (with the necessary course packages). 

## Post Set Up
After the setup script has completed, the resulting `./start` script will start the container, and the `./stop` script will stop it. If you also wish to stop Lima, you can uncomment that line from the `stop` script (this increases startup times). 

To enter the container, run `./start` from your terminal. If, once you enter the container, dune isn't available, run `eval $(opam env)`. If dune is still not available or, for whatever reason, something doesn't work, run the commands in [this script](https://github.com/BrownCS1260/devenv/blob/main/home/setup-2.sh) in order.
