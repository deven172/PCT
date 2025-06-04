#!/bin/bash
echo "setting up groovy installation"
jh=""
if [[ -n "${JAVA_HOME}" ]]; then
	echo "Using JAVA_HOME $JAVA_HOME"
	jh=$JAVA_HOME
else
	echo "JAVA_HOME not set, trying to get from java"
	if [[ -n `which java` ]]; then
		jh=$(dirname $(dirname $(readlink -f $(which java))))
		echo "Using JAVA_HOME $jh"
	else
		echo "no JAVA installed, please install at least java 8 and rerun script (17 recommended)"
		exit 1
	fi
fi
pushd /opt
curl --fail-with-body --insecure https://graurepo01.reval.com/artifactory/generic-local/com.reval/devtools/apache-groovy-binary-4.0.18.tar.gz -o /opt/groovy-4.0.18.tar.gz
tar -xvzf groovy-4.0.18.tar.gz
rm -f groovy-4.0.18.tar.gz
popd
pushd /etc/profile.d
cat << EOF > groovy.sh
export PATH=/opt/groovy-4.0.18/bin/:\$PATH
export JAVA_HOME=$jh
EOF
popd
source /etc/profile.d/groovy.sh
echo "done, please refresh shell"