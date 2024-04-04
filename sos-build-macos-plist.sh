#!/bin/bash

if [ "`whereis plistconvert`" = "" ] ; then
	sudo curl -sL https://phimage.github.io/plistconvert/install.sh | bash
fi

jq ".policies|.EnterprisePoliciesEnabled=true" < ./Files/distribution/policies.json > /tmp/policies.json
plistconvert -o Files/distribution/org.mozilla.firefox.plist --convert plist /tmp/policies.json
