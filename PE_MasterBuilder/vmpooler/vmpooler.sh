


function launch_in_vmpooler
{
    DIR=$1

    is_set "${DIR}" "launch_in_vmpooler requires the base DIR as the first param"

    test $(which floaty | wc -l) -ne 0
    is_ok $? "Floaty must be installed for this to work. gem install vmfloaty"

    log "Ensure you have the pooler private PEM set at this location : ${PEM_FILE}"

    # Get the master centos host from the pooler. Strip the FQDN
    fqdn=$(floaty get centos-7-x86_64 | awk '{ print $2 }') 
    is_ok $? "Failed to get a node list from floaty. Please check your vmpoooler token. Run [floaty list] and check for problems"

    hostname=$(echo $fqdn | cut -d. -f1)
    log "Aquired node [${hostname}]"

    # Construct the SSH command
    SSH_COMMAND="ssh -o LogLevel=quiet -i ${PEM_FILE} root@${fqdn}"
    SCP_COMMAND="scp -i ${PEM_FILE} "

    # Set the lifetime in the pooler until max
    ft=$(floaty modify ${hostname} --lifetime 24)
    is_ok $? "Failed to set the pooler lifetime for [${hostname}]"

    log "The Master ${hostname} is ready for install"

    # Attempt SSH comms
    node_arch=$(${SSH_COMMAND} uname)
    is_ok $? "Failed to ssh to ${fqdn}. Check your PEM file at [${PEM_FILE}]"

    # Ensure SSH response works
    test "$node_arch" == "Linux"
    is_ok $? "SSH comms failed to [$fqdn]. Unable to uname "

    log "Ready to install PE to the Master node"

    ${SCP_COMMAND} ${DIR}/PE/install_pe.sh root@${fqdn}:/root/install_pe.sh
    ${SSH_COMMAND} /root/install_pe.sh
    is_ok $? "Failed to install Puppet Enterprise on [$hostname]. Check the logs above"

    log "Complete: Puppet Enterprise is installed and configured on [${hostname}]"
}

