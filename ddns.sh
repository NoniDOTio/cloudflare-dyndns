#
# Config (required!)
#
CLOUDFLARE_API_KEY=""
CLOUDFLARE_ZONE_ID=""
CLOUDFLARE_ENTRY_ID=""
CLOUDFLARE_EMAIL="example@email.com"
CLOUDFLARE_NAME="example.com"

function main() {
    get_current_public_ip
    echo "${ip}"
    update_cloudflare "${ip}"
}

# Get public ip address
function get_current_public_ip() {
    if connected_to_internet; then
        if [ "${MODE}" == "curl" ]; then
            get_ip_via_curl
        elif [ "${MODE}" == "dig" ]; then
            get_ip_via_dig
        fi
    else
        if [[ $i -lt 10 ]]; then
            ((i++))
            echo "No internet connection :("
            sleep 60
            get_current_public_ip
        else
            return
        fi
    fi
}

function get_ip_via_curl() {
    for service in "${CURL_IP_LOOKUP_SERVICES[@]}"
    do
        ip=$(curl -s ${service})
        echo "${service} reports ${ip}"
        if ip_is_valid "${ip}"; then
            break
        fi
        sleep 1
    done
}

function get_ip_via_dig() {
    # TODO implement this
    ip=""
}

# Check if the computer is connected to the world wide web
function connected_to_internet() {
    for connection_check_ip in "${CONNECTION_CHECK_IPS[@]}"
    do
        nc -z "${connection_check_ip}" 53 >/dev/null 2>&1
        connected=$?
        if [[ $connected -eq 0 ]]; then
            return 0
        fi
        sleep 1
    done

    return 1
}

# Check whether a string is a valid IP address
# $1    String to test
function ip_is_valid() {
    [[ "${1}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && return 0 || return 1
}

function update_cloudflare() {
    curl -X PUT "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${CLOUDFLARE_ENTRY_ID}" \
        -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
        -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
        -H "Content-Type: application/json" \
        --data '{"type":"A","name":"'"${CLOUDFLARE_NAME}"'","content":"'"${1}"'","ttl":1,"proxied":false}'
}

#
# The following fields are optional, don't touch them unless you know what you're doing
#
MODE="curl"
CURL_IP_LOOKUP_SERVICES=(
    "ifconfig.me"
    "http://whatismyip.akamai.com/"
    "https://ipecho.net/plain"
    "http://icanhazip.com/"
    "https://api.ipify.org/?format=txt"
)
RESOLVERS=(
    "resolver1.opendns.com"
)

# IPs for connection check
# 1.1.1.1           Cloudflare DNS
# 8.8.8.8           Google DNS
# 208.67.222.222    OpenDNS
CONNECTION_CHECK_IPS=(
    "1.1.1.1"
    "8.8.8.8"
    "208.67.222.222"
)

# Initialize Global Variables
ip=""
i=""

main "$@"
