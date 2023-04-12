#!/bin/bash

# Bot token
while [[ -z "$tk" ]]; do
    read -p 'Bot token: ' -n 1 tk
    if [[ $tk == $'\0' ]]; then
        echo "Invalid input. Token cannot be empty."
        unset tk
    fi
done

# Chat id
while [[ -z "$chatid" ]]; do
    read -p 'Chat id: ' -n 1 chatid
    if [[ $chatid == $'\0' ]]; then
        echo "Invalid input. Chat id cannot be empty."
        unset chatid
    elif [[ ! $chatid =~ ^\-?[0-9]+$ ]]; then
        echo "${chatid} is not a number."
        unset chatid
    fi
done

# Caption
read -p 'Caption (for example, your domain, to identify the database file more easily): ' caption

# Cronjob
while true; do
    read -p 'Cronjob (minutes and hours) (e.g : 30 6 or 0 12) : ' minute hour
    if [[ $minute == 0 ]] && [[ $hour == 0 ]]; then
        cron_time="* * * * *"
        break
    elif [[ $minute == 0 ]] && [[ $hour =~ ^[0-9]+$ ]] && [[ $hour -lt 24 ]]; then
        cron_time="0 */${hour} * * *"
        break
    elif [[ $hour == 0 ]] && [[ $minute =~ ^[0-9]+$ ]] && [[ $minute -lt 60 ]]; then
        cron_time="*/${minute} * * * *"
        break
    elif [[ $minute =~ ^[0-9]+$ ]] && [[ $hour =~ ^[0-9]+$ ]] && [[ $hour -lt 24 ]] && [[ $minute -lt 60 ]]; then
        cron_time="*/${minute} */${hour} * * *"
        break
    else
        echo "Invalid input, please enter a valid cronjob format (minutes and hours, e.g: 0 6 or 30 12)"
    fi
done


# x-ui or marzban or hiddify
while [[ -z "$xmh" ]]; do
    read -p 'x-ui or marzban or hiddify? [x/m/h] : ' -n 1 xmh
    if [[ $xmh == $'\0' ]]; then
        echo "Invalid input. Please choose x, m or h."
        unset xmh
    elif [[ ! $xmh =~ ^[xmh]$ ]]; then
        echo "${xmh} is not a valid option. Please choose x, m or h."
        unset xmh
    fi
done


if [[ "$xmh" == "m" ]]; then
ZIP="zip -r /root/ac-backup.zip /root/marzban/* /var/lib/marzban/*"
ACLover="marzban backup"
elif [[ "$xmh" == "x" ]]; then
ZIP="zip /root/ac-backup.zip /etc/x-ui/x-ui.db /usr/local/x-ui/bin/config.json"
ACLover="x-ui backup"
else
elif [[ "$xmh" == "h" ]]; then
ZIP=$(cat <<EOF
cd /opt/hiddify-config/hiddify-panel/
python3 -m hiddifypanel backup
cd /opt/hiddify-config/hiddify-panel/backup
latest_file=\$(ls -t *.json | head -n1)
zip /root/ac-backup.zip /opt/hiddify-config/hiddify-panel/backup/\${latest_file}
EOF
)
ACLover="hiddify backup"
else
echo "Please choose m or x or h only !"
exit 1
fi

export IP=$(hostname -I)
caption="${caption}\n\n${ACLover}\n<code>${IP}</code>"

sudo apt install zip -y

cat >/root/ac-backup.sh <<EOL
$ZIP
curl -F chat_id="${chatid}" -F caption=\$'${caption}' -F parse_mode="HTML" -F document=@"/root/ac-backup.zip" https://api.telegram.org/bot${tk}/sendDocument
EOL

{ crontab -l -u root; echo "${cron_time} /bin/bash /root/ac-backup.sh >/dev/null 2>&1"; } | crontab -u root -
bash /root/ac-backup.sh
echo -e "\nDone\n"