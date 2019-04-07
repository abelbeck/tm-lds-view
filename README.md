# tm-lds-view
Display TimeMachines hardware "Locator Data Service" response

Use with TimeMachines https://timemachinescorp.com/ Hardware:<br />
* TM1000A firmware v2.6 or later<br />
* TM2000A firmware v0.3.3 or later<br />
```
Usage: tm-lds-view host-IP|host-name
```
Requires a POSIX shell (`bash`, `dash`, Busybox `ash`, etc.) and utilities: `nc`, `od` and `tr` (Busybox OK)

Tested on macOS 10.14, Debian/Ubuntu, AstLinux

-----------

Start by dowloading the `tm-lds-view.sh` script:
```
curl -O https://raw.githubusercontent.com/abelbeck/tm-lds-view/master/tm-lds-view.sh
```
Give the script a try (using IP address of TM1000A/TM2000A):
```
sh tm-lds-view.sh 10.10.50.5
```
If things go well you should see output similar to:
```
     Hardware: TM1000A
   IP Address: 10.10.50.5
  MAC Address: 70:b3:d5:7f:93:77
     Firmware: v2.6
      GPS Fix: 3D Lock
  NTP Lookups: 261
     GPS Time: 19:07:42 UTC
     Location: 40.81040, -96.62712
    Unit Name: time-gps
```

Finally, install the script (remove `.sh` suffix if desired) to a directory that is in your `$PATH` search path, and make the `tm-lds-view` script executable.
