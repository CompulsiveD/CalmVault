---
layout: default
title: Home
nav_order: 1
---

# CalmVault Deployment Lab

A hands-on guide to deploying a full-stack web application on Azure. This lab is designed for developers at the **100–200 level** — you should be comfortable with basic command-line usage and web development, but no prior Azure experience is required.

## What you'll build

**CalmVault** is a minimal, private web app for storing and organizing personal files and images. By the end of this lab, you'll have deployed it to the cloud using Azure's managed services.

## Lab Structure

| Activity | What you'll do | What you'll learn |
| --- | --- | --- |
| [Activity 1]({% link activity-1.md %}) | Deploy Azure resources and run the app locally | Bicep (infrastructure-as-code), Azure Storage, Cosmos DB |
| [Activity 2]({% link activity-2.md %}) | Build container images in the cloud | Docker concepts, Azure Container Registry, `az acr build` |
| [Activity 3]({% link activity-3.md %}) | Deploy containers to Azure Container Apps | Managed container hosting, auto-scaling, secrets management |
| [Activity 4]({% link activity-4.md %}) | Add monitoring and observability | Diagnostic settings, Log Analytics, KQL queries |
| [Activity 5]({% link activity-5.md %}) | AI auto-tagging with GPT-4o (optional) | Azure OpenAI, Event Grid, Container App Jobs |
| [Activity 6]({% link activity-6.md %}) | Clean up all Azure resources | Resource lifecycle management |

## Architecture

- **Frontend:** Vue 3 + TypeScript (Vite) — a single-page app for uploading and browsing files
- **Backend:** Node.js + Express + TypeScript — REST API that handles uploads and talks to Azure
- **File Storage:** Azure Blob Storage — stores the actual uploaded files
- **Metadata DB:** Azure Cosmos DB (serverless) — stores file metadata (name, tags, dates)

## Prerequisites

- [Node.js](https://nodejs.org/) 20+ — the JavaScript runtime for our backend and frontend build tools
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) — a command-line tool for managing Azure resources
- An active Azure subscription — [create a free account](https://azure.microsoft.com/free/) if you don't have one

**Before starting**, make sure you're logged into Azure:

**Bash / PowerShell:**

```bash
az login
```

This opens a browser window for authentication. Once logged in, verify your subscription:

```bash
az account show --query name -o tsv
```

---

👉 **Ready?** Start with [Activity 1 — Deploy Infrastructure & Run Locally]({% link activity-1.md %})
