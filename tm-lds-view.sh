#!/bin/sh
##
## tm-lds-view
## 2019-04-07, Initial version
##
## Display TimeMachines hardware "Locator Data Service" response.
## Use with TimeMachines https://timemachinescorp.com/ Hardware:
## o TM1000A firmware v2.6 or later
## o TM2000A firmware v0.3.3 or later
##
## Copyright (C) 2019 Lonnie Abelbeck
##
## This is free software, licensed under the GNU General Public License
## version 3 as published by the Free Software Foundation; you can
## redistribute it and/or modify it under the terms of the GNU
## General Public License; and comes with ABSOLUTELY NO WARRANTY.
##
## The LDS response packet:
##   Bytes   | Description
## ----------+-----------------------------------------------
##     0     | ID: TM1000A = 0x04, TM2000A = 0x05
##    1-4    | IPv4 address
##    5-10   | MAC address
##   11-12   | Firmware version Major:Minor
##     13    | Lock status 0=No Lock, 1=2D Lock, or 2=3D Lock
##   14-17   | NTP Sync count, 32 bits, MSB to LSB
##   18-20   | Current Time, H:M:S, UTC
##   21-45   | Location of unit 25 bytes, Latitude, Longitude, null terminated
##   46-80   | Name of Time Server, null terminated
## ----------+-----------------------------------------------

host="$1"

check_commands()
{
  local cmd error IFS

  error=0
  IFS=' '
  for cmd in $*; do
    if ! command -v $cmd >/dev/null 2>&1; then
      echo "tm-lds-view: Missing required command: \"$cmd\"" >&2
      error=1
    fi
  done

  return $error
}

print_header()
{
  local title="$1" space center_col n i IFS

  # Adjust center_col to allow the output to line up as desired
  center_col=13

  n=$((center_col - ${#title}))
  space=""

  unset IFS
  for i in $(seq 1 $n); do
    space="$space "
  done

  printf "%s%s: " "$space" "$title"
}

pop_byte()
{
  byte="${data%% *}"
  data="${data#* }"
}

## main

if [ -z "$host" ]; then
  echo "Usage: tm-lds-view host-IP|host-name" >&2
  exit 1
fi

if ! check_commands nc od tr seq; then
  exit 1
fi

data="$(printf '\241\004\262' | nc -u -w1 $host 7372 | od -An -tx1 | tr -d '\n' | tr -s ' ')"

# Check if we received enough data...
# 80 bytes output as 2-hex plus 1-space for each byte, 80*(2+1)=240
if [ -z "$data" ]; then
  echo "tm-lds-view: No response from host: $host" >&2
  exit 1
fi
len=${#data}
if [ $len -lt 240 ]; then
  echo "tm-lds-view: Invalid $((len/3)) byte response from host: $host" >&2
  exit 1
fi

# remove leading space
data="${data# }"

printf "\n"

print_header "Hardware"
pop_byte
case $byte in
  04) printf "TM1000A\n" ;;
  05) printf "TM2000A\n" ;;
   *) printf "Unknown\n" ;;
esac

print_header "IP Address"
pop_byte ; x1="$byte"
pop_byte ; x2="$byte"
pop_byte ; x3="$byte"
pop_byte ; x4="$byte"
printf "%d.%d.%d.%d\n" $((0x$x1)) $((0x$x2)) $((0x$x3)) $((0x$x4))

print_header "MAC Address"
pop_byte ; x1="$byte"
pop_byte ; x2="$byte"
pop_byte ; x3="$byte"
pop_byte ; x4="$byte"
pop_byte ; x5="$byte"
pop_byte ; x6="$byte"
printf "%02x:%02x:%02x:%02x:%02x:%02x\n" $((0x$x1)) $((0x$x2)) $((0x$x3)) $((0x$x4)) $((0x$x5)) $((0x$x6))

print_header "Firmware"
pop_byte ; x1="$byte"
pop_byte ; x2="$byte"
printf "v%d.%d\n" $((0x$x1)) $((0x$x2))

print_header "GPS Fix"
pop_byte
case $byte in
  00) printf "No Lock\n" ;;
  01) printf "2D Lock\n" ;;
  02) printf "3D Lock\n" ;;
   *) printf "Unknown\n" ;;
esac

print_header "NTP Lookups"
pop_byte ; x1="$byte"
pop_byte ; x2="$byte"
pop_byte ; x3="$byte"
pop_byte ; x4="$byte"
printf "%d\n" $((0x$x1$x2$x3$x4))

print_header "GPS Time"
pop_byte ; x1="$byte"
pop_byte ; x2="$byte"
pop_byte ; x3="$byte"
printf "%02d:%02d:%02d UTC\n" $((0x$x1)) $((0x$x2)) $((0x$x3))

print_header "Location"
str=""
end=0
unset IFS
for i in $(seq 1 25); do
  pop_byte
  if [ "$byte" = "00" ]; then
    end=1
  elif [ $end -eq 0 ]; then
    str="$str$(printf "\\$(printf '%03o' $((0x$byte)))")"
  fi
done
printf "%s\n" "$str"

print_header "Unit Name"
str=""
end=0
unset IFS
for i in $(seq 1 35); do
  pop_byte
  if [ "$byte" = "00" ]; then
    end=1
  elif [ $end -eq 0 ]; then
    str="$str$(printf "\\$(printf '%03o' $((0x$byte)))")"
  fi
done
printf "%s\n" "$str"

printf "\n"

exit 0
