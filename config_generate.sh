#!/bin/bash
if [ ! -f version.yml ]; then
	echo 'no version.yml found, creating one from templates/itg_local.yml'
	cp templates/version_local.yml version.yml
fi
if [ ! -f environment.yml ]; then
	echo 'no environment.yml found, creating one from templates/environment_local.yml'
	cp templates/environment_local.yml environment.yml
fi
echo 'generating compose environment'
groovy helper/generate_compose_env.groovy -p itg.properties -v version.yml -l $HOSTNAME
echo 'generating appconfig files'
rm -f hub/itsconfig/appconfig.xml ebicsui/itsconfig/appconfig.xml camunda/itsconfig/appconfig.xml spot/itsconfig/appconfig*.xml mock/itsconfig/appconfig*.xml
echo 'setting up itg.properties from  custom properties file'
read -p "Please specify the custom properties filename to update itg.properties, or press Enter to ignore " custom_properties_file
./helper/update_itg_properties.sh "$custom_properties_file"
groovy helper/generate_appconfig.groovy -p itg.properties -t templates/appconfig_hub_local.xml -o hub/itsconfig/appconfig.xml
groovy helper/generate_appconfig.groovy -p itg.properties -t templates/appconfig_ebicsui_local.xml -o ebicsui/itsconfig/appconfig.xml
groovy helper/generate_appconfig.groovy -p itg.properties -t templates/appconfig_camunda_local.xml -o camunda/itsconfig/appconfig.xml
groovy helper/generate_appconfig.groovy -p itg.properties -t templates/appconfig_spot_local.xml -e environment.yml -c spot -o spot/itsconfig/appconfig.xml
groovy helper/generate_appconfig.groovy -p itg.properties -t templates/appconfig_mock_local.xml -e environment.yml -c mock -o mock/itsconfig/appconfig.xml

groovy helper/generate_beat_config.groovy -p itg.properties -t beat/logstash/pipeline/metrics.conf -o beat/logstash/pipeline/metrics.conf -h $HOSTNAME -l true
groovy helper/generate_beat_config.groovy -p itg.properties -t beat/logstash/pipeline/troubleshooting.conf -o beat/logstash/pipeline/troubleshooting.conf -h $HOSTNAME -l true
groovy helper/generate_beat_config.groovy -p itg.properties -t beat/logstash/config/logstash.yml -o beat/logstash/config/logstash.yml -h $HOSTNAME -n local
groovy helper/generate_beat_config.groovy -p itg.properties -t beat/filebeat/beat.d/filebeat_ebics.yml -o beat/filebeat/beat.d/filebeat_ebics.yml -n $HOSTNAME -c filebeat -e environment.yml

echo 'generating application properties files'
rm -f spot/itsconfig/application.properties
groovy helper/generate_appconfig.groovy -p itg.properties -t templates/application.properties.template -e environment.yml -o spot/itsconfig/application.properties

echo 'downloading hub api jars'
rm -rf hub/hubapi/*
groovy helper/fetch_api_jars.groovy -e environment.yml -v version.yml -o hub/hubapi || { echo 'error during download' ; exit 1; }
echo 'downloading camunda api jars'
rm -rf camunda/cwplugins/*
groovy helper/fetch_api_jars.groovy -e environment.yml -v version.yml -o camunda/cwplugins -c camunda || { echo 'error during download' ; exit 1; }
echo 'downloading sqlserver driver jar'
rm -f hub/itsconfig/*.jar ebicsui/itsconfig/*.jar camunda/itsconfig/*.jar spot/itsconfig/*.jar mock/itsconfig/*.jar
curl --fail-with-body --insecure https://repograz.reval.com/artifactory/jcenter-cache/com/microsoft/sqlserver/mssql-jdbc/7.4.1.jre11/mssql-jdbc-7.4.1.jre11.jar -o mssql-jdbc-7.4.1.jre11.jar
cp mssql-jdbc-7.4.1.jre11.jar hub/itsconfig
cp mssql-jdbc-7.4.1.jre11.jar ebicsui/itsconfig
cp mssql-jdbc-7.4.1.jre11.jar camunda/itsconfig
cp mssql-jdbc-7.4.1.jre11.jar spot/itsconfig
cp mssql-jdbc-7.4.1.jre11.jar mock/itsconfig
rm mssql-jdbc-7.4.1.jre11.jar