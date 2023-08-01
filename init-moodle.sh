#!/bin/bash
mkdir -p moodle
mkdir -p moodledata
cp src/phpinfo.php ./moodle/
rm -rf src
ln -s moodle src
