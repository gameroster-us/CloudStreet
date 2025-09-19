#!/bin/bash
. /data/mount/env

/bin/bash $APP_ROOT/script/env_vars_setter.sh SMTP_PORT $2
/bin/bash $APP_ROOT/script/env_vars_setter.sh SMTP_HOST $1
/bin/bash $APP_ROOT/script/env_vars_setter.sh SMTP_USERNAME $3
/bin/bash $APP_ROOT/script/env_vars_setter.sh SMTP_PASSWORD $4 
/bin/bash $APP_ROOT/script/env_vars_setter.sh SMTP_SET $5
/bin/bash $APP_ROOT/script/env_vars_setter.sh SMTP_FROM_EMAIL $6
