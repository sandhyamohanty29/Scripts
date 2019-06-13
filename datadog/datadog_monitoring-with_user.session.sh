#!/bin/bash
############################################################
### This is a script to take user's login session output ###
### and configure with datdog   as required              ###
###                                                      ###
###                                                      ###
############################################################
#instead of editing existsing /etc/profile; lets create a script and place in /etc/profile.d
echo " make sure you run this script as root"
FILE=/etc/profile.d/users_session.sh
timestamp=`date "+%m%d%Y%H%M"`
SERVICE=`ps aux | grep datadog-agent | grep -v grep | wc -l`
DATADOG_RPM=`rpm -qa | grep -i datadog| wc -l`
if [ -f "$FILE" ]; then
   echo "user's login script is already present.... ";
else
echo "Let's create user's login session creation script...";
sleep 2; mkdir -p /var/log/session; chmod 777 /var/log/session/
touch /etc/profile.d/users_session.sh; chmod 755 /etc/profile.d/users_session.sh
echo -e '#[Record terminal sessions]
if [ "x$SESSION_RECORD" = "x" ]
then
        timestamp=`date "+%m%d%Y%H%M"`
        output=/var/log/session/session.$USER.$$.$timestamp.log
        SESSION_RECORD=started
        export SESSION_RECORD
        script -t -f -q 2>${output}.timing $output
fi' > /etc/profile.d/users_session.sh
echo "***************user session added sucessfully*************"
fi
##############This portion is responsible for datadog configuration#########
###																		 ###
###																		 ###
###																		 ###
############################################################################

echo "lets check if Data Dog agent is installed and datadog agent is running"
if [[ $SERVICE -gt 0 &&  $DATADOG_RPM -gt 0 ]] ; then
  echo " datadog agent has been installed already";
exit
else
echo "Now let's configure datadog montoring agent..."
echo "data dog agent is installing ...it will complete in a minute or two..."
DD_API_KEY=9d110a6596cd9676a691f0063a443ca2 bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"
echo "Datadog agent installed sucesfully...."
echo "Datadog agent has been installed , its time to customize our session log...It will complete in a minute..."
sleep 2;
cp -p /etc/datadog-agent/datadog.yaml /etc/datadog-agent/datadog.yaml_$timestamp
echo -e 'logs_enabled: true' >> /etc/datadog-agent/datadog.yaml;
systemctl restart datadog-agent; 
mkdir -p /etc/datadog-agent/conf.d/session.d; cd /etc/datadog-agent/conf.d/session.d
touch conf.yaml
echo -e '#Log section
logs:

    # - type : (mandatory) type of log input source (tcp / udp / file)
    #   port / path : (mandatory) Set port if type is tcp or udp. Set path if type is file
    #   service : (mandatory) name of the service owning the log
    #   source : (mandatory) attribute that defines which integration is sending the logs
    #   sourcecategory : (optional) Multiple value attribute. Can be used to refine the source attribtue
    #   tags: (optional) add tags to each logs collected

  - type: file
    path: /var/log/session/*.log
    service: myapp1
    source: session' > /etc/datadog-agent/conf.d/session.d/conf.yaml
echo "************************************************************************"
echo "lets check if our agent is back after restart..."
systemctl restart datadog-agent;ps aux | grep datadog-agent | grep -v grep
echo "##########################################################################"
echo "WoW!!!!!.....Now we have configured user session log script, installed datadog agent and customized our datadog log monitoring..."
echo "***************************************************************************************************"
fi










