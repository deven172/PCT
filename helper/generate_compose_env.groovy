#!/usr/bin/env groovy

import groovy.yaml.YamlSlurper
import groovy.xml.XmlSlurper;
import groovy.xml.XmlUtil;
import org.apache.commons.cli.Option
import groovy.cli.commons.CliBuilder
import java.util.regex.Matcher;

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------

// parse cli
def cli = new CliBuilder(
   usage: '-p properties -v version',
   header: '\nAvailable options:\n',
   footer: '\nInformation provided via above options is used to generate appconfig.\n')

cli.with
{
   p(longOpt: 'properties', 'Property File', args: 1, required: true)
   v(longOpt: 'version', 'Version File', args: 1, required: true)
   b(longOpt: 'basedir', 'Base directory', args: 1)
   h(longOpt: 'hostname', 'Hostname', args: 1)
   l(longOpt: 'logstashhostname', 'LogStashHostname', args: 1)
}
def opt = cli.parse(args)
if (!opt) return

def local = false
def properties = opt.p
def version = opt.v
def basedir = opt.b
def logstashhostname = opt.l
def itgprojectname = 'itg'
if(!basedir) {
	basedir = "${System.getProperty('user.dir')}"
}
def hostname = opt.h
if(!hostname) {
	local = true
	hostname = "host.docker.internal"
}
def filebeatcommand="\"\\\"filebeat\\\" \\\"-e\\\" \\\"-strict.perms\\=false\\\" \\\"-c\\\" \\\"/usr/share/filebeat/beat.d/filebeat.yml\\\"\""
if(local){
	filebeatcommand="\"\\\"filebeat\\\" \\\"-e\\\" \\\"-strict.perms\\=false\\\" \\\"-c\\\" \\\"/usr/share/filebeat/beat.d/filebeat_ebics.yml\\\" \\\"-c\\\" \\\"/usr/share/filebeat/beat.d/filebeat_dnc.yml\\\"\""
}

def appProps = new Properties()
def dbProps = new Properties()

// set static properties
appProps.setProperty('COMPOSE_PROJECT_NAME', "${itgprojectname}")
appProps.setProperty('HUB_CONFIGDIR', "${basedir}/hub/itsconfig")
appProps.setProperty('UI_CONFIGDIR', "${basedir}/ebicsui/itsconfig")
appProps.setProperty('HUB_INTERNAL_CONFIGDIR', "${basedir}/hub-internal/itsconfig")
appProps.setProperty('HUB_INTERNAL_API', "${basedir}/hub-internal/hubapi")
appProps.setProperty('HUB_API', "${basedir}/hub/hubapi")
appProps.setProperty('CAMUNDA_CONFIG_DIR', "${basedir}/camunda/itsconfig")
appProps.setProperty('CAMUNDA_WORKER_PLUGINS_DIR', "${basedir}/camunda/cwplugins")
appProps.setProperty('SPOT_CONFIGDIR', "${basedir}/spot/itsconfig")
appProps.setProperty('MOCK_CONFIGDIR', "${basedir}/mock/itsconfig")
appProps.setProperty('BEAT_CONFIGDIR', "${basedir}/beat")
appProps.setProperty('SPOT_CONFIGDIR', "${basedir}/spot/itsconfig")
appProps.setProperty('MOCK_KEYSDIR', "${basedir}/mock")
appProps.setProperty('MOCK_SFTPDIR', "/efs/mocks/sftp")	
appProps.setProperty('PLATFORM_DIR', "${basedir}/ion/platform")
appProps.setProperty('DNC_PACKAGE_DIR', "${basedir}/dnc-saas")
appProps.setProperty('HOSTNAME',hostname)
appProps.setProperty('LOGSTASH_HOSTNAME',"${logstashhostname}")
appProps.setProperty('FILEBEAT_COMMAND',"${filebeatcommand}")

