#!/bin/sh

php_rc='/opt/php52m/custom/php52m.ini'
php_scan='/opt/php52m/etc/php.d'
php_prog='/opt/php52m/usr/bin/php-ls'

#export PHPRC=$php_rc
export PHP_INI_SCAN_DIR=$php_scan

exec $php_prog -c $php_rc $*