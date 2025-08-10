#!/bin/bash

USER_EMAIL=$(git config user.email)

if echo "$USER_EMAIL" | grep -q "manabu@tomarika.com"; then
    exit 0
else
    echo "🈲 ERROR: COMMIT BLOCKED -- Current email: $USER_EMAIL"
    exit 1
fi
