# cf-ssh

SSH into your home computer from anywhere using your own web address, like `homebox.example.com`.

You don't need to open any ports on your router. Only email addresses you choose can connect.

Throughout this guide, `homebox.example.com` stands in for your machine's address. Replace it with yours.

---

## Step 1: Install the tools

There are two machines involved:

- **Your laptop**: the computer you'll SSH *from*. You also run the setup from here.
- **Your home computer**: the computer you'll SSH *into*.

| Tool | Laptop | Home computer |
|---|---|---|
| Terraform | ✅ | ❌ |
| cloudflared | ✅ | ✅ |

### Install Terraform (laptop only)

- **macOS:** `brew install terraform`
- **Ubuntu/Debian:** 

```sh
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Install cloudflared (laptop and home computer)

- **macOS:** `brew install cloudflared`
- **Ubuntu/Debian:**

```sh
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt-get update && sudo apt-get install cloudflared
```

## Step 2: Set up Cloudflare

This guide assumes you bought your domain through Cloudflare.

1. In the [Cloudflare dashboard](https://dash.cloudflare.com), open **Zero Trust**. Pick any team name, then choose the **Free** plan.
2. Create an API token. This lets the setup script make changes in your Cloudflare account.
   1. Go to **My Profile → API Tokens → Create Token**, and start from scratch.
   2. Add these two policies, with every permission set to **Edit**:

      | Policy type | Resource     | Permissions                                   |
      |-------------|--------------|-----------------------------------------------|
      | Account     | your account | Cloudflare Tunnel, Access: Apps and Policies  |
      | Zone        | your domain  | DNS                                           |

   3. Click **Create Token** and keep the page open. Cloudflare only shows the token once, and you'll need it in the next step.

## Step 3: Fill in your settings

On your **laptop**, in this folder:

Make your own copy of the settings file:

```sh
cp .env.example .env
```

Open `.env` and fill in each line after the `=`:

| Setting | What to put | Where to find it |
|---|---|---|
| `CLOUDFLARE_API_TOKEN` | The token from Step 2 | The token page you kept open. You kept it open right? |
| `TF_VAR_account_id` | Your Account ID | Dashboard → your domain → **Overview**, right-hand side |
| `TF_VAR_zone_id` | Your Zone ID | Same place, just above Account ID |
| `TF_VAR_domain` | Your domain, e.g. `example.com` | The domain you bought |
| `TF_VAR_machine_name` | A name for this computer, e.g. `homebox` | Your choice. You'll connect to `homebox.example.com` |
| `TF_VAR_allowed_emails` | Who may connect, e.g. `you@example.com` | Separate several emails with commas, no spaces |

`.env` holds your secrets and is never committed to git.

## Step 4: Create everything

On your **laptop**:

```sh
./run.sh
```

This shows what it's going to create, then asks you to confirm. Type `yes`.

## Step 5: Connect your home computer

On the **home computer**:

1. Turn on SSH.
   - **macOS:** System Settings → General → Sharing → **Remote Login**.
   - **Ubuntu:** run `sudo apt install openssh-server`.
2. Make sure cloudflared is installed (see Step 1).
3. On your **laptop**, print your tunnel token:
   ```sh
   ./run.sh output -raw tunnel_token
   ```
4. Back on the home computer, run this with that token:
   ```sh
   sudo cloudflared service install <tunnel-token>
   ```

In the dashboard, **Zero Trust → Networks → Tunnels** should now show your tunnel as **Healthy**.

## Step 6: SSH in

On your **laptop**, add this to `~/.ssh/config`:

```
Host homebox.example.com
  ProxyCommand cloudflared access ssh --hostname %h
```

Now connect:

```sh
ssh yourusername@homebox.example.com
```

The first time, a browser window opens. Enter your email, then type in the code Cloudflare emails you.

To stop typing your password each time, copy your SSH key across:

```sh
ssh-copy-id yourusername@homebox.example.com
```

---

## Something not working?

| Problem | Fix |
|---|---|
| `auth.forbidden` during Step 4 | Probably a permission issue. Edit the token and try again. |
| `websocket: bad handshake` | The tunnel isn't running. Check Step 5. |
| Browser says you're not authorized | Your email isn't in `TF_VAR_allowed_emails`. Add it and run `./run.sh` again. |
| `Connection refused` | SSH isn't turned on at home. Check Step 5.1. |

To remove everything: run `./run.sh destroy`, then `sudo cloudflared service uninstall` on the home computer.
