# Terraform Demo

## Summary

Contains a small Terraform project for spinning up a simple web page, served from an autoscaling group, behind a load balancer.

## History

Check out the commit history to see

* Step 1: A lone simple webserver
* Step 2: A load-balanced, auto scaled group
* Step 3: Use a remote backend (S3) for storing state
* Step 4: Create a database
* Step 5: Create modules

## TODO

* [ ] Move modules to separate repositories and reference them via GitHub instead of via the local files system