// this is only required for local env...
if(local) {
	appProps.setProperty('KEYCLOAK_INIT','./init/hub-realm.json')
	appProps.setProperty('KEYCLOAK_UI_INIT','./init/ebics-ui-realm.json')
	appProps.setProperty('MOCK_SFTPDIR', "${basedir}/mock/sftp_data")
	appProps.setProperty('SQLSERVER_DATA', "${basedir}/sqlserverdata")
	appProps.setProperty('SQLSERVER_BACKUP', "${basedir}/sqlserverbackup")
	appProps.setProperty('SQLSERVER_INIT', "${basedir}/init")	
	appProps.setProperty('SQLSERVER_RESTORE_DBNAMES', "")
	dbProps.setProperty('SQLSERVER_DATA', "${basedir}/sqlserverdata")
	dbProps.setProperty('SQLSERVER_BACKUP', "${basedir}/sqlserverbackup")
	dbProps.setProperty('SQLSERVER_INIT', "${basedir}/init")	
	dbProps.setProperty('SQLSERVER_RESTORE_DBNAMES', "")
}

dbProps.setProperty('COMPOSE_PROJECT_NAME', "${itgprojectname}")

// add uid and gid
def sout = new StringBuilder()
def serr = new StringBuilder()
def proc = 'id -u'.execute()
proc.waitForProcessOutput(sout, serr)
appProps.setProperty('COMPOSE_UID',sout.toString().trim())
sout = new StringBuilder()
serr = new StringBuilder()
proc = 'id -g'.execute()
proc.waitForProcessOutput(sout, serr)
appProps.setProperty('COMPOSE_GID',sout.toString().trim())

// add values from version file
ys = new YamlSlurper()
def ver = ys.parse(new File(version))

["core","mock","spot","camunda","lib","dnc-saas","data","monitoring"].each{ node ->
	ver."${node}".each { k,v ->
		appProps.setProperty("VERSION_${k.toUpperCase().replaceAll("-","_")}", "${v.version}")
		dbProps.setProperty("VERSION_${k.toUpperCase().replaceAll("-","_")}", "${v.version}")
	}
}

// add values from properties
Properties props = new Properties()
File propsFile = new File(properties)
propsFile.withInputStream {
    props.load(it)
}
props.each { k,v ->
	// db props
	if(k.endsWith('db-update-username')) {
		def propName = k.minus('-db-update-username').toUpperCase().replaceAll("-","_")
		dbProps.setProperty("LIQUIBASE_COMMAND_USERNAME_${propName}", v)
	}
	if(k.endsWith('db-update-password')) {
		def propName = k.minus('-db-update-password').toUpperCase().replaceAll("-","_")
		dbProps.setProperty("LIQUIBASE_COMMAND_PASSWORD_${propName}", v)
	}
	if(k.endsWith('db-schema')) {
		def propName = k.minus('-db-schema').toUpperCase().replaceAll("-","_")
		dbProps.setProperty("LIQUIBASE_COMMAND_URL_${propName}", "jdbc:sqlserver://${props['db-server']}:1433;DatabaseName=${v};encrypt=true;trustServerCertificate=true")
	}
	if(k.endsWith('db-username')) {
		def propName = k.minus('-db-username').toUpperCase().replaceAll("-","_")
		dbProps.setProperty("${propName}_DB_USERNAME", "${v}")
	}
	if(k.endsWith('db-password')) {
		def propName = k.minus('-db-password').toUpperCase().replaceAll("-","_")
		dbProps.setProperty("${propName}_DB_PASSWORD", "${v}")
	}
	if(k.endsWith('db-jdbc-url')) {
		def propName = k.minus('-db-jdbc-url').toUpperCase().replaceAll("-","_")
		dbProps.setProperty("${propName}_DB_JDBC_URL", "${v}")
	}
	// app props
	if(local) {
		// need keycloak props in app.env as keycloak needs db connection detail as env variables on startup (does not use liquibase)
		if(k.startsWith('keycloak')) {
			def propName = k.toUpperCase().replaceAll("-","_")
			appProps.setProperty("${propName}", "${v}")
		}
	}
}

// Explicitly delete the env files
new File('app.env').delete()
new File('db.env').delete()

def propsFileApp = new File('app.env')
appProps = appProps.sort{ it.key }
propsFileApp.withWriter( 'UTF-8' ) { fileWriter ->
    appProps.each { key, value ->
        fileWriter.writeLine "$key=$value"
    }
}

def dbFileApp = new File('db.env')
dbProps = dbProps.sort{ it.key }
dbFileApp.withWriter( 'UTF-8' ) { fileWriter ->
    dbProps.each { key, value ->
        fileWriter.writeLine "$key=$value"
    }
}