#!/bin/bash

multipass stop nginx-cluster-balancer
multipass delete nginx-cluster-balancer
multipass purge