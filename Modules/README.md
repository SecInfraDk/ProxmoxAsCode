# Modules

## Purpose

Provides Proxmox VE-specific reusable functions and modules.

## Example contents

Existing PS1 functions connect to PVE, query resources, clone or move VMs, reassign disks, wait for tasks, and upload configuration ISOs.

## Scope

Platform-only functions remain here. Shared functions used across repositories belong in InfraModules.

## Dependencies

PVE API connectivity and permissions for nodes, storage, networking, and templates.

## Current integration status

This folder currently contains loose PS1 function files. New-PVEServer.ps1 also contains a VM start operation outside its function, controlled by the caller's Start variable. Review that placement before wrapping these files in an automatic module loader. New-PVEServer calls MAC2IP from InfraModules.
