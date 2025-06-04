#!/bin/bash

# Enable extended pattern matching
shopt -s extglob

# Define file paths
itg_properties="itg.properties"
itg_custom_properties=$1

# Check if itg.properties exists
if [ ! -f "$itg_properties" ]; then
    echo "Error: $itg_properties not found!"
    exit 1
fi

# Check if custom_properties_file is provided and exists
if [ -z "$itg_custom_properties" ] || [ ! -f "$itg_custom_properties" ]; then
    echo "Ignoring update of itg.properties due to unavailable custom properties."
    exit 1
fi

# Remove carriage return characters
sed -i 's/\r$//' "$itg_properties"

# Read custom properties into an array
mapfile -t properties < <(cat "$itg_custom_properties")

# Sort properties with default- and append-default- at the top
sorted_properties=($(printf "%s\n" "${properties[@]}" | grep "^default-"))
sorted_properties+=($(printf "%s\n" "${properties[@]}" | grep "^append-default-"))
sorted_properties+=($(printf "%s\n" "${properties[@]}" | grep -v "^default-" | grep -v "^append-default-"))

# Function to update properties
update_property() {
    local property=$1
    local value=$2
    local file=$3
    local suffix_found=false

    while IFS= read -r line; do      
        trimmed_key=${property#@(default-|append-default-)}
        if [[ $line == *-$trimmed_key=* ]]; then
            suffix_property=$(echo "$line" | cut -d'=' -f1)
            if [[ "$property" == "append-default-jvm-parameter"* ]]; then
                existing_value=$(grep "^$suffix_property=" "$file" | cut -d'=' -f2- | tr -d '\n')                 
                modified_value=$(echo "$existing_value $value" | sed 's:/:\\/:g')
                sed -i -e "s|^$suffix_property=.*|$suffix_property=$modified_value|" "$file"
            else
                sed -i "s/^$suffix_property=.*/$suffix_property=$value/" "$file"
            fi            
            suffix_found=true
        fi
    done < "$file"
    
    if [[ $suffix_found == true ]]; then
        return
    fi
    if [[ $property == *"jvm-parameter" ]]; then       
        property=${property#append-}
        if grep -q "^$property=" "$file"; then
            existing_value=$(grep "^$property=" "$file" | cut -d'=' -f2-)
            sed -i "s/^$property=.*/$property=$existing_value $value/" "$file"
        fi
        return
    fi
    if grep -q "^$property=" "$file"; then
        sed -i "s/^$property=.*/$property=$value/" "$file"
    fi
}

# Update itg.properties with sorted properties
for prop in "${sorted_properties[@]}"; do
    key=$(echo "$prop" | cut -d'=' -f1)
    value=$(echo "$prop" | cut -d'=' -f2)
    update_property "$key" "$value" "$itg_properties"
done

echo "Properties update in $itg_properties done!"
