# Deployment Guide

## Setting up Custom Domain with Caddy

This setup uses Caddy as a reverse proxy to serve your LangGraph application on a custom subdomain (`gs.demos.computelabs.ai`) with automatic SSL certificates.

### Prerequisites

1. **Domain Configuration**: Ensure that the subdomain points to your server's IP address:
   - Add an A record in your DNS settings: `gs.demos.computelabs.ai -> YOUR_SERVER_IP`
   - Wait for DNS propagation (can take up to 24 hours, usually much faster)

2. **Server Requirements**:
   - Ports 80 and 443 must be open and accessible from the internet
   - Docker and Docker Compose installed

### Deployment Steps

1. **Stop the current containers** (if running):
   ```bash
   sudo docker compose down
   ```

2. **Rebuild and start with Caddy**:
   ```bash
   sudo docker compose up --build -d
   ```

3. **Check the logs**:
   ```bash
   # Check all services
   sudo docker compose logs -f
   
   # Check Caddy specifically
   sudo docker compose logs caddy
   ```

4. **Access your application**:
   - Visit `https://gs.demos.computelabs.ai` (Caddy will automatically redirect to HTTPS)
   - The URL will redirect to `/app/` where your frontend is served
   - API documentation: `https://gs.demos.computelabs.ai/docs`

### What Caddy Does

- **Automatic SSL**: Obtains and renews Let's Encrypt certificates automatically
- **HTTP to HTTPS redirect**: All HTTP traffic is redirected to HTTPS
- **Reverse Proxy**: Routes requests to your LangGraph API container
- **Subdomain Routing**: Routes subdomain traffic directly to the backend
- **Security Headers**: Adds security headers for better protection
- **Compression**: Enables gzip compression for better performance

### URL Structure

- **Frontend**: `https://gs.demos.computelabs.ai/app/`
- **API Documentation**: `https://gs.demos.computelabs.ai/docs`
- **API Endpoints**: `https://gs.demos.computelabs.ai/runs/*`, `https://gs.demos.computelabs.ai/threads/*`, etc.

### Troubleshooting

1. **SSL Certificate Issues**:
   - Ensure your domain DNS is properly configured
   - Check Caddy logs: `sudo docker compose logs caddy`
   - Verify ports 80 and 443 are accessible

2. **503 Service Unavailable**:
   - Check if the langgraph-api container is running: `sudo docker compose ps`
   - Check API logs: `sudo docker compose logs langgraph-api`

3. **DNS Issues**:
   - Verify DNS propagation: `nslookup gs.demos.computelabs.ai`
   - Test with curl: `curl -I https://gs.demos.computelabs.ai`

4. **Frontend Assets Not Loading**:
   - Check that the Vite build completed successfully
   - Verify the base path is set correctly in `frontend/vite.config.ts` (should be `/app/` for subdomain)
   - Check browser console for 404 errors on assets

### Local Testing

For local testing, you can modify the Caddyfile to use `localhost`:

```caddyfile
localhost {
    handle /gs {
        redir /gs/app/
    }
    handle /gs/app/* {
        uri strip_prefix /gs
        reverse_proxy langgraph-api:8000
    }
}
```

Then access via `http://localhost` (no SSL for local testing).

### Production Considerations

1. **Environment Variables**: Store sensitive data in `.env` file
2. **Backup**: Regularly backup the `langgraph-data` volume
3. **Monitoring**: Consider adding monitoring for the containers
4. **Updates**: Regularly update Docker images for security

### Changing the Domain or Subdomain

To use a different domain or subdomain:

1. Update the subdomain in `Caddyfile`
2. Update the `base` path in `frontend/vite.config.ts` (keep as `/app/` for subdomains)
3. Update the `apiUrl` in `frontend/src/App.tsx`
4. Rebuild the frontend: `sudo docker compose up --build -d`
5. Configure DNS for the new subdomain
6. Restart Caddy: `sudo docker compose restart caddy`

### Notes on Subdomain Deployment

- The frontend is configured with `base: "/app/"` in Vite config
- Caddy routes the entire subdomain directly to the backend
- All asset URLs will be prefixed with `/app/`
- API calls from the frontend go directly to the subdomain (no path stripping needed) 