#!/bin/bash

if [ -z "$1" ]; then
	echo "Usage: heic-convert <path>"
	exit 1
fi

find "$1" -name "*.heic" -o -name "*.HEIC" | while read f; do
	heif-convert "$f" "${f%.*}.jpg" && rm "$f"
done
