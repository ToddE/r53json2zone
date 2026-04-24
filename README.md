# r53json2zone

A bash script that converts AWS Route 53 JSON exports to standard BIND zone files, making it easy to migrate DNS records to other providers (e.g. Cloudflare).


## What it does

- Converts Route 53 DNS records (exported as JSON) into a standard BIND zone file format that other DNS providers can import
- Converts AWS-specific "Alias" records into standard CNAME records for compatibility
- Detects special AWS routing features (Weighted, Geo-based, Failover, Health Checks) that won't automatically transfer, and warns you about them
- Optionally generates a migration guide with Cloudflare-specific tips

## Requirements

- **bash** — the shell (included on Linux/macOS)
- **curl** — for downloading the script and checking for updates. The installer will automatically install it if you don't have it.
- **jq** — a JSON parsing tool. The installer will automatically install it if you don't have it.
- **AWS CLI** — needed to export your Route 53 records. You must have it installed and configured with AWS credentials that can access Route 53. See [AWS CLI setup docs](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

## Installation

### One-liner (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/ToddE/r53json2zone/main/install.sh | bash
```

This downloads and installs the script automatically. The installer will:
- Create `~/.local/bin` directory if needed
- Download the script and verify it's authentic
- Install any missing dependencies (like `jq` or `curl`)

If the installer says your PATH needs updating, add this line to your `.bashrc` or `.zshrc` file:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell:

```bash
source ~/.bashrc   # or source ~/.zshrc
```

### Manual

Download [r53json2zone](r53json2zone), make it executable, and place it somewhere on your `PATH`:

```bash
chmod +x r53json2zone
mv r53json2zone ~/.local/bin/
```

## Usage

### Step 1: Get your Route 53 Zone ID

In the AWS Console, go to Route 53 → Hosted zones. Copy the Zone ID for the domain you want to migrate.

### Step 2: Export your Route 53 records to JSON

Replace `YOUR_ZONE_ID` with the ID from Step 1:

```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID \
  > records.json
```

This creates a file called `records.json` with all your DNS records.

### Step 3: Convert to BIND format

```bash
r53json2zone records.json example.com.zone
```

Replace `example.com.zone` with whatever name you want for the output file. This will create a zone file you can import into your new DNS provider.

**What you get:**
- `example.com.zone` — the zone file to import (in the same directory as specified)
- `info-example.com.zone` — (if applicable) a guide with migration notes (same directory as the zone file)

### Updates

The script automatically checks for updates once per day (when you run it normally). If a newer version is available, you'll see a message:

```
⚠ Update available
Your version:   abc123456789... (2026-04-20)
Latest version: def456789012... (2026-04-24)
Run: curl -sSL https://raw.githubusercontent.com/ToddE/r53json2zone/main/install.sh | bash
```

To check for updates manually and update if needed:

```bash
r53json2zone --check-updates
```

This will show you the version info and ask if you want to update now. Just answer `y` to install the latest version, or `n` to skip.

The auto-check runs in the background with a 4-second timeout, so it won't slow down your DNS conversions. When it finds an update, it'll suggest running `r53json2zone --check-updates` to install.

## What to do next

After running the script, you'll have a zone file ready to import into your new DNS provider (Cloudflare, Porkbun, GoDaddy, etc.). Each provider has a different import process, but most have a "Zone File" or "Import" option in their settings.

If the script detects anything unusual in your records (like AWS-specific routing features), it will create an `info-example.com.zone` file with notes about what needs manual setup on your new provider.

## Important: CloudFront domains

If any of your Route 53 records point to a CloudFront distribution, you **must** verify that the domain name is listed in CloudFront's **Alternate Domain Names** setting. If not, you'll get HTTP 403 errors when accessing the site through the new DNS provider.

Check this regardless of which provider you migrate to.

## Migrating to Cloudflare

If you're migrating to Cloudflare, the script will generate a migration guide with Cloudflare-specific tips, including:

- How Cloudflare handles CNAME records at the zone root (via CNAME Flattening)
- How to recreate AWS routing features (Weighted, Geo-based, Failover) using Cloudflare Load Balancing
- How Cloudflare's proxy automatically handles both IPv4 and IPv6

## Supported platforms

**Tested:** Debian, Ubuntu

**Expected to work:**
- macOS (Homebrew)
- Windows (WSL with Ubuntu or Debian)
- RHEL/CentOS/Fedora
- Arch Linux
- Armbian, Linux Mint, Raspbian

The script includes auto-detection and dependency installation for these platforms. If you use a different distribution or encounter issues, please open an issue or pull request on [GitHub](https://github.com/ToddE/r53json2zone).

## License

MIT
