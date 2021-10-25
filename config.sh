# customize the values below
export HTTPPORT=8080
export CLUSTER=mycluster
export GRAFANA_PASS="operator"

# SLACKWEBHOOK this is a URL like this: https://hooks.slack.com/services/DFE$$RFSFSZ/FSFRGRGRRQ/afsdfsjisjfijgsjdsfjfooj
# create one via https://api.slack.com/apps  ( create new app and generate a webhook URL)
export SLACKWEBHOOK=$(cat ../.slack/SLACKWEBHOOK.url)

# path to AMTOOL if available. Extract from https://github.com/prometheus/alertmanager/releases
export AMTOOL=~/bin/amtool


# usually there is no need to do something below this line
ENVSUBSTVAR='$HTTPPORT $CLUSTER $APP $GRAFANA_PASS $SLACKWEBHOOK $AMTOOL $AMTOOLCONFIG $VERSION'
export AMVALUES=extra-am-values.yaml.template # use this to ./prom.sh  with pre-configured alertmanager routes
#export AMVALUES=am-values.yaml.template      # use this to ./prom.sh  w/o pre-configured alertmanager routes
[ -f package.json ] && export APP=`cat package.json | grep '^  \"name\":' | cut -d ' ' -f 4 | tr -d '",'`
[ -f package.json ] && export VERSION=`cat package.json | grep '^  \"version\":' | cut -d ' ' -f 4 | tr -d '",'`
AMTOOLCONFIG=~/.config/amtool/config.yml
[ -x ${AMTOOL} ] && mkdir -p `dirname ${AMTOOLCONFIG}` && cat amtool-config.yaml.template | envsubst > ${AMTOOLCONFIG}


