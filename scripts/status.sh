#!/bin/bash

# Makes sure we're running from the project directory.
cd "$PROJECT_PATH"

echo -n "Enabled targets: ${T_BOLD}"
echo -n "web "
if [ "x$BUILD_IOS" = "xYES" ]; then
    echo -n "ios "
fi
if [ "x$BUILD_ANDROID" = "xYES" ]; then
    echo -n "android "
fi
if [ "x$BUILD_BLACKBERRY" = "xYES" ]; then
    echo -n "backberry "
fi
echo -e "${T_RESET}"

# If the project was already build once, let's use previous parameters as defaults.
if test -e "$PROJECT_PATH/build/config"; then
    target="`cat "$PROJECT_PATH/build/config" | cut -d\  -f1`"
    conf="`cat "$PROJECT_PATH/build/config" | cut -d\  -f2`"

    echo -e "Current target:  ${T_BOLD}$target${T_RESET}"
    echo -e "Current config:  ${T_BOLD}$conf${T_RESET}"
fi
echo
