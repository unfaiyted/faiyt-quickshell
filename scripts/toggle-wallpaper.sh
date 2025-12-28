#!/bin/bash
# Toggle wallpaper picker via Quickshell IPC

# Use the config path to identify the running instance
qs ipc -p ~/codebase/faiyt-qs call wallpaper toggle
