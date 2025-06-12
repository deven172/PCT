# ITG DevBox scripts

[[_TOC_]]

## Description

This folder contains scripts to run ITG services locally on a development box.

Currently, the following services are supported:

- Hub, Mq, Scheduler
- Keycloak
- AdminUI
- Spots
- Mocks
- Camunda-Engine-Server, Camunda-Worker-Server, Camunda-App-Server, Camunda-Deploy-Server
- Auth, CDS, Journal-Api, Cancellation Api Libraries
- Msg-Transformation, Scs-Screening and Scs-Exceptions
- Beats
- A local SQLServer holding all the required databases

## System requirements

### Prerequisite Overview

A Windows Box with the following installed (requires admin permissions for setup):
- Windows Subsystem for Linux (WSL2)
	- Ubuntu Linux
	- Java (OpenJDK 17 recommended) within Ubuntu
	- Gitlab Graz access configured via SSH
- Docker Desktop (or Docker within WSL, also requires Docker Compose)
	- Enable pulling from Graz Nexus

### Prerequisite installation steps

1) Install WSL2

Please refer to the official Microsoft Documentation: https://learn.microsoft.com/en-us/windows/wsl/install.
Advanced WSL settings, like limiting memory and similar can be found here: https://learn.microsoft.com/en-us/windows/wsl/wsl-config.

2) Install Docker Desktop

Can be installed from the Software Center.
Make sure that after installation the WSL integration is enabled (Settings -> Resources -> WSL Integration).
Once installed calls to the docker demon should be possible from within wsl/install.
Run e.g. the following to validate:
`docker version`

:zap: to be able to pull from Graz Nexus, the matching Certificate needs to be imported to Windows Trusted Root Certification Authorities. The certificate can be obtained from https://graudocreg01.reval.com:8082/. Once done restart the docker desktop. If the regular docker engine is used within WSL instead of Docker Desktop the certificate needs to either be supplied via /etc/docker/certs.d or nexus needs to be allowed as an insecure registry via demon.json. More information on insecure registries can be found here: https://docs.docker.com/reference/cli/dockerd/#insecure-registries

:zap: to be able to pull from DNC CI which is only needed when using the msg-transformation and/or the sanction-service, the matching Certificate needs to be imported to Windows Trusted Root Certification Authorities. The certificate can be obtained from https://suite-ci.iongroup.com:5005. In this case above description about docker and self-signed certificates applies here as well.

:zap: add the following entry in C:\Windows\System32\drivers\etc\hosts
```
127.0.0.1 keycloak
```


3) Install OpenJDK in Ubuntu

Can be installed via 
```
sudo apt update
sudo apt install openjdk-17-jdk 
```

`java --version` should then return a correct response.

4) Configure GitLab Graz SSH access

Simply place your GitLab SSH key into the WSL user home directories .ssh folder.

In case you need more instructions on how to create and setup SSH keys for your GitLab account, please follow: https://docs.gitlab.com/ee/user/ssh.html.

5) Install unzip in Ubuntu

Can be installed via
```
sudo apt update
sudo apt install unzip 
```

This is required for extracting the itg-data-package.zip to mount its contents to the dnc-update container.

6) Mount network share drives to WSL for database backups

To support restore of databases, database back up files can be added to a folder on centralized share - \\\\itgauto1.eng.wallstreetsystems.com\\dbbackup. The share also needs to be mounted to WSL using the following commands:
```
sudo mkdir -p /mnt/dbbackup
#Update /etc/fstab file with below entry
\\\\itgauto1.eng.wallstreetsystems.com\\dbbackup        /mnt/dbbackup      drvfs defaults,rw,uid=1000,gid=1000,umask=22,fmask=11 0 0
```

7) Mount docker-desktop-data to WSL. This step is required to allow filebeat to read logs of other container services and push to Open-search domain.
```
sudo mkdir /mnt/docker-data
#Update /etc/fstab file and add below entry:
\\\\wsl.localhost\\docker-desktop-data\\data\\docker    /mnt/docker-data   drvfs defaults,uid=1000,gid=1000    0    0
```

## ITG DevBox script usage

### Initial Setup

To start using the DevBox scripts the following needs to be done:

1. Set up a local directory for the itg scripts. A recommendation is to create a folder named itg in the /home directory of the used WSL user (e.g. /home/user/itg).

