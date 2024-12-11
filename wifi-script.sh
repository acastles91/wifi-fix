#!/bin/bash

DELAY=5  # Delay between checks in seconds
MAX_RETRIES=5 # Maximum number of retries
RETRY_COUNT=0

# Path where the USB drive will be mounted
MOUNT_POINT="/mnt/usb"

# Name of the file with WiFi credentials
FILENAME="wifi.txt"

# Create mount point directory if it doesn't exist


#mkdir -p $MOUNT_POINT

# Wait before starting the process
sleep 5

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do

    # Attempt to mount the USB drive
if sudo mount -t vfat -o rw,user,umask=000 /dev/sda1 $MOUNT_POINT; then
	exec 2>>$MOUNT_POINT/wifi_connection_log.txt
	echo "$(date): USB drive successfully mounted"  >> $MOUNT_POINT/wifi_connection_log.txt
   else
        echo "Failed to mount USB drive."
fi

        # Check if wifi.txt exists
        if [ -f "$MOUNT_POINT/$FILENAME" ]; then
            # Read SSID and Password from the file
            SSID=$(sed -n '1p' $MOUNT_POINT/$FILENAME)
            PASSWORD=$(sed -n '2p' $MOUNT_POINT/$FILENAME)

            # Check SSID is not "network"
            if [ "$SSID" != "network" ]; then
		if nmcli dev wifi list | grep -q "$SSID"; then
                	if nmcli dev wifi connect "$SSID" password "$PASSWORD" >> $MOUNT_POINT/wifi_connection_log.txt 2>&1; then
                    # If the connection is successful, log it and enable autoconnect
                    		nmcli connection modify "$SSID" connection.autoconnect yes
                    		echo "$(date): Successfully connected to $SSID" >> $MOUNT_POINT/wifi_connection_log.txt 2>&1
                    		# Exit the loop after successful connection
                    		break
                	else
                    	# Log failure to connect
                    	echo "$(date): Failed to connect to $SSID" >> $MOUNT_POINT/wifi_connection_log.txt
			fi
            	else
                	echo "The network was not found during the scan"
		fi
	else
        	echo "The first line is 'network', skipping Wi-Fi connection attempt."
            fi
        else
            echo "wifi.txt not found."
        fi
 
    # wifi is not ready, wait and then try again
    RETRY_COUNT=$((RETRY_COUNT+1))
    sleep $DELAY

done
