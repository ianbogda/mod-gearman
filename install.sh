#!/bin/bah

#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
else
    clear
    # Update and upgrade
    echo "Updating ans Upgrading"
    sudo apt-get update && sudo apt-get -qq upgrade -y

    sudo apt-get -qq install -y dialog build-essential libgd2-xpm-dev openssl libssl-dev xinetd

    DIALOG=${DIALOG=dialog}
    fichtemp=`./tempfile 2>/dev/null` || fichtemp=/tmp/test$$
    trap "rm -f $fichtemp" 0 1 2 5 15

    $DIALOG --title "Configuration ModGearmanWorker" --clear \
        --yesno "Vous êtes sur le point d'installer mod-gearman-worker.\n
voulezvous continuer ?" 20 60

    case $? in
        0)
            $DIALOG --clear \
                    --inputbox "Indiquez le serveur et le port du serveur Nagios (127.0.0.1:4730) :" 16 51 2>$fichtemp
            case $? in
                0)
                    GEARMANSERVER=`cat $fichtemp`
                    $DIALOG --clear \
                            --inputbox "Indiquez le Nom du groupe de serveur :" 16 51 2>$fichtemp
                    case $? in
                        0)
                            HOSTGROUP=`cat $fichtemp`
                            $DIALOG --clear \
                                    --inputbox "Indiquez le mot de passe :" 16 51 2>$fichtemp
                            case $? in
                                0)
                                    PASSWORD=`cat $fichtemp`
                                    sudo apt-get -qq install mod-gearman-worker -y

                                    if [ -f "/etc/mod-gearman/worker.conf" ]
                                    then
                                        WorkerConf=/etc/mod-gearman/worker.conf
                                    elif [ -f "/etc/mod-gearman-worker/worker.conf" ]
                                    then
                                        WorkerConf=/etc/mod-gearman-worker/worker.conf
                                    fi
                                    sudo sed -i -e "s/\(^identifier=\).*/\1PBX/"        $WorkerConf
                                    sudo sed -i -e "s/\(^server=\).*/\1$GEARMANSERVER/" $WorkerConf
                                    sudo sed -i -e "s/\(^hostgroups=\).*/\1PBX/"        $WorkerConf
                                    sudo sed -i -e "s/\(^encryption=\).*/\1yes/"        $WorkerConf
                                    sudo sed -i -e "s/\(^key=\).*/\1yes/"               $WorkerConf
                                    sudo sed -i -e "s/\(^job_timeout=\).*/\160/"        $WorkerConf

                                    # installation Nagios plugins
                                    useradd nagios
                                    mkdir /home/nagios
                                    chown nagios:nagios /home/nagios
                                    groupadd nagcmd
                                    usermod -a -G nagcmd nagios

                                    wget http://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz
                                    tar xvf nagios-plugins-2.2.1.tar.gz
                                    cd nagios-plugins-2.2.1
                                    ./configure --with-nagios-user=nagios --with-nagios-group=nagios
                                    make
                                    make install
                                    ;;
                                1) cancel ;;
                                255) escape ;;
                            esac
                            ;;

                        1) cancel ;;
                        255) escape ;;
                    esac
                    ;;
                1) cancel ;;
                255) escape ;;
            esac
            ;;
        1) cancel ;;
        255) escape ;;
    esac
fi
function cancel ()
{
    echo "Installation Annulée. Merci et au revoir."
}

function escape ()
{
    echo "Merci et au revoir."

}
