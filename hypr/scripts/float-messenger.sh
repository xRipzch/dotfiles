#!/usr/bin/env bash
# Launches the Messenger webapp. Floating, size and centering come from the
# "messenger" window rule in rules/windows.lua, which matches on the custom class below.

set -euo pipefail

readonly WM_CLASS="WebApp-Messenger4386"

XAPP_FORCE_GTKWINDOW_ICON="messenger-indicator" exec firefox \
	--class "$WM_CLASS" --name "$WM_CLASS" \
	--profile /home/ravn/.local/share/ice/firefox/Messenger4386 \
	--no-remote "https://www.messenger.com"