Either:

2. Retrieve setup_fetch_files.sh from https://gitgraz.reval.com/reval-devops/itg-deployment/-/raw/master/shared/compose/setup_fetch_files.sh.?ref_type=heads&inline=false to the local directory.
3. Run `./setup_fetch_files.sh` to fetch all the required scripts to the local box as well as to setup the required folder structure.

Or in case a guided wizard is preferred for first time setup:

2. Retrieve setup_wizard.sh from https://gitgraz.reval.com/reval-devops/itg-deployment/-/raw/master/shared/compose/setup_wizard.sh.?ref_type=heads&inline=false to the local directory and follow the steps.
3. Run `./setup_wizard.sh` and follow the instructions displayed in wizard.

Make sure to have execution rights set on the sh file. If the script throws an SSH error, follow the instructions provided in the error message.

#### DevBox directory structure

Once setup_fetch_files.sh has been run the following directory structure is in place

- :file_folder: camunda (holds configuration and plugins of camunda engine)
- :file_folder: dnc-saas (holds configuration of dnc-saas)
- :file_folder: ebicsui (holds configuration of ebicsui)
- :file_folder: helper (holds helper scripts to e.g. generate config, download files...)
- :file_folder: hub (holds configuration and plugins for hub, mq, scheduler)
- :file_folder: init (holds database initialization scripts to populate schemas and users for the local sqlserver container)
- :file_folder: mock (holds configuration for mocks)
- :file_folder: spot (holds configuration for spots)
- :file_folder: sqlserverdata (holds sqlserver data files and transaction logs)
- :file_folder: stacks (holds compose stacks for the various services)
- :file_folder: templates (holds configuration templates used to generate the required configuration files for all services)
- :file_folder: beat (holds configuration templates used to generate the required configuration files for filebeat, metricbeat and logstash)
- itg.properties (holds usernames and passwords used throughout the application services)
- various sh / ps1 scripts (used to operate the tasks described in the further sections of this readme)

#### Install additional library requirements

The ITG DevBox Scripts need the following additional libraries to be installed:

1) Groovy

To install the groovy runtime execute `./setup_groovy.sh` as sudo and then refresh the console.
It installs Groovy to the /opt directory in WSL and sets the required PATH/JAVA_HOME variables within a script named groovy.sh in /etc/init.d


### Create config

By running `./config_generate.sh` all required configuration files are generated.

This includes:

- docker compose environment files app.env and db.env used for the compose application stacks as well as liquibase update stacks (in the root folder of the DevBox directory structure).
- appconfig.xml file for hub, mq, scheduler (in hub/itsconfig folder).
- appconfig.xml file for ebicsui (in ebicsui/itsconfig folder).
- appconfig.xml file for camunda (in camunda/itsconfig folder).
- appconfig.xml file for spots (for each spot mentioned in spot/itsconfig folder).
- download of api jars for hub, spot and camunda based on the environment file to hub/hubapi and camunda/cwplugins folders.
- download of mssql server driver jars to hub/itsconfig, ebicsui/itsconfig, camunda/itsconfig and spot/itsconfig folders.
- in case no version.yml and environment.yml are provided in the root directory the two files are automatically created utilizing the templates in the templates folder.
- logstash.yml, metrics.conf and troubleshooting.conf for logstash (in beat/logstash folder).
- filebeat_ebics.yml and filebeat_dnc for filebeat (in beat/filebeat/beat.d folder).

:zap: Whenever the manifest files change this script can be rerun to generate an updated configuration.

### Database handling

#### Initialize local SQLServer with all users/schemas

ITG requires a SqlServer to host all required databases
`./database_init.sh` can be used to create a local SqlServer container and setup the following schemas (matching user/password in brackets):

1. banking (banking/banking)
2. banking_ks (hub/hub)
3. camunda (camunda/camunda)
4. cds (cds/cds)
5. dnc_adapter (dnc_adapter/dnc_adapter)
6. ebics (ebics/ebics)
7. hub (hub/hub)
8. itgapi (itgapi/itgapi)
9. its (its/its)
10. keycloak (keycloak/keycloak)
11. mds (mds/mds)
12. scheduler (hub/hub)

:zap: sa user password is SqlServer2022 and can be used to e.g. access the sqlserver instance via management studio (Server Name = localhost).

