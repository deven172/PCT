#!/usr/bin/env groovy

import groovy.yaml.YamlSlurper
import groovy.xml.XmlSlurper;
import groovy.xml.XmlUtil;
import org.apache.commons.cli.Option
import groovy.cli.commons.CliBuilder
import java.util.regex.Matcher;

// ---------------------------------------------------------------------------
// HELPER
// ---------------------------------------------------------------------------

def RemoveNodes(configXml, spot, isBankingApiNamedSpot) {
	def configNode = new XmlSlurper().parseText(configXml)
	if (spot.equalsIgnoreCase("UDDR")) {
		// For UDDR spot, remove all other nodes from config, including GlobalParams, DataConn
		configNode."*".findAll {!(it.name().equalsIgnoreCase(spot))}.replaceNode {};
	}
	else {
		if(isBankingApiNamedSpot) {
			configNode."*".findAll {!(it.name().equalsIgnoreCase("GlobalParams") ||
									it.name().equalsIgnoreCase("DataConn") ||
									it.name().equalsIgnoreCase("BankingApi") ||
									it.name().equalsIgnoreCase("CNCL") ||
									it.name().equalsIgnoreCase("JRNL") ||
									it.name().equalsIgnoreCase("BusinessEventApi") ||
									it.name().equalsIgnoreCase(spot))}
									.replaceNode {};
		}
		else {
			configNode."*".findAll {!(it.name().equalsIgnoreCase("GlobalParams") ||
									it.name().equalsIgnoreCase("DataConn") ||
									it.name().equalsIgnoreCase("CNCL") ||
									it.name().equalsIgnoreCase("JRNL") ||
									it.name().equalsIgnoreCase("BusinessEventApi") ||
									it.name().equalsIgnoreCase("TenantLib") ||
									it.name().equalsIgnoreCase(spot))}
									.replaceNode {};
		}
	}

	return XmlUtil.serialize(configNode).toString()
}

def MergeSpotNodes(configXml, spot, targetSpot) {
	def configNode = new XmlSlurper().parseText(configXml)
	if(configNode.spot){
		configNode."${spot}"."*".collect{configNode."${targetSpot}".appendNode(it)}
	}
	configNode."*".findAll {(it.name().equalsIgnoreCase(spot))}.replaceNode {};
	return XmlUtil.serialize(configNode).toString()
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
}
def opt = cli.parse(args)
if (!opt) return

def properties = opt.p
def template = opt.t
def output = opt.o
def environment = opt.e
def component = opt.c

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
	def appconfigFile = new File(output)
	appconfigFile.write(appconfig)
} else {
	def ys = new YamlSlurper()
	def env = ys.parse(new File(environment))
	def configNode
	env."${component}".each{node ->
		def item=node.key.toString()
		if (env."${component}"."${item}" && env."${component}"."${item}".'config-node'){
				configNode = env."${component}"."${item}".'config-node'
		}
		if(configNode) {
			File templateFile = new File(template)
			String appconfig = templateFile.text
			def bankingApiSpot = (item.toLowerCase().startsWith("banking-api-")) ? true : false
			if (bankingApiSpot){
				//Merge Same Named Nodes
				if(component == 'spot') {
					appconfig = MergeSpotNodes(appconfig,configNode,"BankingApiSpotTemplate")
				}
				// replace node name
				if(component == 'spot') {
					appconfig = appconfig.replaceAll("BankingApiSpotTemplate",configNode)
					// replace variable names
					appconfig = appconfig.replaceAll("bankingapispot",configNode)
				} else {
					appconfig = appconfig.replaceAll("(?i)BankingApiMock",configNode)
				}
				//Remove all nodes except GlobalParams, DataConn, BankingApi and the specific spot in appconfig.xml									
				appconfig = RemoveNodes(appconfig, configNode, true)
			}
			else {
				//Remove all nodes except GlobalParams, DataConn and the specific spot in appconfig.xml	
				appconfig = RemoveNodes(appconfig, configNode, false)
			}
			props.each {appconfig = appconfig.replaceAll("(?i)%${it.key}%", Matcher.quoteReplacement(it.value))}
			def configname=output
			configname=configname.replaceAll("appconfig.","appconfig_${configNode}.")
			def appconfigFile = new File(configname)
			appconfigFile.write(appconfig)
		}
	}
}
