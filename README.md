# PowershellSSHManager
## Screeshot
![Screenshot](https://github.com/tuaninbox/PowershellSSHManager/blob/main/Screenshot.png?raw=true)
## Start 
- Change config in devmgmt.ini 
- .\start.ps1
- Devices are listed in devices.csv. Use this link https://ozh.github.io/ascii-tables/ to generate table in screenshot, with numbers matching numbers in devices.csv. Alternatively, script can generate menu from devices.csv file, just swap the name of function Print-Menu -> Print-Menu2 and Print-Menu1 -> Print-Menu
- Credentials are encrypted in credential.xml
- Certificate file is in pfx format so private key can be encrypted
- start.ps1 will close menu after timeout (defined in start.ps1) and delete certificate so credentials are protected
