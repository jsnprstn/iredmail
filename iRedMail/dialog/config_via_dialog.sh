#!/usr/bin/env bash

# Author:   Zhang Huangbin (michaelbibby <at> gmail.com)

#---------------------------------------------------------------------
# This file is part of iRedMail, which is an open source mail server
# solution for Red Hat(R) Enterprise Linux, CentOS, Debian and Ubuntu.
#
# iRedMail is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# iRedMail is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with iRedMail.  If not, see <http://www.gnu.org/licenses/>.
#---------------------------------------------------------------------

# Note: config file will be sourced in 'conf/functions', check_env().

. ${CONF_DIR}/global
. ${CONF_DIR}/functions
. ${CONF_DIR}/core
. ${CONF_DIR}/openldap

trap "exit 255" 2

# Initialize config file.
echo '' > ${CONFIG_FILE}

if [ X"${DISTRO}" == X"FREEBSD" ]; then
    DIALOG='dialog'
    PASSWORDBOX='--inputbox'
else
    DIALOG="dialog --colors --no-collapse --insecure \
            --ok-label Next --no-cancel \
            --backtitle ${PROG_NAME}:_Open_Source_Mail_Server_Solution"
    PASSWORDBOX='--passwordbox'
fi

# Welcome message.
${DIALOG} \
    --title "Welcome and thanks for use" \
    --yesno "\
Thanks for your use of ${PROG_NAME}.
Bug report, feedback, suggestion are always welcome.

* Contact author via mail: zhb@iredmail.org
* Community: http://www.iredmail.org/forum/
* Admin FAQ: http://www.iredmail.org/faq.html

NOTE:

    Ctrl-C will abort this wizard.
" 20 76

# Exit when user choose 'exit'.
[ X"$?" != X"0" ] && ECHO_INFO "Exit." && exit 0

# VMAIL_USER_HOME_DIR
VMAIL_USER_HOME_DIR="/var/vmail"
${DIALOG} \
    --title "Default mail storage path" \
    --inputbox "\
Please specify a directory for mail storage.
Default is: ${VMAIL_USER_HOME_DIR}

EXAMPLE:

    * ${VMAIL_USER_HOME_DIR}

NOTE:

    * It may take large disk space.
" 20 76 "${VMAIL_USER_HOME_DIR}" 2>/tmp/vmail_user_home_dir

VMAIL_USER_HOME_DIR="$(cat /tmp/vmail_user_home_dir)"
export VMAIL_USER_HOME_DIR="${VMAIL_USER_HOME_DIR}" && echo "export VMAIL_USER_HOME_DIR='${VMAIL_USER_HOME_DIR}'" >> ${CONFIG_FILE}
export STORAGE_BASE_DIR="${VMAIL_USER_HOME_DIR}" && echo "export STORAGE_BASE_DIR='${VMAIL_USER_HOME_DIR}'" >> ${CONFIG_FILE}
export SIEVE_DIR="${VMAIL_USER_HOME_DIR}/sieve" && echo "export SIEVE_DIR='${SIEVE_DIR}'" >>${CONFIG_FILE}
rm -f /tmp/vmail_user_home_dir

# --------------------------------------------------
# --------------------- Backend --------------------
# --------------------------------------------------
${DIALOG} \
    --title "Choose your preferred backend" \
    --radiolist "\
We provide two backends and the homologous webmail programs:

    +----------+---------------+---------------------------+
    | Backend  | Web Mail      | Web-based management tool |
    +----------+---------------+---------------------------+
    | OpenLDAP |               | iRedAdmin, phpLDAPadmin   |
    +----------+   Roundcube   +---------------------------+
    | MySQL    |               | iRedAdmin, phpMyAdmin     |
    +----------+---------------+---------------------------+

TIP:
    * Use 'Space' key to select item.

" 20 76 2 \
    "OpenLDAP" "An open source implementation of LDAP protocol. " "on" \
    "MySQL" "The world's most popular open source database." "off" \
    2>/tmp/backend

BACKEND="$(cat /tmp/backend)"
echo "export BACKEND='${BACKEND}'" >> ${CONFIG_FILE}
rm -f /tmp/backend

if [ X"${BACKEND}" == X"OpenLDAP" ]; then
    . ${DIALOG_DIR}/ldap_config.sh

    # For iRedAPD: Postfix Policy Daemon.
    export USE_IREDAPD='YES'
    echo "export USE_IREDAPD='YES'" >> ${CONFIG_FILE}
else
    :
fi

# MySQL server is required as backend or used to store policyd/roundcube data.
. ${DIALOG_DIR}/mysql_config.sh

#
# Virtual domain configuration.
#
. ${DIALOG_DIR}/virtual_domain_config.sh

#
# For optional components.
#
. ${DIALOG_DIR}/optional_components.sh

# Append EOF tag in config file.
echo "#EOF" >> ${CONFIG_FILE}

#
# Ending message.
#
cat <<EOF
Configuration completed.

*************************************************************************
***************************** WARNING ***********************************
*************************************************************************
*                                                                       *
* Please do remember to *MOVE* configuration file after installation    *
* completed successfully.                                               *
*                                                                       *
*   * ${CONFIG_FILE}
*                                                                       *
*************************************************************************
EOF

ECHO_INFO -n "Continue? [Y|n]"
read ANSWER

case ${ANSWER} in
    N|n)
        ECHO_INFO "Canceled, Exit."
        exit 255
        ;;
    Y|y|*)
        :
        ;;
esac
