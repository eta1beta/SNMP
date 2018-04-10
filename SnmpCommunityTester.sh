#

COMMUNITY_FILE="snmp-communities.list"
IP_FILE="ip.list"
SNMP_FILE="snmp-config.xml"

echo '<!-- Autogenerate snmp-config.xml file -->' > $SNMP_FILE
echo "<?xml version=\"1.0\"?>" >> $SNMP_FILE
echo "<snmp-config retry=\"4\" timeout=\"800\" version=\"v2c\">" >> $SNMP_FILE

for ip in $(cat $IP_FILE); do
    FOUND=0
    echo "Trying $ip..." 
    for com in $(cat $COMMUNITY_FILE); do
        echo "  with community $com..."
        NAME=$(snmpwalk -c $com -v1 $ip sysName 2> /dev/nul | awk -F ":" ' { print $4 } ')
        if [ "$NAME" != "" ]; then
            echo "  Found $NAME with $com against $ip using SNMP v1"
            echo "  ... trying v2c"
            NAME=$(snmpwalk -v2c -c $com $ip sysName 2> /dev/nul | awk -F ":" ' { print $4 } ')
            if [ "$NAME" != "" ]; then
                echo "  Found $NAME with $com against $ip using SNMP v2c"
                echo "  ** Going to create the definition using v2c (DEFAULT)"

                echo "  <definition read-community=\"$com\">" >> $SNMP_FILE
                echo "    <specific>$ip</specific>" >> $SNMP_FILE
                echo "  </definition>" >> $SNMP_FILE
            else
                echo "  ** Going to create the definition using v1"
                echo "  <definition read-community=\"$com\" version=\"v1\">" >> $SNMP_FILE
                echo "    <specific>$ip</specific>" >> $SNMP_FILE
                echo "  </definition>" >> $SNMP_FILE
            fi
            FOUND=1
            break
        fi
    done
    if [ $FOUND = 0 ]; then
        echo "  No matching communities found for $ip"
    fi
done

echo "</snmp-config>" >> $SNMP_FILE

echo "Done searching for communities for ya! LATER!"