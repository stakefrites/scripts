Start this script as a user with go acesss:
```
wget  https://raw.githubusercontent.com/stakefrites/scripts/main/node-setup/template/cosmovisor/cosmovisor.sh \
&& chmod +x cosmovisor.sh \
&& ./cosmovisor.sh
```

Start this script as root to create the service file:
```
wget  https://raw.githubusercontent.com/stakefrites/scripts/main/node-setup/template/cosmovisor/cosmo-service.sh \
&& chmod +x cosmo-service.sh \
&& ./cosmo-service.sh
```