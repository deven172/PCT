#!/bin/bash

applyscenario(){
	local scriptname=$1
	while true; do
		read -p "Please input comma separated service names e.g hub, spot etc.: " choice
		if [ "$choice" = "" ]; then
			echo "Invalid input!"
		else
			echo "$choice" | tr ',' '\n' > "dev.scenario"
			"./$scriptname" "dev.scenario"
			break
		fi
	done
}
updateDB(){
	local scriptname=$1
	while true; do
		read -p "Please input service name e.g hub, spot etc.: " choice
		if [ "$choice" = "" ]; then
			echo "Invalid input!"
		else
			"./$scriptname" $choice
			break
		fi
	done
}
execute() {
	local action=$1
	local scriptname=$2
	local secondscriptname=$3
	while true; do
		read -p "Do you want to $action? (y/n - 'n' default option): " choice
		case $choice in
			y|Y)
				if [ "$action" = "applyScenario" ]; then
					applyscenario $scriptname
				else
					if [ "$scriptname" = "database_update.sh" ]; then
						updateDB $scriptname
					else
						if [ "$scriptname" = "setup_fetch_files.sh" ]; then
							git archive --format=tar --remote git@gitgraz.reval.com:reval-devops/itg-deployment.git master:shared/compose setup_fetch_files.sh |tar xf -
						fi
						if [ "$scriptname" = "config_generate.sh" ]; then
							while true; do
								echo -e "\nAs part of default configuration, a local sqlserver container will be set up and configured."
								echo -e "If you would like to connect to an external database, please configure the connection properties at this point by updating db-server in itg-properties file.\n"
								read -sp $"Press enter to continue once done, or to proceed with default configuration:"$'\n'
								break
							done
						fi
						"./$scriptname"				
					fi
					echo "$scriptname Done"	
					if [[ "$scriptname" = "setup_groovy.sh" || "$scriptname" = "database_update.sh" ]]; then
						while true; do
							read -sp $"Press enter to continue once $secondscriptname on windows box is executed(refer README):"$'\n'
							break
						done
					fi
				fi
				break
				;;
			n|N|"") break;;
			*) echo "Invalid choice!";;
		esac
	done
	echo -e '...\n...'
}

# Main script execution
HORIZONTALLINE="============================================================"
echo -e "$HORIZONTALLINE"
echo "Welcome to the setup wizard!"
echo -e "$HORIZONTALLINE"

execute 'setup environment' 'setup_groovy.sh' 'setup_ebicsui_odbc.ps1'
execute 'fetch files from git' 'setup_fetch_files.sh'
execute 'generate configs' 'config_generate.sh'
execute 'execute database initialization' 'database_init.sh'
execute 'restore database from backup' 'database_restore.sh'
execute 'update database' 'database_update.sh' 'database_update_ebicsui.ps1'
execute 'applyScenario' 'service_scenario_apply.sh'

echo -e "$HORIZONTALLINE"
echo "Setup wizard completed. Thank you!"
echo -e "$HORIZONTALLINE"