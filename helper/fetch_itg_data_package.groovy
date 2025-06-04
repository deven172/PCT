#!/usr/bin/env groovy

import groovy.yaml.YamlSlurper
import org.apache.commons.cli.Option
import groovy.cli.commons.CliBuilder

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------

// parse cli
def cli = new CliBuilder(
   usage: '-v version -o output -d dpwnload',
   header: '\nAvailable options:\n',
   footer: '\nInformation provided via above options is used fetch api jars.\n')

cli.with
{
   v(longOpt: 'version', 'Version File', args: 1, required: true)
   o(longOpt: 'output', 'Output Directory', args: 1, required: true)
   d(longOpt: 'download', 'Download Source (s3, artifactory)', args: 1, defaultValue: 's3')
}
def opt = cli.parse(args)
if (!opt) return

def output = opt.o
def version = opt.v
def download = opt.d

def ys = new YamlSlurper()
def ver = ys.parse(new File(version))
def command
def dncUpdatePackageVersion = ver.'data'.'dnc-update-package'.version
def dataPackageFileName = "itg-data-package-${dncUpdatePackageVersion}"

def region
def s3Url
if(download.startsWith('s3')) {
	def isProd = false
	if(download == 's3-prod' || download == 's3-uat') {
		isProd = true
	}
	def itgenv = download.split('-')[1]
	def s3bucket = isProd ? 'client-itg' : 'icrq-574-s3-bucket'
	region = isProd ? 'ca-central-1' : 'us-east-1'
	s3Url = "s3://${s3bucket}/artifacts/${itgenv}/${ver.itg.version}/dnc-saas"
	command = "aws s3 cp  ${s3Url}/${dataPackageFileName}.zip ${output}/. --region ${region}"
	
} else {
	command = "curl --fail-with-body http://repograz.reval.com:8081/artifactory/gradle-all-resolve/com/reval/itg-data-package/${dataPackageFileName}.zip  --output ${output}"
}
def proc = command.execute()
proc.waitFor()
println proc.in.text
def exitcode= proc.exitValue()
def error = proc.err.text
if (error) {
	println "Std Err: ${error}"
	println "Process exit code: ${exitcode}"
	return exitcode
}
