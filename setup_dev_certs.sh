#!/bin/bash

import_cert(){
    service_name=$1
    if docker ps | grep -q $service_name; then # If service is running
        if [ "$(docker inspect --format='{{.State.Health.Status}}' $service_name)" = "healthy" ]; then # If service is healthy
            echo -e "\nImport dev cert to $service_name..."
            docker cp --quiet ./spot/itsconfig/keys/uddr_server.cer $service_name:/itsconfig/keys/uddr_server.cer
            docker exec $service_name bash -c "
            if /app/spot/java/bin/keytool -list -cacerts -alias itgdev -storepass changeit > /dev/null 2>&1; then
                /app/spot/java/bin/keytool -delete -alias itgdev -cacerts -storepass changeit
            fi
            /app/spot/java/bin/keytool -import -trustcacerts -cacerts -storepass changeit -noprompt -alias itgdev -file /itsconfig/keys/uddr_server.cer
            "
        fi
    fi
}

# Import itg-dev ssl cert (*.eng.wallstreetsystems.com) to service containers
import_cert "dnc-adapter-server"
import_cert "sanctions-screening-server"