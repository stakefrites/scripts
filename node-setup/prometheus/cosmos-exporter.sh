wget https://github.com/solarlabsteam/cosmos-exporter/releases/download/v0.2.2/cosmos-exporter_0.2.2_Linux_x86_64.tar.gz \ 
&& tar xvfz cosmos-exporter-0.2.2-Linux-x86_64.tar.gz \
&& sudo cp ./cosmos-exporter /usr/bin \
&& sudo nano /etc/systemd/system/cosmos-exporter.service


--denom ulum --denom-coefficient 1000000 --bech-prefix lum --log-level debug

--denom uakt --denom-coefficient 1000000 --bech-prefix akash --log-level debug