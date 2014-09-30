#!/bin/bash

mkdir data log
chcon -t svirt_sandbox_file_t -R data
chcon -t svirt_sandbox_file_t -R log 

docker build --rm --tag "ovirt/postgres" .

