import groovy.yaml.YamlSlurper
import org.apache.commons.cli.Option
import groovy.cli.commons.CliBuilder

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------

// parse cli
def cli = new CliBuilder(
   usage: '-c component -v version -o outputDir',
   header: '\nAvailable options:\n',
   footer: '\nInformation provided via above options is used to generate Dockerfile.\n')

cli.with
{
   c(longOpt: 'component', 'Specific component to generate the Dcokerfile file for', args: 1, required: true)
   v(longOpt: 'version', 'Version File', args: 1, required: true)
   o(longOpt: 'outputDir', 'Dockerfile Output Directory', args: 1, required: true)
}
def opt = cli.parse(args)
if (!opt) return

def component = opt.c
def version = opt.v
def outputDir = opt.o

def ys = new YamlSlurper()
def verFile = ys.parse(new File(version))
def forComponent = "msg-transformation"
if (component.startsWith("scs")){
        forComponent = "scs-exceptions"
}
def componentVersion = verFile."dnc-saas"."${forComponent}".version

def text = """
FROM suite-ci.iongroup.com:5005/dnc_bank_connectivity_phase_2:${componentVersion}
"""
def dockerFile = new File("${outputDir}/${component}_Dockerfile")
dockerFile.write(text)
def cmd = ["/bin/sh", "-c", "docker build . -t ${component}:${componentVersion} -f ${outputDir}/${component}_Dockerfile"]
cmd.execute().with{
    def output = new StringWriter()
    def error = new StringWriter()
    //wait for process ended and catch stderr and stdout.
    it.waitForProcessOutput(output, error)
    //check there is no error
    println "error=$error"
    println "output=$output"
    println "code=${it.exitValue()}"
}