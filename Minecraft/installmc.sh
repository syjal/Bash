#!/bin/bash
#
# Minecraft Install Script
#
# Written by: Jack Salem (jack.salem@outlook.com)
# April 10, 2022
#
# Installs Minecraft, Fabric, MCRCON, backup script,
# and system service.
#
# Change MCRCON password in this script, backup.sh,
# and minecraft.service to something other than
# PASSWORD.
#
# Change java memory values in minecraft.service to
# taste
######################################################

if (( $EUID != 0 )); then
    echo "This script needs to be run as root."
    exit
fi

# Run updates and install prerequisites
apt update
apt upgrade -y
apt install ca-certificates-java ssl-cert openssl ca-certificates -y
apt install mlocate openjdk-17-jre-headless -y
apt autoremove -y

# Update database for mlocate
updatedb

# Create minecraft user
useradd --system --user-group --create-home --home /opt/minecraft --shell /bin/bash minecraft

# Install Minecraft with Fabric
sudo -u minecraft bash <<EOF
  mkdir /opt/minecraft/{backups,server,utility}
  cd /opt/minecraft/server
  curl -o installer.jar https://maven.fabricmc.net/net/fabricmc/fabric-installer/0.11.0/fabric-installer-0.11.0.jar
  java -jar installer.jar server -mcversion 1.19 -downloadMinecraft
  rm installer.jar
  mv server.jar vanilla.jar
  mv fabric-server-launch.jar server.jar
  echo "serverJar=vanilla.jar" > fabric-server-launcher.properties
  java -jar server.jar
  sed -i 's/eula=false/eula=true/' eula.txt
EOF

# Install MCRCON
sudo -u minecraft bash <<EOF
  mkdir /opt/minecraft/utility/mcrcon
  wget https://github.com/Tiiffi/mcrcon/releases/download/v0.7.2/mcrcon-0.7.2-linux-x86-64.tar.gz --directory-prefix /tmp
  tar -xvf /tmp/mcrcon-0.7.2-linux-x86-64.tar.gz -C /opt/minecraft/utility/mcrcon
  chmod -R 750 /opt/minecraft/utility/mcrcon
  sed -i 's/enable-rcon=false/enable-rcon=true/' /opt/minecraft/server/server.properties
  sed -i 's/rcon.password=/rcon.password=PASSWORD/' /opt/minecraft/server/server.properties
  rm /tmp/mcrcon-0.7.2-linux-x86-64.tar.gz
EOF

# Install backup script with cron job
chmod 755 backup.sh
chown minecraft:minecraft backup.sh
mv backup.sh /opt/minecraft/utility/backup.sh
sudo -u minecraft bash <<EOF
  crontab -l > /opt/minecraft/mycron
  echo "0 3 * * * /opt/minecraft/utility/backup.sh > /opt/minecraft/utility/backup.log 2>&1" >> /opt/minecraft/mycron
  crontab /opt/minecraft/mycron
  rm /opt/minecraft/mycron
EOF

# Install minecraft.service in systemd
chmod 755 minecraft.service
chown root:root minecraft.service
mv minecraft.service /etc/systemd/system/minecraft.service
systemctl daemon-reload
systemctl start minecraft
systemctl stop minecraft

# Download Fabric mods
# Note to self: update versions when new releases become available.
sudo -u minecraft bash <<EOF
  cd /opt/minecraft/server/mods
  wget https://github.com/CaffeineMC/lithium-fabric/releases/download/mc1.18.2-0.7.10/lithium-fabric-mc1.18.2-0.7.10.jar
  wget https://github.com/CaffeineMC/phosphor-fabric/releases/download/mc1.18.x-0.8.1/phosphor-fabric-mc1.18.x-0.8.1.jar
EOF

# Download VanillaTweaks
# Includes: Armor Statues, AFK Display, Multiplayer Sleep, Coordinates HUD, Track Statistics, Track Raw Statistics,
# Durability Ping, Player Head Drops, Anti Enderman Grief, More Mob Heads, Silence Mobs, Double Shulker Shells,
# Wandering Trades (Hermit Edition), Spectator Conduit Power & Night Vision.
sudo -u minecraft bash <<EOF
  cd /opt/minecraft/server/world/datapacks
  wget https://vanillatweaks.net/download/VanillaTweaks_d539008_UNZIP_ME.zip
  unzip VanillaTweaks_d539008_UNZIP_ME.zip
  rm VanillaTweaks_d539008_UNZIP_ME.zip
EOF

# Start it all up
systemctl start minecraft
