#!/bin/bash

USER_EMAIL=$(git config user.email)

if echo "$USER_EMAIL" | grep -q "manabu@tomarika.com"; then
    exit 0
else
    echo "--------------------------------------------------"
    echo "エラー: コミットがブロックされました。"
    echo ""
    echo "現在の設定値: $USER_EMAIL"
    echo "--------------------------------------------------"
    exit 1
fi
