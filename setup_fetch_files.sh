#!/bin/sh
echo "setting up DevBox folder structure"
rm -rf *.sh *.ps1
git ls-remote git@gitgraz.reval.com:reval-devops/itg-deployment master | cut -f1 > version.txt
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:shared/compose |tar xf -
mkdir -p templates
rm -f templates/*.yml templates/*.xml
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/config/hub appconfig_local.xml |tar xf -
mv appconfig_local.xml templates/appconfig_hub_local.xml
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/config/ebicsui appconfig_local.xml |tar xf -
mv appconfig_local.xml templates/appconfig_ebicsui_local.xml
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/config/camunda appconfig_local.xml |tar xf -
mv appconfig_local.xml templates/appconfig_camunda_local.xml
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/config/spot appconfig_local.xml |tar xf -
mv appconfig_local.xml templates/appconfig_spot_local.xml
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/config/spot application.properties.template |tar xf -
mv application.properties.template templates/application.properties.template
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/config/mock appconfig_local.xml |tar xf -
mv appconfig_local.xml templates/appconfig_mock_local.xml
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/config local_environment_config |tar xf -
mv local_environment_config itg.properties
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:shared/version environment_local.yml |tar xf -
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:shared/version itg_local.yml |tar xf -
mv environment_local.yml templates/environment_local.yml
mv itg_local.yml templates/version_local.yml
mkdir -p beat
mkdir -p hub/hubapi
mkdir -p hub/itsconfig
mkdir -p ebicsui/itsconfig
mkdir -p camunda/cwplugins
mkdir -p camunda/itsconfig
mkdir -p spot/itsconfig/keys
mkdir -p mock/itsconfig
mkdir -p sqlserverdata
rm -rf beat/*
git archive --format=tar --remote=git@graugitlab01.reval.com:reval/itgtest.git master:staticdata/data/shared/shiftleft tenants.json userTenantMapping.csv | tar xf -
mv tenants.json mock/itsconfig/tenants.json
mv userTenantMapping.csv mock/itsconfig/userTenantMapping.csv
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/config/beat |tar xf - -C beat
mv beat/filebeat/beat.d/filebeat_template.yml beat/filebeat/beat.d/filebeat_ebics.yml
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:dnc/config/beat/filebeat/beat.d filebeat_template.yml |tar xf - -C beat/filebeat/beat.d
mv beat/filebeat/beat.d/filebeat_template.yml beat/filebeat/beat.d/filebeat_dnc.yml
mv beat/metricbeat/metricbeat_template.yml beat/metricbeat/metricbeat.yml
mv beat/logstash/pipeline/metrics_template.conf beat/logstash/pipeline/metrics.conf
mv beat/logstash/pipeline/troubleshooting_template.conf beat/logstash/pipeline/troubleshooting.conf
mv beat/logstash/config/logstash_template.yml beat/logstash/config/logstash.yml
mkdir -p beat/logstash/security
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/keys logstash.keystore truststore-opensearch.p12 | tar xf - -C beat/logstash/config
mv beat/logstash/config/truststore-opensearch.p12 beat/logstash/security
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/keys/mock | (cd mock && tar xf -)
git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/keys uddr_server.cer keystore_local.p12 truststore_local.p12 keystore_icashub_local.jks |  tar xf - -C spot/itsconfig/keys
git archive --format=tar --remote=git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/keys keystore_icashub_mock_local.jks | tar xf - --transform='s/keystore_icashub_mock_local.jks/icashub.jks/' -C hub/itsconfig/
git archive --format=tar --remote=git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/keys keystore_icashub.jks | tar xf - --transform='s/keystore_icashub.jks/icashub.jks/' -C spot/itsconfig/keys
git archive --format=tar --remote=git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/keys keystore_local.p12 | tar xf - --transform='s/keystore_local.p12/hub-keystore.p12/' -C spot/itsconfig/keys
git archive --format=tar --remote=git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/keys truststore_local.p12 | tar xf - --transform='s/truststore_local.p12/hub-truststore.p12/' -C spot/itsconfig/keys
git archive --format=tar --remote=git@gitgraz.reval.com:reval-devops/itg-deployment.git master:core/keys traceRuntime.lic | tar xf -  -C spot/itsconfig/keys
mkdir -p dnc-saas
mkdir -p sqlserverbackup
echo "done"