# Scripts

## Purpose

Provides runnable Proxmox VE entry scripts.

## Example contents

Existing commands create and copy templates, create or remove VMs, balance workloads, and launch the tools UI.

## Scope

Reusable platform functions belong in ../Modules. Guest role installation uses InfraAsCode.

## Dependencies

PVE API connectivity and permissions for nodes, storage, networking, and templates.

## Current integration status

The existing entry scripts still import from a Functions directory and use deployment-specific paths such as C:\Scripts and the local deployment web service. Adapt those callers to the new Modules layout before using this copy for deployment. New-PVEVMTemplate also calls New-Unattend from InfraModules.
