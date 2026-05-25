    ## Show free space
    df -Th | grep -v fs
    # Will need English output for processing
    LANG=en_GB.UTF-8

    ## Clean apt cache
    apt-get update
    apt-get -f install
    apt-get -y autoremove
    apt-get clean

    ## Remove old versions of snap packages
    snap list --all | while read snapname ver rev trk pub notes; do
        if [[ $notes = *disabled* ]]; then
            snap remove "$snapname" --revision="$rev"
        fi
    done

    ## Set snap versions retain settings
    if [[ $(snap get system refresh.retain) -ne 2 ]]; then snap set system refresh.retain=2; fi
    rm -f /var/lib/snapd/cache/*

    ## Remove old versions of Linux Kernel
    # New 2 lines to remove old kernels
    dpkg --list | grep 'linux-image' | awk '{ print $2 }' | sort -V | sed -n '/'"$(uname -r | sed "s/\([0-9.-]*\)-\([^0-9]\+\)/\1/")"'/q;p' | xargs apt-get -y purge
    dpkg --list | grep 'linux-headers' | awk '{ print $2 }' | sort -V | sed -n '/'"$(uname -r | sed "s/\([0-9.-]*\)-\([^0-9]\+\)/\1/")"'/q;p' | xargs apt-get -y purge

    ## Rotate and delete old logs
    /etc/cron.daily/logrotate
    find /var/log -type f -iname *.gz -delete
    journalctl --rotate
    journalctl --vacuum-time=1s

    ## Show free space
    df -Th | grep -v fs
