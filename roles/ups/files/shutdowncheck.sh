#!/bin/bash

# This script checks if MightyBoost signals reset or shutdown to raspi via gpio and acts accordingly

# This is an input from MightyBoost to the Pi.
# When button is held for ~3 seconds, this pin will become HIGH signalling to this script to poweroff the Pi.
SHUTDOWN=18
REBOOTPULSEMINIMUM=200      #reboot pulse signal should be at least this long
REBOOTPULSEMAXIMUM=600      #reboot pulse signal should be at most this long
echo "$SHUTDOWN" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio$SHUTDOWN/direction

# Hold the button for at least 500ms but no more than 2000ms and a reboot HIGH pulse of 500ms length will be issued
# This is an output from Pi to MightyBoost and signals that the Pi has booted.
# This pin is asserted HIGH as soon as this script runs (by writing "1" to /sys/class/gpio/gpio#/value)
BOOT=23
echo "$BOOT" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio$BOOT/direction
echo "1" > /sys/class/gpio/gpio$BOOT/value
echo "MightyBoost shutdown script started: asserted pins ($SHUTDOWN=input,LOW; $BOOT=output,HIGH). Waiting for GPIO$SHUTDOWN to become HIGH..."

# This loop continuously checks if shutdown was signalled on MightyBoost (GPIO7 to become HIGH), and issues a shutdown when that happens.
# It sleeps as long as that has not happened.
while [ 1 ]; do
  shutdownSignal=$(cat /sys/class/gpio/gpio$SHUTDOWN/value)
  if [ $shutdownSignal = 0 ]; then
    /bin/sleep 0.2
  else  
    pulseStart=$(date +%s%N | cut -b1-13) # mark the time when Shutoff signal went HIGH (milliseconds since epoch)
    while [ $shutdownSignal = 1 ]; do
      /bin/sleep 0.02
      if [ $(($(date +%s%N | cut -b1-13)-$pulseStart)) -gt $REBOOTPULSEMAXIMUM ]; then
        echo "MightyBoost triggered a shutdown signal, halting Rpi ... "
        sudo poweroff
        exit
      fi
      shutdownSignal=$(cat /sys/class/gpio/gpio$SHUTDOWN/value)
    done
    # pulse went LOW, check if it was long enough, and trigger reboot
    if [ $(($(date +%s%N | cut -b1-13)-$pulseStart)) -gt $REBOOTPULSEMINIMUM ]; then 
      echo "MightyBoost triggered a reboot signal, recycling Rpi ... "
      sudo reboot
      exit
    fi
  fi
done