#!/bin/bash
if [[ $(arch) != arm64 ]]; then
  echo "This script is only for M1 Macs"
  exit 1
fi

USER=$(whoami)
# DockerHub image to build.
IMAGE=jiahuac/cs1260:latest
# No slash at end.
IMAGE_HOME=/home/student
# Name of this image and host. This directory will also be linked into the image as ~/CONTAINER_NAME
CONTAINER_NAME=cs1260

echo "Setting up x86_64 Docker container. Make sure you're in the directory you would like to be linked into your container"

# Checks if brew is installed, and install if it not
which -s brew
if [[ $? != 0 ]]; then
  # Install Homebrew
  echo "🍺 Brew not found, installing"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "🍺 Brew found, updating"
  brew update
fi

which -s docker
if [[ $? != 0 ]]; then
  # Install Docker
  echo "🐳 Docker not found, installing"
  brew install docker
else
  echo "🐳 Docker found, you're set!"
fi

which -s limactl
if [[ $? != 0 ]]; then
  # Install Lima
  echo "🦙 Lima not found, installing"
  brew install lima
else
  echo "🦙 Lima found, you're set!"
fi

echo "🦙 Checking if Lima Docker instance exists:"
limactl list | grep docker
if [[ $? != 0 ]]; then
  echo "🦙 Setting up Lima context for Docker"
  cat <<EOT >>docker.yaml
# Example to use Docker instead of containerd & nerdctl
# $ limactl start ./docker.yaml
# $ limactl shell docker docker run -it -v $HOME:$HOME --rm alpine

# To run "docker" on the host (assumes docker-cli is installed):
# $ export DOCKER_HOST=$(limactl list docker --format 'unix://{{.Dir}}/sock/docker.sock')
# $ docker ...

arch: "x86_64"

# This example requires Lima v0.8.0 or later
images:
  # Try to use release-yyyyMMdd image if available. Note that release-yyyyMMdd will be removed after several months.
  - location: "https://cloud-images.ubuntu.com/releases/22.04/release-20220712/ubuntu-22.04-server-cloudimg-amd64.img"
    arch: "x86_64"
    digest: "sha256:86481acb9dbd62e3e93b49eb19a40c66c8aa07f07eff10af20ddf355a317e29f"
  - location: "https://cloud-images.ubuntu.com/releases/22.04/release-20220712/ubuntu-22.04-server-cloudimg-arm64.img"
    arch: "aarch64"
    digest: "sha256:e1ce033239f0038dca5ef09e582762ba0d0dfdedc1d329bc51bb0e9f5057af9d"
  # Fallback to the latest release image.
  # Hint: run "limactl prune" to invalidate the cache
  - location: "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
    arch: "x86_64"
  - location: "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-arm64.img"
    arch: "aarch64"

mounts:
  - location: "~"
    writable: true
  - location: "/tmp/lima"
    writable: true
# containerd is managed by Docker, not by Lima, so the values are set to false here.
containerd:
  system: false
  user: false
provision:
  - mode: system
    # This script defines the host.docker.internal hostname when hostResolver is disabled.
    # It is also needed for lima 0.8.2 and earlier, which does not support hostResolver.hosts.
    # Names defined in /etc/hosts inside the VM are not resolved inside containers when
    # using the hostResolver; use hostResolver.hosts instead (requires lima 0.8.3 or later).
    script: |
      #!/bin/sh
      sed -i 's/host.lima.internal.*/host.lima.internal host.docker.internal/' /etc/hosts
  - mode: system
    script: |
      #!/bin/bash
      set -eux -o pipefail
      command -v docker >/dev/null 2>&1 && exit 0
      export DEBIAN_FRONTEND=noninteractive
      curl -fsSL https://get.docker.com | sh
      # NOTE: you may remove the lines below, if you prefer to use rootful docker, not rootless
      systemctl disable --now docker
      apt-get install -y uidmap dbus-user-session
  - mode: user
    script: |
      #!/bin/bash
      set -eux -o pipefail
      systemctl --user start dbus
      dockerd-rootless-setuptool.sh install
      docker context use rootless
