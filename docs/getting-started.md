# Getting Started with Portainer

Welcome! This guide will help you understand what Portainer is and how to use this project to set it up on your system.

## What is Portainer?

Portainer is a tool that makes it easy to manage Docker containers through a friendly web interface. Think of it as a control panel for your Docker applications - instead of remembering complex commands, you can click buttons and fill in forms to manage your containers.

## What This Project Does

This project provides ready-to-use configuration files that help you set up Portainer quickly and easily. It handles all the technical details so you can focus on using Portainer rather than configuring it.

## Who Is This For?

This guide is written for people who:
- Are new to Docker or Portainer
- Want to manage Docker containers without using command-line tools
- Prefer a visual interface over text commands
- Need to manage Docker on one or more computers

## What You'll Need

Before you start, make sure you have:
- **Docker installed** on your computer or server
- **Basic computer skills** - you should be comfortable using a terminal or command prompt
- **Administrator access** (sudo or root privileges) - needed to create folders and set permissions

## Understanding the Different Ways to Use Portainer

Portainer can be set up in different ways depending on your needs. This project supports three main approaches:

### 1. Single Computer Setup (Host Mode)
**Best for:** Managing Docker on just one computer

In this mode, Portainer runs on your computer with a web interface you can access directly. You'll use a web browser to manage containers on that same computer.

**When to choose this:**
- You only need to manage Docker on one machine
- You want a simple, straightforward setup
- You don't need to manage remote computers

### 2. Remote Agent Setup (Edge Agent Mode)
**Best for:** Managing multiple computers from one central location

In this mode, a small "agent" program runs on your computer and connects to a Portainer server running elsewhere. This lets you manage this computer from a central control panel.

**When to choose this:**
- You already have a Portainer server running somewhere else
- You want to manage this computer remotely
- You're part of a team managing multiple computers

### 3. Multi-Computer Cluster (Swarm Mode)
**Best for:** Advanced users managing many computers as a group

This mode is for experienced users who want to manage multiple computers as a single cluster. It's more complex but powerful for large setups.

**When to choose this:**
- You're managing many computers (10+)
- You need advanced features like load balancing
- You're comfortable with Docker Swarm

## Next Steps

Now that you understand the basics, choose your next step:

- **New to Portainer?** Start with [Installation Guide](installation.md) for a single computer setup
- **Already have a Portainer server?** Read [Deployment Modes](deployment-modes.md) to set up an agent
- **Want to understand the options?** Check [Deployment Modes](deployment-modes.md) for detailed comparisons

## Need Help?

If you get stuck or have questions:
- Check our [FAQ](faq.md) for common questions
- Look at [Troubleshooting](troubleshooting.md) for solutions to common problems
- Remember: start simple with the single computer setup before trying advanced modes
