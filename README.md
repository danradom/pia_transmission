# pia_transmission

private internet access (PIA) VPN control script / transmission kill switch

- pia.sh start  -  starts PIA VPN and transmission
- pia.sh stop  -  stops PIA VPN and transmission
- pia.sh status  -  prints PIA VPN status
- pia.sh monitor  -  run via cron every minute to kill transmission service if PIA VPN goes down and send email notifications on VPN status change

sends a single email when VPN goes down and another when it comes back up
