# First login and API keys (manual, in the browser)

Do this after `scripts/03-host-dns.sh` and before `scripts/05-api-setup.sh`.

1. Open `https://landscape.demo.internal` and accept the self-signed certificate warning.
2. Create the first **global administrator** (name, email, password). The account name is `standalone`.
3. Open your account settings and **generate API credentials**.
4. Copy the template and paste in your keys:

   ```bash
   # Create your private keys file from the template
   cp config/api.env.example config/api.env
   # Open it and paste the access key and secret key
   nano config/api.env
   ```

After `scripts/04-launch-clients.sh`, go to **Computers → Pending** and **accept** all three clients.
