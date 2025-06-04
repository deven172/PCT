#!/usr/bin/env groovy

import groovy.yaml.*
import org.apache.commons.cli.Option
import groovy.cli.commons.CliBuilder
import groovy.io.FileType

// ---------------------------------------------------------------------------
// Classes
// ---------------------------------------------------------------------------

class Service {
	String name
	String stack
	Boolean enabled
	Boolean running
	String status
	String type
	
	Service(String name, String stack) {
		this.name = name
		this.stack = stack
		this.enabled = true
		this.running = false
		this.status = "unhealthy"
		this.type = "app"
	}
	
	String toString() {
		"${name} (${stack}): ${enabled} (${running})"
	}
}

// ---------------------------------------------------------------------------
// HELPER
// ---------------------------------------------------------------------------

String COLOR_LIGHT_RED = "\u001B[31m"
String COLOR_LIGHT_GREEN = "\u001B[1;32m"	

static String color(String text, String ansiValue) {
    ansiValue + text + "\u001B[0m"
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------

// parse cli
def cli = new CliBuilder(
   usage: '-m mode -d composeFileDirectory -s services',
   header: '\nAvailable options:\n',
   footer: '\nInformation provided via above options is used enable/disable services in compose files.\n')

cli.with
{
   m(longOpt: 'mode', 'Mode (enable, disable, apply, show)', args: 1, required: true)
   s(longOpt: 'services', 'List of services (separated by ,)', args: '+', valueSeparator: ',')
   d(longOpt: 'composeFileDirectory', 'directory where compose files are located (default ../stacks)', args: 1)
}
def opt = cli.parse(args)
if (!opt) return

def mode = opt.m

def dir
if (!opt.d) {
	dir = new File("../stacks")
} else {
	dir = new File(opt.d)
}

// list of all services extracted from compose stacks
def composeServices = []
// list of services passed to this script
def passedServices = opt.ss
// list of services currently running
def runningServices = []
// list of services selected by passedServices (can contain regex, so can be different)
def selectedServices = []

// -----------------------------------------------------------------------------------------------------------
// read running currently services from docker ps
// -----------------------------------------------------------------------------------------------------------
def sout = new StringBuilder(), serr = new StringBuilder()
def proc = 'docker ps --format "{{.Names}}-{{.Status}}"'.execute()
proc.consumeProcessOutput(sout, serr)
proc.waitForOrKill(10000)
runningServices = sout.toString().replaceAll('"','').split('\n')

// -----------------------------------------------------------------------------------------------------------
// read available services from all available compose stacks / generate list of service objects
// -----------------------------------------------------------------------------------------------------------
def ys = new YamlSlurper()
dir.eachFileRecurse (FileType.FILES) { file ->
	def fileName = file.getName().take(file.name.lastIndexOf('.'))
	if(!fileName.contains('disable')) {
		def yaml = ys.parse(file)
		yaml.services.each  { k,v ->
			currentComposeService = new Service(k,fileName)
			
			// disable all services if mode is apply
			if(mode=='apply') {
				currentComposeService.enabled = false
			}
			if(runningServices.any(){ it.contains(currentComposeService.name)}) {
				currentComposeService.running = true
			}
			if(runningServices.any(){ it.matches("${currentComposeService.name}.*\\(healthy\\)")}) {
				currentComposeService.status = "healthy"
			}
			if(k.contains('db-update')){
				if(v.labels && v.labels."service.description".contains('lib')) {
					currentComposeService.type = "lib"
				} else {
					currentComposeService.type = "db"
				}
			}
			if(v.profiles && v.profiles.contains('sharedenv')) {
				// skip
			} else if(k.contains('sqlserver')) {
				// skip
			} else {
				composeServices << currentComposeService
			}
		}
	}
}

// -----------------------------------------------------------------------------------------------------------
// disable previously disabled services in service list (from disable files)
// -----------------------------------------------------------------------------------------------------------
ys = new YamlSlurper()
dir.eachFileRecurse (FileType.FILES) { file ->
	def fileName = file.getName().take(file.name.lastIndexOf('.'))
	if(fileName.contains('disable')) {
		def yaml = ys.parse(file)
		yaml.services.each  { k,v ->
			currentComposeService = composeServices.find { it.name == k && it.stack == fileName.minus("-disable") }
			if(currentComposeService) {
				currentComposeService.enabled = false
			}
		}
	}
}

// -----------------------------------------------------------------------------------------------------------
// enable / disable services based on current script input in service list
// -----------------------------------------------------------------------------------------------------------
if(passedServices) {
	passedServices.each { service ->
		def foundServices 
		foundServices = composeServices.findAll { it.name.matches(service) }

		if(!foundServices) {
			println "${service} not found, ignoring"
		} else  {
			selectedServices.addAll(foundServices)
		}
	}
	if(selectedServices) {
		selectedServices.each { k ->
			if(mode == 'enable') {
				k.enabled = true
			} else if(mode == 'disable') {
				k.enabled = false
			} else if(mode == 'apply') {
				k.enabled = true
			}
		}
	}
}

// -----------------------------------------------------------------------------------------------------------
// write disabled files
// -----------------------------------------------------------------------------------------------------------
if(mode != 'show') {

	// remove all disabled files
	dir.eachFileRecurse (FileType.FILES) { file ->
		if(file.getName().contains('disable.yml')) {
			file.delete()
		}
	}

	// group compose services by stack
	def composeServicesByStack = composeServices.groupBy{ it.stack }
	
	// write disabled files per stack
	composeServicesByStack.each { k,v ->
	
		stackHasDisabledService = false
		Map disabledServicesMap = [:]
		Map profiles = [profiles:['disabled']]
	
		v.each { i ->
			if(!i.enabled) {
				stackHasDisabledService = true
				disabledServicesMap[i.name] = profiles
			}
		}
	
		if(stackHasDisabledService) {
			Map yamlMap = [
			  services : disabledServicesMap
			]
			def yaml = new YamlBuilder()
			yaml(yamlMap)

			def myFile = new File("${dir}/${k}-disable.yml")
			myFile.write(yaml.toString())
		}
	}
}

// -----------------------------------------------------------------------------------------------------------
// stop/start/restart affected compose stacks
// -----------------------------------------------------------------------------------------------------------
if(mode == 'enable' || mode == 'disable') {
	// restart stacks with changes, does not start new stacks
	def modifiedServices = composeServices.findAll { (it.type == 'app' && it.enabled && !it.running) || (it.type == 'app' && !it.enabled && it.running) }
	def stacksWithRunningServices = composeServices.findAll { it.type == 'app' && it.running }.collect{ it.stack }.unique()

	def stacks = ""
	modifiedServices.each { s ->
		if(stacksWithRunningServices.contains(s.stack)) {
			stacks += s.stack.minus('-compose') + " "
		}
	}
	if(stacks) {
		println "Restarting Compose Stacks: ${stacks}"

		// stop stacks
		proc = "./service_stop.sh ${stacks}".execute()
		proc.waitForProcessOutput(System.out, System.err)

		// start stacks
		proc = "./service_start.sh ${stacks}".execute()
		proc.waitForProcessOutput(System.out, System.err)
	}
} else if(mode == 'apply') {
	
	// stop all running stacks, start all affected stacks
	
	def stacksWithRunningServices = composeServices.findAll { it.type == 'app' && it.running }.collect{ it.stack }.unique()
	def stacks = ""
	stacksWithRunningServices.each { s ->
		stacks += s.minus('-compose') + " "
	}
	if(stacks) {
		println "Stopping Compose Stacks: ${stacks}"
		proc = "./service_stop.sh ${stacks}".execute()
		proc.waitForProcessOutput(System.out, System.err)
	}
	// start lib db update stack
	stacks = ""
	def selectedServicesByStack = selectedServices.findAll { it.type == 'lib' }.groupBy{ it.stack }
	selectedServicesByStack.each { k,v ->
		stacks += k.minus('db-update-').minus('-compose') + " "
	}
	if(stacks) {
		println "Starting Lib Compose Stacks: ${stacks}"
		proc = "./database_update.sh ${stacks}".execute()
		proc.waitForProcessOutput(System.out, System.err)
	}
	// start db update stack
	stacks = ""
	selectedServicesByStack = selectedServices.findAll { it.type == 'db' }.groupBy{ it.stack }
	selectedServicesByStack.each { k,v ->
		stacks += k.minus('db-update-').minus('-compose') + " "
	}
	if(stacks) {
		println "Starting Db-update Compose Stacks: ${stacks}"
		proc = "./database_update.sh ${stacks}".execute()
		proc.waitForProcessOutput(System.out, System.err)
	}
	// stack app services stack
	stacks = ""
	selectedServicesByStack = selectedServices.findAll { it.type == 'app' }.groupBy{ it.stack }
	selectedServicesByStack.each { k,v ->
		stacks += k.minus('-compose') + " "
	}
	if(stacks) {
		println "Starting Compose Stacks: ${stacks}"
		proc = "./service_start.sh ${stacks}".execute()
		proc.waitForProcessOutput(System.out, System.err)
	}
	
}

// -----------------------------------------------------------------------------------------------------------
// refresh service status
// -----------------------------------------------------------------------------------------------------------
sout = new StringBuilder()
serr = new StringBuilder()
proc = 'docker ps --format "{{.Names}}-{{.Status}}"'.execute()
proc.consumeProcessOutput(sout, serr)
proc.waitForOrKill(10000)
runningServices = sout.toString().replaceAll('"','').split('\n')

composeServices.each { s ->
	
	if(runningServices.any(){ it.contains(s.name)}) {
		s.running = true
	} else {
		s.running = false
	}
	if(runningServices.any(){ it.matches("${s.name}.*\\(healthy\\)")}) {
		s.status = "healthy"
	}
	if(runningServices.any(){ it.matches("${s.name}.*\\(unhealthy\\)")}) {
		s.status = "unhealthy"
	}
	if(runningServices.any(){ it.matches("${s.name}.*\\(health: starting\\)")}) {
		s.status = "starting"
	}

}

// -----------------------------------------------------------------------------------------------------------
// print service status summary
// -----------------------------------------------------------------------------------------------------------

println "------------------------------------------"
println "Service Status"
println "------------------------------------------"

def composeServicesByType = composeServices.sort{it.type}.groupBy{it.type}
composeServicesByType.each {serviceType,services ->
	println "------------------------------------------"
	println "${serviceType}"
	println "------------------------------------------"
	services.sort{ it.name }.each { k ->
		def output = "${k.name} (${k.stack}): "
		if (k.enabled) {
			output += color("enabled", COLOR_LIGHT_GREEN)
		} else {
			output += color("disabled", COLOR_LIGHT_RED)
		}
		if (k.type == "app"){
			if (k.running) {
				output += " (running/"
				if(k.status == 'healthy') {
					output += color(k.status, COLOR_LIGHT_GREEN)  + ")"
				} else if(k.status == 'unhealthy') {
					output += color(k.status, COLOR_LIGHT_RED)  + ")"
				} else  {
					output += k.status + ")"
				}
			} else {
				output += " (not running)"
			}
		}
		println output
	}
}