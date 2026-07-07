#!/bin/sh

xcodebuild -project Freecell.xcodeproj -scheme Freecell clean build | xcpretty -r json-compilation-database --output compile_commands.json