probes:
  - script: |
      #!/bin/bash
      set -eux -o pipefail
      if ! timeout 30s bash -c "until command -v docker >/dev/null 2>&1; do sleep 3; done"; then
        echo >&2 "docker is not installed yet"
        exit 1
      fi
      if ! timeout 30s bash -c "until pgrep rootlesskit; do sleep 3; done"; then
        echo >&2 "rootlesskit (used by rootless docker) is not running"
        exit 1
      fi
    hint: See "/var/log/cloud-init-output.log". in the guest
hostResolver:
  # hostResolver.hosts requires lima 0.8.3 or later. Names defined here will also
  # resolve inside containers, and not just inside the VM itself.
  hosts:
    host.docker.internal: host.lima.internal
portForwards:
  - guestSocket: "/run/user/{{.UID}}/docker.sock"
    hostSocket: "{{.Dir}}/sock/docker.sock"
message: |
  To run "docker" on the host (assumes docker-cli is installed), run the following commands:
  ------
  docker context create lima-{{.Name}} --docker "host=unix://{{.Dir}}/sock/docker.sock"
  docker context use lima-{{.Name}}
  docker run hello-world
  ------
EOT
  limactl start --tty=false docker.yaml
  rm docker.yaml
else
  echo "🦙 You've got a Lima context in your Docker already, you're all set!"
  limactl start --tty=false docker
fi

docker context list | grep lima | grep unix:///Users/$USER/.lima/docker/sock/docker.sock
if [[ $? != 0 ]]; then
  # Install Lima
  echo "🦙 Lima Docker context not found, setting up"
  docker context create lima --docker "host=unix:///Users/$USER/.lima/docker/sock/docker.sock"
else
  echo "🦙 Lima Docker context found, you're set!"
fi

docker context use lima

echo
docker ps | grep $IMAGE
if [[ $? != 0 ]]; then
  # Install Lima
  echo "🐳 Pulling $IMAGE image..."
  docker pull $IMAGE
  docker tag $IMAGE $CONTAINER_NAME
  echo "🐳 Setting up image..."
  docker run -d -it \
    -v $(pwd):$IMAGE_HOME/$CONTAINER_NAME \
    -v ~/.gitconfig:/etc/gitconfig \
    -v ~/.ssh:$IMAGE_HOME/.ssh \
    -h $CONTAINER_NAME --name $CONTAINER_NAME $CONTAINER_NAME
  echo "🐳 $IMAGE named $CONTAINER_NAME has been set up!"
else
  echo "🐳 You already have a $IMAGE image, you don't need to pull or create the image again!"
fi

rm -f start
cat <<EOT >>start
#!/bin/bash
if [[ \$(hostname) != $CONTAINER_NAME ]]; then
    # Starts container
    echo "🦙🐳 Starting container..."
    limactl start docker
    docker start $CONTAINER_NAME
else
    echo "🦙🐳 You're already in the container."
fi
EOT

rm -f stop
cat <<EOT >>stop
#!/bin/bash
if [[ \$(hostname) != $CONTAINER_NAME ]]; then
    # Starts container
    echo "🦙🐳 Stopping container..."
    docker stop $CONTAINER_NAME
    # Uncomment the below line if you also want to stop Lima every time you stop (this is slow).
    # limactl stop docker
else
    echo "🦙🐳 You're in the container, run this from outside the container."
fi
EOT

chmod +x ./start ./stop

echo """
You're all set up! To ever start your container, run:

./start

from this directory. To stop your container, run: 

./stop

from this directory. 

Each of these operations might take longer than normal since it also 
needs to start or stop the VM. Remember to do so so it doesn't
overwhelm your computer. 
"""
