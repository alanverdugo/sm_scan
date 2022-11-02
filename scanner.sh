#!/bin/sh
##############################################################################
#
# Description:
#   A simple shell script that retrieves a secret payload from
#   IBM Secrets Manager's API, without requiring the user to know the secret's
#   ID.
#   The user supplies the secret name, secret type, service URL and API key.
#
# Dependencies:
#   curl
#   jq
#   ncurses
#
# Author:
#   Alan Verdugo (alan.verdugo.munoz1@ibm.com)
#
# Return codes:
#   0 - Completed successfully.
#   1 - Any of the required arguments was not provided.
#   2 - Failure authenticating or getting the IAM token.
#   3 - The requested secret or secrets were not found.
#
##############################################################################

bold=$(tput bold)
normal=$(tput sgr0)

get_secret_payload() {
    # Get and print secret payload to stdout.
    # Argument $1: UUID for the requested secret.
    secret_payload_output="$(curl --silent -X GET \
        "$service_url/api/v1/secrets/$secret_type/$1" \
        -H "Authorization: Bearer $IAM_token" \
        -H "Accept: application/json")"

    fully_qualified_secret_name="$(printf "%s" "$secret_payload_output" | \
                                jq --raw-output '.resources[].name')"
    secret_payload="$(printf "%s" "$secret_payload_output" | \
                   jq --raw-output '.resources[].secret_data.payload')"

    # Print result(s).
    printf "%sSecret name:%s\n%s\n" "${bold}" "${normal}" "$fully_qualified_secret_name"
    printf "%sSecret payload:%s\n%s\n" "${bold}" "${normal}" "$secret_payload"
}

# Verify that the required values where indeed provided by the user.
if [ -z "$api_key" ]; then
    printf "%sERROR:%s api_key value is required.\n" "${bold}" "${normal}"
    exit 1
fi

if [ -z "$secret_name" ]; then
    printf "%sERROR:%s secret_name value is required.\n" "${bold}" "${normal}"
    exit 1
fi

if [ -z "$service_url" ]; then
    printf "%sERROR:%s service_url value is required.\n" "${bold}" "${normal}"
    exit 1
fi

if [ -z "$secret_type" ]; then
    printf "%sERROR:%s secret_type value is required.\n" "${bold}" "${normal}"
    exit 1
fi

# Get IAM token
IAM_token_output="$(curl --silent -X POST \
  "https://iam.cloud.ibm.com/identity/token" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --header "Accept: application/json" \
  --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" \
  --data-urlencode "apikey=$api_key")"
IAM_token=$(printf "%s" "$IAM_token_output" | jq --raw-output '.access_token')

if [ "$IAM_token" = "null" ]; then
    printf "%sERROR%s authenticating to IAM.\n" "${bold}" "${normal}"
    printf "%s" "$IAM_token_output" | jq
    exit 2
fi

# Get ID of the secret
secret_ID_payload="$(curl --silent -X GET \
  "$service_url/api/v1/secrets/$secret_type?search=$secret_name" \
  -H "Authorization: Bearer $IAM_token" \
  -H "Accept: application/json")"

return_code=$?

if [ $return_code -ne 0 ]; then
    printf "%sERROR%s connecting to %s\n" "${bold}" "${normal}" "$service_url"
    exit $return_code
fi

# Check if the secret was found.
collection_total=$(printf "%s" "$secret_ID_payload" | \
                 jq --raw-output '.metadata.collection_total')

if test "$collection_total" = 0; then
    printf "%sWARNING:%s requested secret not found.\n" "${bold}" "${normal}"
    printf "%s" "$secret_ID_payload" | jq
    exit 3
else
    # Iterate over the secrets that were found.
    for id_index in $(seq 0 $((collection_total-1))); do
        collected_id=$(printf "%s" "$secret_ID_payload" | \
                     jq --raw-output ".resources[$id_index].id")
        # Call the extract secret payload function.
        get_secret_payload "$collected_id"
    done
fi
