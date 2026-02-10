# Setup Passwordless SSH to Proxmox

## Problem
Terraform's `null_resource` provisioners need to SSH into Proxmox but can't handle interactive password prompts properly.

## Solution: SSH Key Authentication

### From WSL:

```bash
# 1. Copy your SSH key to Proxmox
ssh-copy-id root@192.168.50.200

# You'll be prompted for the root password once
# After this, SSH will work without a password

# 2. Test passwordless SSH
ssh root@192.168.50.200 "echo 'Passwordless SSH works!'"

# 3. Now run Terraform
cd /mnt/c/Users/Mathew/homelab
terraform apply
```

## Alternative: Manual SSH Key Setup

If `ssh-copy-id` doesn't work, do it manually:

```bash
# 1. Get your public key
cat ~/.ssh/id_ed25519.pub

# 2. SSH into Proxmox (with password)
ssh root@192.168.50.200

# 3. On Proxmox, add your key
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit

# 4. Test passwordless access
ssh root@192.168.50.200 "echo 'Success!'"
```

## Verify It Works

```bash
# This should connect without asking for a password
ssh root@192.168.50.200 "pct list"
```

Once this is set up, Terraform will be able to run the SSH commands without any password prompts!