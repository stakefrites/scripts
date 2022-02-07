Start this script as the chain user (or any user that has access to GO):
```
wget  https://raw.githubusercontent.com/stakefrites/scripts/main/node-tools/monitoring/tenderduty/tenderduty.sh \
&& chmod +x tenderduty.sh \
&& ./tenderduty.sh
```

Then start this script as root:
```
wget  https://raw.githubusercontent.com/stakefrites/scripts/main/node-tools/monitoring/tenderduty/service-duty.sh \
&& chmod +x service-duty.sh \
&& ./service-duty.sh
```