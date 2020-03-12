#!/bin/bash

#disable bluetooth
/usr/sbin/rfkill block bluetooth


connected_network="0"
connected_VPN="0"
previous_network="0"
previous_VPN="0"


#check if we're connected to wifi and VPN
check_connection () {
/usr/bin/nmcli device status | grep -q 'wifi      connected'
if [ $? == 0 ]; then
  previous_network="1"
fi

/usr/bin/expressvpn status | grep -q 'Connected'
if [ $? == 0 ]; then
  previous_VPN="1"
fi
}


connect_network () {
echo -e "\e[32m[!] \e[39mConnecting to $network."

/usr/bin/nmcli connection show | grep -q "$network"
if [ $? == 0 ]; then
  /usr/bin/nmcli connection up "$network" > /dev/null 2>&1
else
  read -s -p "Enter password: " pass
  echo
  /usr/bin/nmcli device wifi connect "$network" password $pass > /dev/null 2>&1
fi    

if [ $? -eq 0 ]; then
  connected_network="1"
  echo -e "\e[32m[!] \e[39mSuccess! \e[1;32mConnected to $network\e[21;22m"

else
  echo -e "\e[91m[!] \e[39mNetwork does not exist or failed to authenticate. Please try again."
  read -p "Which network? " network
fi
}


#connect to VPN
connect_VPN () {
  echo -e "\e[32m[!] \e[39mConnecting to VPN."
  /usr/bin/expressvpn connect smart | grep -q 'Connected'

  if [ $? -eq 0 ]; then
    connected_VPN="1"
    echo -e -n "\e[32m[!] \e[39mSuccess! " 
    /usr/bin/expressvpn status | head -1
    
    #check for updates
    /usr/bin/expressvpn status | grep -q 'newer'
    if [ $? == 0 ]; then
      /usr/bin/expressvpn status
    fi
  else
    echo -e "\e[91m[!] \e[39mVPN connection failed. Trying again."
  fi
}


check_connection
if [ $previous_network -eq "1" ] && [ $previous_VPN -eq "1" ]; then  
  echo -e "\e[32m[!] \e[39mAlready connected to network and VPN."
  exit 1

elif [ $previous_network -eq "1" ] && [ $previous_VPN -eq "0" ]; then 
  echo -e "\e[32m[!] \e[39mAlready connected to network"
  while [ $connected_VPN -eq "0" ]; do {
    connect_VPN
  }
  done
  exit 1

elif [ $previous_network -eq "0" ] && [ $previous_VPN -eq "0" ]; then
  if [ "$*" == "" ]; then
    
    #checks for line count in wifi list to ensure it's not empty	  
    lines=0
    while [[ $lines -le 1 ]]; do
      lines=$(/usr/bin/nmcli device wifi list | wc -l)
      echo -n "."
      sleep 1
    done

    /usr/bin/nmcli device wifi list
    read -p "Which network? " network
  else
    #enable -n and -h options
    while getopts ":n:h" opt; do
      case $opt in
        n) 
	  network="$OPTARG" >&2 ;;
	h)
          echo "Usage: connect [OPTION]... "
	  echo 'Example: connect -n "Starbucks WiFi"'
	  echo 
	  echo "Running with no arguments will display a list of available networks"
	  echo 
	  echo "Arguments-"
	  echo 
	  echo " -n	connect to known SSID with a saved connection profile"
	  echo
	  echo " -h     this help message"
	  exit 1 
	  ;;
	:) 
	  echo "Invalid option: -$OPTARG requires an argument" >&2 
	  exit 1 
	  ;;
	\?) 
	  echo "Invalid option: -$OPTARG" >&2
	  exit 1 ;;
      esac
    done
  fi

  while [ $connected_network -eq "0" ]; do {
    connect_network
  }
  done

  while [ $connected_VPN -eq "0" ]; do {
    connect_VPN
  }
  done
fi
