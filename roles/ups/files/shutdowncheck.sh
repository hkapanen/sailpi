#!/bin/bash
# This script checks if MightyBoost signals shutdown to raspi and acts accordingly

# This is an input (active high) from MightyBoost to the Pi.
SHUTDOWN=18
SHUTDOWNPULSEMINIMUM=600      # Shutdown needs to be high at least this long (ms)
echo "$SHUTDOWN" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio$SHUTDOWN/direction

# This is an output from Pi to MightyBoost and signals that the Pi is up and running
# This pin is asserted HIGH as soon as this script runs (by writing "1" to /sys/class/gpio/gpio#/value)
RUNNING=23
echo "$RUNNING" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio$RUNNING/direction
echo "1" > /sys/class/gpio/gpio$RUNNING/value
echo "MightyBoost shutdown script started: asserted pins ($SHUTDOWN=input,LOW; $RUNNING=output,HIGH). Waiting for GPIO$SHUTDOWN to become HIGH..."

# This loop keeps checking if shutdown was signalled on MightyBoost (GPIO to become HIGH), and issues a shutdown when that happens.
# It sleeps as long as that has not happened.
while [ 1 ]; do
  shutdownSignal=$(cat /sys/class/gpio/gpio$SHUTDOWN/value)
  if [ $shutdownSignal = 0 ]; then
    /bin/sleep 1
  else  
    pulseStart=$(date +%s%N | cut -b1-13) # mark the time when Shutoff signal went HIGH (milliseconds since epoch)
    while [ $shutdownSignal = 1 ]; do
      /bin/sleep 0.02
      if [ $(($(date +%s%N | cut -b1-13)-$pulseStart)) -gt $SHUTDOWNPULSEMINIMUM ]; then
        echo "MightyBoost triggered a shutdown signal, halting Rpi ... "
        sudo poweroff
        exit
      fi
      shutdownSignal=$(cat /sys/class/gpio/gpio$SHUTDOWN/value)
    done
  fi
done