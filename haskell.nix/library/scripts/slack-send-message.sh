#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Serokell <https://serokell.io/>
#
# SPDX-License-Identifier: MPL-2.0

curl -XPOST https://slack.com/api/chat.postMessage \
     -H "Authorization: Bearer $SLACK_TOKEN" \
     -d "channel=$SLACK_CHANNEL" \
     -d "text=$MESSAGE"
