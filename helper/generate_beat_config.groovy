#!/usr/bin/env groovy

import groovy.yaml.YamlSlurper;
import groovy.yaml.YamlBuilder;
import groovy.xml.XmlSlurper;
import groovy.xml.XmlUtil;
import org.apache.commons.cli.Option
import groovy.cli.commons.CliBuilder
import java.util.regex.Matcher;

// ---------------------------------------------------------------------------
// HELPER
// ---------------------------------------------------------------------------

def deepcopy(obj){
	return new groovy.json.JsonSlurper().parseText(groovy.json.JsonOutput.toJson(obj))
}
def getValueFromEnvFile(itgenvfile, section, cmpnt, node, maincmpnt=null){
	def returnValue = ""
	if (itgenvfile."${section}"."${cmpnt}" && itgenvfile."${section}"."${cmpnt}"."${node}"){
		if(node.equalsIgnoreCase("instances")){
			returnValue = returnValue + itgenvfile."${section}"."${cmpnt}"."${node}"
		}	
		returnValue = returnValue.trim()
	}
	return returnValue
}
def getContainerName(component)
{
    switch(component){
        case 'ui':
            return 'ebics-ui'
        case 'ebics':
            return 'ebics-server'
        default:
            return component
    }
}
def getLogComponentName(component)
{   
    if (component.startsWith('banking-api-')){
       def matches = component=~/banking-api-(\w*)-(.*)/ 
       return "bankingapi_" + matches[0][1]
    }
    else{
         switch(component){
            case 'ui':
                return 'reval_hub_ebics_ui'
            case 'hub':
                return 'reval_hub_api'
			case 'hub-internal':
                return 'reval_hub_private_api'
            case 'ebics-server':
                return 'reval_hub_ebics_server'
            case 'mq':
                return 'reval_hub_mq'
            case 'scheduler':
                return 'reval_hub_scheduler'
            case 'keycloak':
                return 'reval_hub_keycloak'
            case 'itg-api-server':
                return 'itgapi'
            case 'dnc-adapter-server':
                return 'reval_hub_dnc_adapter'
            case 'master-data-spot-server':
                return 'reval_hub_master-data-spot'
            default:
                return component.replaceAll("-server","")
        }
    }
}
def getLogComponentType(node, component)
{
    if (node.equalsIgnoreCase('ebics')){
        return getLogComponentName(component).toUpperCase()
    }
    else if(node.equalsIgnoreCase('spot')){
        if (component.startsWith('banking-api-')){
            return 'REVAL_HUB_BANKINGAPI'
        } else if (component.equalsIgnoreCase('itg-api-server')){
            return 'REVAL_HUB_ITGAPI'
        } else if (component.equalsIgnoreCase('dnc-adapter-server')){
            return 'REVAL_HUB_DNC_ADAPTER'
        } else if (component.equalsIgnoreCase('master-data-spot-server')){
            return 'REVAL_HUB_MASTER_DATA_SPOT'
        } else if (component.equalsIgnoreCase('ebics-server')){
            return getLogComponentName(component).toUpperCase()
        } else{
            return "REVAL_HUB_${component.replaceAll("-server","").replaceAll("-","_").toUpperCase()}"
        }
    }
	else{
         return getLogComponentName(component).toUpperCase()
    }
    return component
}

def getModule(node,component)
{
    if (node.equalsIgnoreCase('ebics')){
        return "EBICS"
    }
    else if(node.equalsIgnoreCase('spot')){
        if (component.startsWith('banking-api-')){
            return 'BANKINGAPI'
        } else if (component.equalsIgnoreCase('itg-api-server')){
            return 'ITGAPI'
        } else if (component.equalsIgnoreCase('dnc-adapter-server')){
            return 'BANKINGAPI'
        } else if (component.equalsIgnoreCase('master-data-spot-server')){
            return 'MASTERDATASPOT'
        } else if (component.equalsIgnoreCase('ebics-server')){
            return 'EBICS'
        } 
		else{
            return "${component.replaceAll("-server","").replaceAll("-","").toUpperCase()}"
        }
    }
	else{
         return "${component.replaceAll("-server","").replaceAll("-","").toUpperCase()}"
    }
    return component
}


// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------

