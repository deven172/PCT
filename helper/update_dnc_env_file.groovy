#!/usr/bin/env groovy

import groovy.yaml.YamlSlurper
import groovy.xml.XmlSlurper;
import groovy.xml.XmlUtil;
import org.apache.commons.cli.Option
import groovy.cli.commons.CliBuilder
import java.util.regex.Matcher;

// parse cli
def cli = new CliBuilder(
   usage: '-p properties -t template -o output',
   header: '\nAvailable options:\n',
   footer: '\nInformation provided via above options is used to update users and passwords for dnc environment file.\n')

cli.with
{
   p(longOpt: 'properties', 'Property File', args: 1, required: true)
   t(longOpt: 'template', 'Appconfig Template', args: 1, required: true)
   o(longOpt: 'output', 'Output Filename', args: 1, required: true)
}
def opt = cli.parse(args)
if (!opt) return

def properties = opt.p
def template = opt.t
def output = opt.o

// read properties
Properties props = new Properties()
File propsFile = new File(properties)
propsFile.withInputStream {
    props.load(it)
}

File templateFile = new File(template)
String envFile = templateFile.text
envFile = envFile.replaceAll("Refdatadbx12!", Matcher.quoteReplacement(props['refdata-db-password-admin']))
envFile = envFile.replaceAll("Refdatadbx12!", Matcher.quoteReplacement(props['refdata-db-password']))
envFile = envFile.replaceAll("Sdsdbx12!", Matcher.quoteReplacement(props['sds-db-password-admin']))
envFile = envFile.replaceAll("Sdsdbx12!", Matcher.quoteReplacement(props['sds-db-password']))
envFile = envFile.replaceAll("Mmdbx12!", Matcher.quoteReplacement(props['mm-db-password-admin']))
envFile = envFile.replaceAll("Mmdbx12!", Matcher.quoteReplacement(props['mm-db-password']))
envFile = envFile.replaceAll("Resdbx12!", Matcher.quoteReplacement(props['res-db-password-admin']))
envFile = envFile.replaceAll("Resdbx12!", Matcher.quoteReplacement(props['res-db-password']))
envFile = envFile.replaceAll("Webdbx12!", Matcher.quoteReplacement(props['web-server-db-password-admin']))
envFile = envFile.replaceAll("Webdbx12!", Matcher.quoteReplacement(props['web-server-db-password']))
envFile = envFile.replaceAll("Esdbx12!", Matcher.quoteReplacement(props['es-db-password-admin']))
envFile = envFile.replaceAll("Esdbx12!", Matcher.quoteReplacement(props['es-db-password']))
envFile = envFile.replaceAll("Scsdbx12!", Matcher.quoteReplacement(props['scs-db-password-admin']))
envFile = envFile.replaceAll("Scsdbx12!", Matcher.quoteReplacement(props['scs-db-password']))

envFile = envFile.replaceAll("refdatadba", Matcher.quoteReplacement(props['refdata-db-user-admin']))
envFile = envFile.replaceAll("refdatadbu", Matcher.quoteReplacement(props['refdata-db-user']))
envFile = envFile.replaceAll("sdsdba", Matcher.quoteReplacement(props['sds-db-user-admin']))
envFile = envFile.replaceAll("sdsdbu", Matcher.quoteReplacement(props['sds-db-user']))
envFile = envFile.replaceAll("mmdba", Matcher.quoteReplacement(props['mm-db-user-admin']))
envFile = envFile.replaceAll("mmdbu", Matcher.quoteReplacement(props['mm-db-user']))
envFile = envFile.replaceAll("resdba", Matcher.quoteReplacement(props['res-db-user-admin']))
envFile = envFile.replaceAll("resdbu", Matcher.quoteReplacement(props['res-db-user']))
envFile = envFile.replaceAll("WEBDBA", Matcher.quoteReplacement(props['web-server-db-user-admin']))
envFile = envFile.replaceAll("WEBDBU", Matcher.quoteReplacement(props['web-server-db-user']))
envFile = envFile.replaceAll("ESDBA", Matcher.quoteReplacement(props['es-db-user-admin']))
envFile = envFile.replaceAll("ESDBU", Matcher.quoteReplacement(props['es-db-user']))
envFile = envFile.replaceAll("scsdba", Matcher.quoteReplacement(props['scs-db-user-admin']))
envFile = envFile.replaceAll("scsdbu", Matcher.quoteReplacement(props['scs-db-user']))

envFile = envFile.replaceAll("refdatadba", Matcher.quoteReplacement(props['refdata-db-user-admin']))
envFile = envFile.replaceAll("refdatadbu", Matcher.quoteReplacement(props['refdata-db-user']))
envFile = envFile.replaceAll("sdsdba", Matcher.quoteReplacement(props['sds-db-user-admin']))
envFile = envFile.replaceAll("sdsdbu", Matcher.quoteReplacement(props['sds-db-user']))
envFile = envFile.replaceAll("mmdba", Matcher.quoteReplacement(props['mm-db-user-admin']))
envFile = envFile.replaceAll("mmdbu", Matcher.quoteReplacement(props['mm-db-user']))
envFile = envFile.replaceAll("resdba", Matcher.quoteReplacement(props['res-db-user-admin']))
envFile = envFile.replaceAll("resdbu", Matcher.quoteReplacement(props['res-db-user']))
envFile = envFile.replaceAll("WEBDBA", Matcher.quoteReplacement(props['web-server-db-user-admin']))
envFile = envFile.replaceAll("WEBDBU", Matcher.quoteReplacement(props['web-server-db-user']))
envFile = envFile.replaceAll("ESDBA", Matcher.quoteReplacement(props['es-db-user-admin']))
envFile = envFile.replaceAll("ESDBU", Matcher.quoteReplacement(props['es-db-user']))
envFile = envFile.replaceAll("scsdba", Matcher.quoteReplacement(props['scs-db-user-admin']))
envFile = envFile.replaceAll("scsdbu", Matcher.quoteReplacement(props['scs-db-user']))

def environmentFile = new File(output)
environmentFile.write(envFile)