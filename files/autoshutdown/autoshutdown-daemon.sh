#!/bin/bash

. /autoshutdown/autoshutdown-fcns.sh

. ${SCRIPTS:-/}start-utils

# wait for java process to be started
while :
do
  if java_process_exists ; then
    break
  fi
  sleep 0.1
done

STATE=INIT

while :
do
  case X$STATE in
  XINIT)
    # Server startup
    if mc_server_listening ; then
      TIME_THRESH=$(($(current_uptime)+$AUTOSHUTDOWN_TIMEOUT_INIT))
      logAutoshutdown "MC Server listening for connections - shutting down in $AUTOSHUTDOWN_TIMEOUT_INIT seconds"
      STATE=K
    fi
    ;;
  XK)
    # Knocked
    if java_clients_connected ; then
      logAutoshutdown "Client connected - waiting for disconnect"
      STATE=E
    else
      if [[ $(current_uptime) -ge $TIME_THRESH ]] ; then
        logAutoshutdown "No client connected since startup - stopping"
        /autoshutdown/shutdown.sh
        STATE=S
      fi
    fi
    ;;
  XE)
    # Established
    if ! java_clients_connected ; then
      TIME_THRESH=$(($(current_uptime)+$AUTOSHUTDOWN_TIMEOUT_EST))
      logAutoshutdown "All clients disconnected - stopping in $AUTOSHUTDOWN_TIMEOUT_EST seconds"
      STATE=I
    fi
    ;;
  XI)
    # Idle
    if java_clients_connected ; then
      logAutoshutdown "Client reconnected - waiting for disconnect"
      STATE=E
    else
      if [[ $(current_uptime) -ge $TIME_THRESH ]] ; then
        logAutoshutdown "No client reconnected - stopping"
        STATE=S
        break
      fi
    fi
    ;;
  *)
    logAutopause "Error: invalid state: $STATE"
    ;;
  esac
  sleep $AUTOSHUTDOWN_PERIOD
done

/autoshutdown/shutdown.sh