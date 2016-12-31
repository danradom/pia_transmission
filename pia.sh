#!/bin/bash
#
# private internet access (PIA) VPN control script / transmission kill switch
#

down="/usr/local/admin/.pia.down"


if [ $1 != "status" ]; then
        if [ $EUID != "0" ]; then
                echo ""
                echo "you must be root to run this script.  try sudo !!"
                echo ""
                exit 1
        fi
fi


pia_start () {
        openvpn --config /etc/openvpn/pia/US\ California.ovpn --auth-user-pass /etc/openvpn/pia/.pass.txt --crl-verify /etc/openvpn/pia/crl.rsa.2048.pem --ca /etc/openvpn/pia/ca.rsa.2048.crt > /dev/null 2>&1 &
        sleep 10
        route delete default gw 192.168.0.254
        service transmission-daemon start
        sleep 5
        $0 status
}


pia_stop () {
        service transmission-daemon stop
        pid=`ps -ef |grep /etc/openvpn/pia/ca.rsa.2048.crt |grep -v grep |awk '{print $2}'`
        kill $pid
        route add default gw 192.168.0.254
        sleep 5
        $0 status
}


pia_status () {
        echo ""
        ifconfig tun0 > /dev/null 2>&1
        if [ $? = 0 ]; then
                ifconfig tun0
        else
                echo "tun0 interface not found"
        fi
        echo ""
        echo ""
        pidt=`pidof transmission-daemon`
                if [ -z $pidt ]; then
                        echo "transmission not running"
                elif [ -n $pidt ]; then
                        echo "transmission running with PID $pidt"
                fi
        echo ""
        echo ""
        pido=`pidof openvpn`
        if [ -z $pido ]; then
                        echo "openvpn not running"
                elif [ -n $pido ]; then
                        echo "openvpn running with PID $pido"
                fi
        echo ""
        echo ""
        ip route show
        echo ""
}


pia_monitor () {
        gwif=`/sbin/ip route |awk '/0.0.0.0/||/default/ { print $5 }'`
        status="/usr/local/admin/.pia.status"
        if [[ -f $down ]] && [[ "$gwif" = "eth0" ]]; then
                echo ""
                echo "$down file exists.  PIA VPN is down or file is stale"
                echo ""
                exit 1
        fi

        if [ "$gwif" = "eth0" ] ; then
                pia_status > $status
                mail -s "PIA VPN down" email@email.net < $status
#               rm $status
                service transmission-daemon stop
                touch $down
        elif [ "$gwif" = "tun0" ]; then
                echo ""
                echo "PIA VPN is up"
                /sbin/ip route |grep default
                echo ""
                if [ -f $down ]; then
                        rm $down
                        pia_status > $status
                        mail -s "PIA VPN up" email@email.net < $status
#                       rm $status
                        service transmission-daemon start
                fi
        fi
}


case "$1" in
        start)
                pia_start;;
        stop)
                pia_stop;;
        status)
                pia_status;;
        monitor)
                pia_monitor;;
        *)
                echo ""
                echo "$0 start|stop|status|monitor"
                echo ""
esac
