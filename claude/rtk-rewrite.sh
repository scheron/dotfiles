#!/bin/bash
for bin in \
  "$(command -v rtk 2>/dev/null)" \
  "$HOME/.local/bin/rtk" \
  /opt/homebrew/bin/rtk \
  /usr/local/bin/rtk
do
  [ -n "$bin" ] && [ -x "$bin" ] && exec "$bin" hook claude
done
exit 0
