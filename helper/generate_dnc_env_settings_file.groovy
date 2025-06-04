import groovy.yaml.YamlSlurper
import groovy.xml.XmlSlurper;
import groovy.xml.XmlUtil;
import org.apache.commons.cli.Option
import groovy.cli.commons.CliBuilder
import java.util.regex.Matcher;

// ---------------------------------------------------------------------------
// HELPER
// ---------------------------------------------------------------------------

def handleSettingOverrideEnvOption(settingOverrideValue){
    def temp = []
    settingOverrideValue.split("],").each {
      def compName = it.tokenize('[')[0]
      def setting = settingOverrideValue.findAll(/${compName}\[(.*?)\]/){match -> match[1].trim()}
      temp.add("${compName}[${setting.join(",")}]")
    }
    return temp.unique().join(",")
}

def getEnvSettingFromFile(envList, envVar_FromFile){
        if (envVar_FromFile.contains("=")){
                key_FromFile = envVar_FromFile.split("=",2)[0]
                value_FromFile = envVar_FromFile.split("=",2)[1]
                //Add envVar_FromFile to envList if it does not exist already
                if (!envList.any{it.split("=")[0].equalsIgnoreCase(key_FromFile)}){
                        envList.add(envVar_FromFile)
                }
                else {
                        envList.each { envVar ->
                                if (envVar.contains("=")){
                                        envKey = envVar.split("=",2)[0]
                                        envValue = envVar.split("=",2)[1]
                                        if (key_FromFile.equalsIgnoreCase(envKey)){
                                                value_combined = "$envValue,$value_FromFile"
                                                if (key_FromFile.equalsIgnoreCase("SETTING_OVERRIDE")) {
                                                        // To handle SETTING_OVERRIDE env option
                                                        // from SETTING_OVERRIDE=MessageTransformation[db.servicename:test],MessageTransformation[health.jetty.port:4019]
                                                        // to   SETTING_OVERRIDE=MessageTransformation[db.servicename:test, health.jetty.port:4019]
                                                        value_combined = handleSettingOverrideEnvOption(value_combined)
                                                }
                                                envList[envList.indexOf(envVar)] = envVar.replace(envValue,value_combined)
                                        }
                                }
                        }
                }
        }
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------

// parse cli
def cli = new CliBuilder(
   usage: '-p properties -c component -e environment -o output -h hostname -d dbName -l isLocal',
   header: '\nAvailable options:\n',
   footer: '\nInformation provided via above options is used to generate appconfig.\n')

cli.with
{
   p(longOpt: 'properties', 'Property File', args: 1, required: true)
   c(longOpt: 'component', 'Specific component to generate the environment file for', args: 1, required: true)
   e(longOpt: 'environment', 'Provide environment file', args: 1, required: true)
   o(longOpt: 'output', 'Output Filename', args: 1, required: true)
   h(longOpt: 'dbHostName', 'Provide Database Hostname', args: 1, required: true)
   d(longOpt: 'dbName', 'Provide Database Name', args: 1, required: true)
   l(longOpt: 'isLocal', 'Specify true for devbox', type: boolean, args: 1, required: true)
}
def opt = cli.parse(args)
if (!opt) return

def properties = opt.p
def component = opt.c
def environment = opt.e
def output = opt.o
def dbHostName = opt.h
def dbName = opt.d
def isLocal = opt.l

// read properties
Properties props = new Properties()
File propsFile = new File(properties)
propsFile.withInputStream {
    props.load(it)
}

def ys = new YamlSlurper()
def itgenvfile = ys.parse(new File(environment))

def mmComponentName = "MessageManager"
def additionalUsers = "ADDITIONAL_USERS=${props['itgops-user']}:\"${props['itgops-password']}\",${props['iontms-user']}:\"${props['iontms-password']}\""
def ionWebServerSettings = ""
def mainComponent = "dnc-saas"

if(!isLocal && !((component == "dnc-update") || (component == "scs-update"))){
        ionWebServerSettings = "ION_WEB_SERVER[ionweb.secureconnections:1,ionweb.keystore:/var/tmp/itg-internal.jks,ionweb.keystorepwd:${props['ionweb-keystorepwd']},ionweb.keypwd:${props['ionweb-keypwd']}]"
}

if ((component == "scs-screening") || (component == "msg-transformation") ){
        mmComponentName = "MessageTransformation"
}

if ((component == "dnc-update") || (component == "scs-update") ){
        mainComponent = "data"
}
def settingOverride = "SETTING_OVERRIDE=ANY[DB_CONNECT_STRING:\"jdbc:sqlserver://${dbHostName}:1433;databaseName=${dbName}\",DB_HOST:${dbHostName},DB_NAME:${dbName}]," +
        "SDS[sds.db.user:${props['service-sds-db-user']},sds.db.password:${props['service-sds-db-password']}]," +
        "refdata[DBUSER:${props['service-refdata-db-user']},DBPWD:${props['service-refdata-db-password']}]," +
        "rules_engine_server[db.servicename:,db.user:${props['service-res-db-user']},db.password:${props['service-res-db-password']}]," +
        "${mmComponentName}[db.servicename:,db.user:${props['service-mm-db-user']},db.password:${props['service-mm-db-password']}]," +
        "entitlement_server[db.servicename:,db.user:${props['service-es-db-user']},db.password:${props['service-es-db-password']}]," +
        "sanctions_screening[db.servicename:,db.user:${props['service-scs-db-user']},db.password:${props['service-scs-db-password']}," +
        "${ionWebServerSettings}"

def envVariables = ["START_DBMS=false",
        "DB_HOST=${dbHostName}",
        "DB_NAME=${dbName}",
        "${settingOverride}",
        "${additionalUsers}"]

if (itgenvfile."${mainComponent}"."${component}" && itgenvfile."${mainComponent}"."${component}"."env"){
        itgenvfile."${mainComponent}"."${component}"."env".each{k ->
                getEnvSettingFromFile(envVariables,k)
        }
}

def envSettingConfig = new File(output)
envSettingConfig.write(envVariables.join("\n"))