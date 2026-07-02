#!/bin/bash
# Open a floating ghostty window running an app
# Usage: floating-run.sh <width> <height> <app>
#        floating-run.sh <app>  (defaults to 800x450)

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <width> <height> <app>"
    echo "   or: $0 <app>"
    exit 1
elif [[ $# -eq 3 ]]; then
    WIDTH="$1"; HEIGHT="$2"; APP="$3"
elif [[ $# -eq 1 ]]; then
    WIDTH="800"; HEIGHT="450"; APP="$1"
else
    echo "Error: expected 1 or 3 arguments"
    exit 1
fi

hyprctl dispatch exec "[float; size $WIDTH $HEIGHT; center] ghostty -e $APP"
