# AUTO WITHDRAW AND DELEGATE SCRIPT.
Install script for auto-withdraw-delegate rewards to your Validator every 60 minutes.  
### Features:  
- You can specify a custom RPC port
- Custom FEES
- Custom Sleep Time in minutes
- Send message about delegation to Telegram
- It is enough to enter in the variables only the password, binary and key name in the start command
- No need to edit config

Specify environments in this line `./start.sh -b BINARY -k KEY_NAME -s SLEEP_TIME -p RPC_PORT -d DISCORD_HOOK`  
Example `./start.sh -b desmos -k ducca -s 60m -p 36657 -d https://discord.com/api/webhooks/938451322930352219/VhBFby9cGQ_sg64vztDN9_czZ1MWRCXo2ayV20M2SgTxDjLARKGHxwDgCwGhI1h8ILpk`  
`-s 60m` - value in seconds(s), minutes(m), hours(h)  
### You can use like all variables, some or set only `-b BINARY` and `-k KEY_NAME`.

Start new `TMUX` session:
```
tmux new -s delegate
```
And start this script:
```
wget https://raw.githubusercontent.com/stakefrites/scripts/main/node-tools/auto_with_delegate.sh \
&& chmod +x auto_with_delegate.sh \
&& ./auto_with_delegate.sh -b BINARY -k KEY_NAME -s SLEEP_TIME -p RPC_PORT -d DISCORD_HOOK
```