#### Restore databases from itg-dev database dump

To restore databases on the developer box, database backups available in different folders on share path \\\\itgauto1.eng.wallstreetsystems.com\\dbbackup can be used.
To support the restore process, script database_restore.sh is used:

This script executes the restore process in 3 steps:

 - Fetch db dump files from share \\\\itgauto1.eng.wallstreetsystems.com\\dbbackup (mounted at path /mnt/dbbackup) to a local folder in WSL filesystem /home/user/itg/sqlserverbackup 
 - Stop all running containers
 - Run the restore process: 
   - To check the logs of restore process, please run command "docker logs -f sqlserver.dbrestore"


#### Update the ITG databases

Databases for all services that support liquibase (hub, lib, spot etc.) can be updated using `./database_update.sh stack` e.g. `./database_update.sh hub`.
This script executes the matching compose db update stack (for hub e.g. db-update-hub-compose.yml which includes hub, mq and scheduler liquibase update containers) and after completion validates the exit codes.

The following stacks are supported for database_update.sh:

- hub (includes hub, scheduler, mq as well as auth lib)
- spot (all spots)
- camunda
- lib (all libraries)
- dnc (message transformation)
- scs (sanction screening)
- admin_ui



Keycloak does not require a separate db update call as it updates the database on startup.


#### External DB Connection

- As part of default configuration, a local sqlserver container will be set up and configured. To connect to an external database, please set the db-server in properties file to the target DB server name and run .\config_generate.sh. This will ensure all application configs are generated correctly for the external DB server.

- To connect only a single service or a sub-set of services to an external DB server, please modify the data connection properties of that service directly in appconfig file.

### Start application

Startup of application services is done via `./service_start.sh stack1 stack2 ...` 
e.g. `./service_start.sh hub keycloak adminui camunda` would start the hub, mq, scheduler, keycloak, adminui and all the camunda services plus ensure that sqlserver is running.

Startup of the msg-transformation service is done via `./service_start.sh dnc` and startup of scs-screening and scs-execptions services is done via `./service_start.sh scs`.


:zap: Two additional users have been configured to access these services: itgops/itgops; iontms/iontms. 

:speech_balloon: Startup of the ION platform on any of these 3 services takes about 5 mins.

The following stacks are supported for service_start.sh

- hub (includes hub, scheduler, mq)
- spot (all spots)
- mock (all mocks)
- keycloak
- camunda
- adminui
- dnc (message transformation)
- scs (sanction screening)
- sqlserver
- beat (filebeat, metricbeat and logstash)

#### Usage considerations

Running all supported stacks can quickly cause high resource usage in terms of Memory/CPU, especially on 16GB systems.
As usually not all services are required, only running the required ones is the recommended approach. The start/stop scripts support running individual stacks as described in the above section. However, for mocks/spots, it can be useful to disable unused services in the respective compose stacks (stacks/spot-compose.yml, stacks/mock-compose.yml) to configure which exact spots/mocks should be run.

The following section highlights two options to configure which exact services should run.

For dnc-saas database update (scs-update and dnc-update), it is recommended to run them one after another.
For dnc-saas application components (msg-transformation, scs-exceptions and scs-screening), it is recommended to run only one of these three services at any given time.

Filebeat, Metricbeat and Logstash containers captures logs from local application containers. Filebeat container fetches the logs for both ebics container and dnc container.

#### Run select application services

In general the versions of all itg services are specified in version.yml wich resides in the root folder of the DevBox scripts.
The file can be adapted to change versions of specific services.

Option 1: Services can be permanently enabled/disabled using `./service_enable_disable.sh`. If run without parameters the script gives an overview of all services over all stacks, their enabled/disabled state and service status/health. 
To disable services run `./service_enable_disable.sh disable commaSeparatedListOfServices` e.g. `./service_enable_disable.sh disable ebics-server,banking-api-core-server` (service names also support regex like banking-api-.*).
Similar services can be reenabled using `./service_enable_disable.sh enable commaSeparatedListOfServices`.
Above calls enable/disable services within the compose stacks. If any service is enable/disabled where the matching stack is already running, it will be restarted to reflect the changes. 
Please note stacks that are not running wont be automatically started by the script (even when previously disabled services are enabled again).
To start and stop services the start/stop scripts mentioned in previous sections can be used.

