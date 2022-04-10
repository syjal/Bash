# Minecraft Backup Script

# MCRCON Command
function consolemc {
  /opt/minecraft/utility/mcrcon/mcrcon -H 127.0.0.1 -P 25575 -p PASSWORD "$1"
}

# Server Directory
serverDir="/opt/minecraft/server"

# Backup Directory
backupDir="/opt/minecraft/backups"

# Date Format (YYYY-MM-DD-HH-MM)
dateFormat=$(date +%F-%H-%M)

# Disable Disk Writes
consolemc "save-off"

# Flush Pending Writes
consolemc "save-all"

# Create Backup Archive
tar -cpzf $backupDir/$dateFormat-server.tar.gz $serverDir

# Enable Disk Writes
consolemc "save-on"

# Delete Backups (> 7 days old)
find $backupDir -type f -mtime +7 -name "*.tar.gz" -exec rm {} \;