// parse cli
def cli = new CliBuilder(
   usage: '-p properties -t template -o output',
   header: '\nAvailable options:\n',
   footer: '\nInformation provided via above options is used to generate appconfig.\n')

cli.with
{
   p(longOpt: 'properties', 'Property File', args: 1, required: true)
   t(longOpt: 'template', 'Appconfig Template', args: 1, required: true)
   o(longOpt: 'output', 'Output Filename', args: 1, required: true)
   e(longOpt: 'environment', 'Environment Filename (only required for spot/mock)', args: 1, required: false)
   c(longOpt: 'component', 'Specific component to generate appconfig for (only required for spot/mock)', args: 1, required: false)
   h(longOpt: 'hostname', 'Hostname', args: 1)
   n(longOpt: 'nodename', 'Nodename', args: 1)
   l(longOpt: 'local', 'Is Local', args: 1)
}
def opt = cli.parse(args)
if (!opt) return

def properties = opt.p
def template = opt.t
def output = opt.o
def environment = opt.e
def component = opt.c
def hostname = opt.h
def nodename = opt.n
def isLocal = opt.l

if(!hostname) {
	hostname = "host.docker.internal"
}

// read properties
Properties props = new Properties()
File propsFile = new File(properties)
propsFile.withInputStream {
    props.load(it)
}

if(!component) {
	File templateFile = new File(template)
	String appconfig = templateFile.text
	props.each {appconfig = appconfig.replaceAll("(?i)%${it.key}%", Matcher.quoteReplacement(it.value))}
	if(hostname && appconfig.contains("%hostname%")){
		appconfig = appconfig.replaceAll("%hostname%", hostname)
	}
	if(nodename && appconfig.contains("%node-name%")){
		appconfig = appconfig.replaceAll("%node-name%", nodename)
	}
	if(isLocal && template.contains("metrics.conf")){
		appconfig = appconfig.replaceAll('index => "metricbeat-%\\{\\+YYYY\\.MM\\.dd\\}"', 'index => "local-metricbeat-%{+YYYY.MM.dd}"')
	}
	if(isLocal && template.contains("troubleshooting.conf")){
		appconfig = appconfig.replaceAll('index => "ts-live-treasury-%\\{\\+YYYY\\.MM\\.dd\\}"', 'index => "local-ts-live-treasury-%{+YYYY.MM.dd}"')
	}
	def appconfigFile = new File(output)
	appconfigFile.write(appconfig)
} else {
	def ys = new YamlSlurper()
	def env = ys.parse(new File(environment))
	def configNode
	
	def tmplt = ys.parse(new File(template))
	def templateDefault = tmplt."filebeat.autodiscover".providers[0].templates[0]
	tmplt."filebeat.autodiscover".providers[0].templates.remove(0)
	
	["core","spot","camunda"].each{ node ->
		if(env."${node}") {
			env."${node}".each { c ->
				def cmpnt = c.key.toString()
				// Skip non-container components
                if (!(cmpnt.equalsIgnoreCase("authkeycloakEar") ||
					  cmpnt.equalsIgnoreCase("cds") ||
					  cmpnt.equalsIgnoreCase("mdi"))){
					def instances = getValueFromEnvFile(env,"${node}","${cmpnt}","instances")
					def instancesExists = false
					if(instances){
					    instancesExists = true
					}
					if(!instancesExists){
						instances=1
					}
					def containerName=cmpnt
					for (int i = 0; i < instances.toInteger(); i++) {
						def idx = (i+1).toString()
						if(instances>1){
							containerName="${cmpnt}-${idx}"
						}
                        def cmpntConfig = templateDefault
                        cmpntConfig.condition."equals.docker.container.name" = getContainerName(containerName)
                        cmpntConfig.config[0].fields.logComponentName = getLogComponentName(cmpnt)
                        cmpntConfig.config[0].fields.logComponentType = getLogComponentType(node,cmpnt)
                        cmpntConfig.config[0].fields.Module = getModule(node,cmpnt)
                        tmplt."filebeat.autodiscover".providers[0].templates.add(deepcopy(cmpntConfig))
					}
               }
			}
		}
	} 
	def configFile = new File(output)
	def config = new YamlBuilder()
	config(tmplt)
	configFile.write(config.toString())
}
