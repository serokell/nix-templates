#!/usr/bin/env bash

curl -XPOST https://slack.com/api/chat.postMessage \
     -H "Authorization: Bearer $SLACK_TOKEN" \
     -d "channel=$SLACK_CHANNEL" \
     -d "text=$MESSAGE"
