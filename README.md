## Cloudflare domain configs with Terraform

Configs for domains on Cloudflare (as a proxy) to achieve maximum security, automated with Terraform.

### Why I made this:

I always host my domains behind a Cloudflare proxy to block spam traffics. Since I apply the same settings every time, I want to minimize manual, repetitive works with some form of automation. Then, I discovered Terraform. Not only it saves time, but it also avoids potential human errors.

### Pre-requisite:

1. Purchase domain from a domain provider (e.g. Namecheap)
2. Install Terraform on your machine.

- On Windows, this would be the easiest way to install (on cmd):

```bash
winget install HashiCorp.Terraform
```

- Once finished, close and reopen your Terminal. Verify it works by typing:

```bash
terraform -version
```

### 1. Initially on Cloudflare:

1. Connect a domain
2. Complete the setup with default settings
3. Continue to Activation
4. Refer to `./terraform.tfvars.example` in this project and get all the credentials you need.

- `api_token`: Create one on _Account API Tokens_ (Ctrl+K and search for this).
  &rarr; **Template:** Edit zone DNS (Use template)

  &rarr; **Permissions:**

  - Zone / Zone WAF (Edit)
  - Zone / Zone Settings (Edit)
  - Zone / SSL and Certificates (Edit)

  &rarr; **Zone Resources:**

  - Include / Specific zone / `your domain`

- `zone_id`: It appears at the bottom-right corner of the domain's Overview page. (Ctrl+F and search for _Zone ID_)

### 2. Terraform (this repo):

1. Make sure `terraform.tfvars` is added to the root of this project and it follows the format of `./terraform.tfvars.example`.

2. Install Terraform-Cloudflare provider(s)

```bash
terraform init
```

3. Check for errors. Cloudflare is constantly updating its dashboard and features. Refer to the Cloudflare-Terraform docs at https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs

```bash
terraform plan
```

4. Apply configs to your domain on Cloudflare

```bash
terraform apply
```

### Summary - Configs applied

##### 1. SSL/TLS:

- Full + Strict (optional)
- Edge Certificate: Enable Always Use HTTPS

##### 2. DNS Settings:

- Enable DNSSEC
- Enable Multi-signer DNSSEC

##### 3. Security:

- WAF:

  1. <b>Block script kiddie</b>

  - Block incoming traffic which contains `.php` and `.json` in the URL

  2. <b>Rate limiting rules</b>

  - 25 Requests / 10 seconds (10sec is fixed on the Free plan)

### 3. Additional steps on Cloudflare

##### 1. Security (recommended):

- Page Shield: Enable

##### 2. Speed / Web analytics (optional):

- Enable Real User Monitoring to track page load time

##### 3. Email (optional):

- Enable **Email Routing** (auto add MX records)
- You may need to remove all conflicting `MX`, `TXT` records in the `DNS` settings if your domain comes with some default values.

- <b>Receiving at custom email</b>

  1. Add a destination address at `Destination addresses`
  2. Verify your email address at the email's inbox
  3. Create a custom address in the `Custom addresses` section in `Routing rules`
  4. Pick an alias (hello@...), Action should be `Send to an email`, and select your destination email address
  5. Send a test email to the custom email address you created

- <b>Sending as custom email</b>

  1. Go to `App passwords` in Google and create `custom@mail.com app password for gmail`, save the password
  2. In Gmail, See all Settings, Accounts and Import, `add another email address` below "**Send mail as**"
  3. Email address: your custom email, Treat as an alias: Check (Yes)
  4. SMTP Server: `smtp.gmail.com`, Port: `587` (default)
  5. Username: `the current gmail`
  6. Password: `the app password created`
  7. Test sending email from the custom email
  8. Optional: In Gmail, See all Settings, Filters and ..., whatever email sent to custom email will be labeled
