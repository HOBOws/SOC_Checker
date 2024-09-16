Goal:
To stimulate and exercise the SOC team by simulating an attack on one of the clients in the network.

Target Selection:
The script automatically determines the host's address and filters itself out of the selection list.
Every address receives an index number.
Selection is done by simply selecting the index number representing the address.
Select "R" for a random target.

Attack Modes:
Bruteforce: Using Hydra (nmap brute NSE for SSH) with a list of 6x6 passwords crafted specifically to find nothing versus the user "abministrat0r" to make it look close enough at first glance, yet ensure nothing is actually found.
MiTM: Using Arpspoof and Gnome-terminal to simulate a man-in-the-middle attack between a selected target and the default gateway.
DHCP Starvation: Using Yersinia to starve the address pool. Note: This mode could potentially cause damage or disrupt the availability of the service. Use with caution and in appropriate environments.
Random: Select one of the attacks at random (including DHCP starvation).

Detection:
The script detects when the SOC team solves the problem by periodically checking [$route -n]. As soon as there is no value, it confirms that the host was kicked out of the network.
Logging:

LOG:
The script logs the target, total addresses on the network, attack mode (including service name in case of bruteforce), timestamp, duration, and the amount of related packets sent.
Logs are located at /var/log/SOCheck and named by timestamp.
