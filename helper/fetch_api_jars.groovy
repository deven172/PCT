#!/usr/bin/env groovy

import groovy.yaml.YamlSlurper
import org.apache.commons.cli.Option
import groovy.cli.commons.CliBuilder

// ---------------------------------------------------------------------------
// HELPER
// ---------------------------------------------------------------------------

def downloadApiJar(download,apiJarFile,outputLocation,region,s3Url){
	def retval = true
	def command
	if(download.startsWith('s3')) {
		command = "aws s3 cp  ${s3Url}/${apiJarFile} ${outputLocation} --region ${region}"
		println "downloading: ${apiJarFile} from S3"
	} else {
		def outFile = new File(apiJarFile)
		command = "curl --fail-with-body http://repograz.reval.com:8081/artifactory/gradle-all-resolve/${apiJarFile} --output ${outputLocation}/${outFile.getName()}"
		println "downloading: ${apiJarFile} from artifactory"
	}
	
	def proc = command.execute()
	proc.waitFor()
	def exitcode = proc.exitValue()
	def error = proc.err.text
	if (exitcode) {
		retval = false
		println "error: ${error}"
	}
	return retval
}

def getOutputLocationByLabel(output, label) {
	if(output[label]) {
		return output[label]
	} else if(output['default']) {
		return output['default']
	} else {
		return output.values().toArray()[0]
	}
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------

// parse cli
def cli = new CliBuilder(
   usage: '-e environemnt -v version -o output',
   header: '\nAvailable options:\n',
   footer: '\nInformation provided via above options is used fetch api jars.\n')

cli.with
{
   e(longOpt: 'environment', 'Environment File', args: 1, required: true)
   v(longOpt: 'version', 'Version File', args: 1, required: true)
   o(longOpt: 'output', 'Output Directory (can also be a list in following format label1:/location1,label2:/location2; labels must match api jar definition in env file)', args: 1, required: true)
   d(longOpt: 'download', 'Download Source (s3-<env>,rt)', args: 1, defaultValue: 'rt')
   c(longOpt: 'component', 'Component to fetch api jars for (hub,camunda)', args: 1, defaultValue: 'hub')
}
def opt = cli.parse(args)
if (!opt) return
	
def output = [:]
opt.o.split(",").each { param ->
    def nameAndValue = param.split(":")
	if(nameAndValue.size()>1) {
		output[nameAndValue[0]] = nameAndValue[1]
	} else {
		output['default'] = nameAndValue[0]
	}
}

def environment = opt.e
def version = opt.v
def download = opt.d
def component = opt.c

def ys = new YamlSlurper()
def env = ys.parse(new File(environment))

ys = new YamlSlurper()
def ver = ys.parse(new File(version))

def region
def s3Url
def downloadError
if(download.startsWith('s3')) {
	def isProd = false
	if(download == 's3-prod' || download == 's3-uat') {
		isProd = true
	}
	def itgenv = download.split('-')[1]
	def s3bucket = isProd ? 'client-itg' : 'icrq-574-s3-bucket'
	region = isProd ? 'ca-central-1' : 'us-east-1'
	s3Url = "s3://${s3bucket}/artifacts/${itgenv}/${ver.itg.version}"
}

def downloadSource = 'api-jar-file-path'
if(component == 'camunda') {
	downloadSource = downloadSource + '-camunda'
}
if(download.startsWith('s3')) {
	downloadSource = downloadSource + '-s3'
}

["core","spot","mock","camunda"].each{ node ->
	ver."${node}".each { k,v ->
		if (env."${node}"."${k}" && env."${node}"."${k}"."${downloadSource}"){
			def c = env."${node}"."${k}"."${downloadSource}"
			if (!(c instanceof String)){
				c.each {
					def apiJarFilePath_Parts = it.replaceAll('%version%',ver."${node}"."${k}".version).split(":")
					def apiJarFile = apiJarFilePath_Parts[0]
					def apiJarFileLabel = []
					if(apiJarFilePath_Parts.size()>1) {
						apiJarFilePath_Parts[1].split(",").each {apiJarFileLabel.add(it)}
					} else {
						// default to public hub when no label is specified in env file
						apiJarFileLabel.add("hub")
					}
					apiJarFileLabel.each { l ->
						if(!downloadApiJar(download,apiJarFile,getOutputLocationByLabel(output,l),region,s3Url)) {
							downloadError = true
						}
					}
				}
			} else {
				c = c.replaceAll('%version%',ver."${node}"."${k}".version)
				if(!downloadApiJar(download,c,getOutputLocationByLabel(output,'default'),region,s3Url)) {
					downloadError = true
				}
			}
		}
	}
}

if(downloadError) {
	System.exit(1)
}