Option 2: As an extension to option 1 there is a capability to apply scenarios. Scenarios are basically files that list the application services that should run. The format of a scenario file is to list each service that should run per line in the file. 

e.g. my.scenario
```
hub
mq
scheduler
ebics-server 
```
After creation of such a file it can be applied by running `./service_scenario_apply my.scenario`. Please note that a call to this script stops all running services and starts exactly the ones defined in the passed scenario file.
This functionality makes it possible to create multiple scenarios of application services and quickly change between them.

Please note that this process also supports db update and library update procedures. DB/Library update service can be included in the scenario file in the same way as other services, one service per line.
e.g. my.db.update.scenario
```
auth-db-update
hub-db-update
hub
mq
```
In this case, library update will be run first (auth-db-update), followed by hub-db-update, and lastly, the remaining serives - hub and mq will start. Please note the order of the services specified in the scenario file is not significant.

#### Run multiple instances of a specific service

For some services (e.g. camunda worker) it might make sense to run multiple instances at the same time.
Unfortunatley docker compose currently has a bug that prevents the usage of the replication feature (https://github.com/docker/compose/issues/7188). A workaround for now is to manually duplicate the required service in the particular compose stack yml file and reallocate the mapped ports accordingly.

#### Local Urls

The following list provides the local URLs of various ITG services after they have been started:

- Hub: http://localhost:8282/hub/docu/swagger-ui/index.html
- Keycloak: http://localhost:8080/auth
- AdminUi: http://localhost:8076/adminui/web2/keycloaksso
- Camunda: http://localhost:8094/camunda/
- Message Transformation: http://localhost:8081/ionweb/r/restapi/messagetransformation/openapi.json
- Sanctions Screening: http://localhost:8083/ionweb/r/restapi/sanctionsscreening/openapi.json
- Exceptions: http://localhost:8082/ionweb/r/restapi/sanctionsscreening/openapi.json
- Logstash: http://localhost:9600

#### Curl commands to operate on dnc-saas services

- Get a list of all the mappings: `curl -k -u '<user>:<pwd>' http://localhost:8081/ionweb/r/restapi/messagetransformation/1.0/mappings/ `
- Check screening request against a counterparty: `curl  -k -u '<user>:<pwd>' http://localhost:8083/ionweb/r/restapi/sanctionsscreening/1.0/screen -H 'X-ION-TENANT-ID: AAA' -H 'Content-Type: application/json' -d '{ "counterparty": { "name": "Syriamar"  } }'`
- Add a counterparty to the blacklist: `curl -k -u '<user>:<pwd>' -X POST http://localhost:8082/ionweb/r/restapi/sanctionsscreening/1.0/exceptions -H 'Content-type: application/json' -H 'X-ION-TENANT-ID: XXX' -d '{"profileId":"HMT0000000006965","name":"Al Qaida"}'`
- List all the blacklisted counterparties: `curl -k -u '<user>:<pwd>' http://localhost:8082/ionweb/r/restapi/sanctionsscreening/1.0/exceptions -H "X-ION-TENANT-ID: XXX"`

### Stop application

Similar to start `./service_stop.sh stack1 stack2 ...` can be used to stop previously started stacks. 
The list of supported stacks is the same as for service_start.sh listed above.

### Opensearch
Logs from Logstash container will be shipped to the DEV OpenSearch domain: https://itgdev-opensearch.eng.wallstreetsystems.com/_dashboards/app/home
These logs have their own indexes. We also have a cleanup policy in place which will delete all the local-* indexes that are older than three days.
Application logs will flow to local-ts-live-treasury named indexes can be viewed under local-ts-live-treasury-* index pattern.
Metrics logs will flow to local-metric named indexes can be viewed under local-metricbeat-* index pattern.

## Developer Configuration for Shift-Left

Shift-Left containers have multiple configurations that can be managed through property files. Configurations such as database connection pools and Java memory settings can be adjusted using `ebics/config/local_environment_config`.

For database connections, parameters like `maxIdle`, `maxActive`, `maxWait`, and others can be modified by simply adding or updating them in the properties file. 

Refer to the example below for `hub-db-maxIdle`:

```xml
<Param
    schemaname="%hub-db-schema%"
    maxIdle="20"
    maxWait="5000"
    maxActive="10"
    maxIdle="%hub-db-maxIdle%"
    maxWait="%hub-db-maxWait%"
    maxActive="%hub-db-maxActive%"
    encrypted="false"
/>
```

### Naming Conventions for Properties in `local_environment_config`

1. For components other than Spot: `<component name>-<db if database property>-<parameter name>` (e.g., `hub-db-maxIdle`).
2. For Spot components: `spot-<spot name>--<db if database property>-<parameter name>` (e.g., `spot-ebics-db-maxIdle`).
3. For non-database properties: `spot-<spot name>-<parameter name>` (e.g., `spot-bofaapi-maxMemory=128m`).

Component parameters can only be modified using properties in the secrets file. Below is a sample component parameter, where the value can be replaced/appended with the property name:

```xml
<Param name="JVM_PARAMETER" value="-Djsch.server_host_key=ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,ssh-rsa,rsa-sha2-512,rsa-sha2-256 -Dlogging.level.com.jcraft.jsch=WARN -Djsch.client_pubkey=ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,ssh-rsa,rsa-sha2-512,rsa-sha2-256" />
```
---

### Managing Custom Properties through custom file 

When copying `local_environment_config` properties to `itg.properties`, there is a possibility of losing custom Configurations that was mentioned in itg.properties.
To prevent this, custom configurations can be placed in some custom properties file like `itg-custom.properties` within ShiftLeft linux box.
Here, we are assuming custom file as `itg-custom.properties`
W
### Key Features of custom properties file

1. **Default Property Replacement**:
	- **Default Prefix**: Properties starting with `default-` (e.g., `default-maxMemory=512m`) will replace all component properties with the same suffix (e.g., `maxMemory`) with the specified value.
	- **Default Append Prefix**: Properties starting with `default-` (e.g., `default-append-jvm-parameter=-Xdebug`) will append all component properties with the same suffix (e.g., `jvm-parameter`)

2. **Property Override and Append Behavior**:
	- **Exact Match Override**: If a property in `itg-custom.properties` matches a property in `itg.properties`, it will override the value in `itg.properties`.
	- **JVM Parameters Append**: For JVM parameters, values will be appended to those in `itg.properties`.

3. **Priority Order**:
   - **First**: Default properties will replace or append values in `itg.properties`.
   - **Second**: Properties with an exact match will replace values in `itg.properties`.
   - **JVM Parameters**: Always appended.

4. **Execution of Property Replacement**:
    - **Script Execution**: Properties replacement will be done when `config_generate.sh` is executed.Or we can execute directly via executing sh script - shared/compose/helper/update_itg_properties.sh


Here’s an improved and more professional version of your documentation with clearer structure, grammar, and formatting:

---

### Sample Execution of `update_itg_properties.sh`

This section demonstrates the behavior of the `update_itg_properties.sh` script under different scenarios.

---

#### **1. Standalone Execution**

When `update_itg_properties.sh` is executed independently, the following three cases are illustrated in the screenshot below:

- **Case 1:** Invalid properties file
- **Case 2:** Missing properties file
- **Case 3:** Valid properties file

![properties files run sample](./README_images/img_1.png)

---

#### **2. Execution via `config_generate.sh`**

When `update_itg_properties.sh` is invoked from within the `config_generate.sh` script, the behavior varies based on user input:

- **Negative Case:**  
  If a Shift-Left user runs the script but chooses **not** to update the `itg.properties` file, the output appears as shown below:

![negative run scenario](./README_images/img_2.png)

- **Positive Case:**  
  If a Shift-Left user provides a **custom properties file** during execution, the script updates the configuration accordingly. The output is shown below:

 ![positive run scenario](./README_images/img_3.png)

---


## Troubleshooting



### Compose startup fails with ports not available

Error: In rare cases, the startup fails with the following error: 'bind: An attempt was made to access a socket in a way forbidden by its access permissions'.

Fix: Restart the 'Host Network service' (hns) via service dialog (requires admin permissions).

## Known Issues / Enhancements

Known issues are tracked here: https://jira.reval.com/issues/?filter=47449


## PCT Driver

The existing `runpctExperimental.sh` script now supports non-interactive DPCT or OPCT flows.
Use `./runpctExperimental.sh --usecase myusecase --version-manifest version.yaml -y` plus optional flags described in `runpctExperimental.sh --help`.

