#!/bin/bash

echo "Hello, World, V2" > index.html
nohup busybox httpd -f -p ${server_port} &