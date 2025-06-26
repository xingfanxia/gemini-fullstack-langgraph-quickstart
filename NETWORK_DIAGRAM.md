# Network Topology Diagram

## Docker Network Architecture

```
Internet → Cloudflare DNS → Server (35.193.136.64)
                                    ↓
                            [Caddy Reverse Proxy]
                                    ↓
    ┌─────────────────────────────────────────────────────┐
    │                  Network Routing                    │
    │                                                     │
    │  Same Network (default)    │  External Network      │
    │  ┌─────────────────────┐   │  (docker_default)      │
    │  │ LangGraph API:8000  │   │  ┌─────────────────┐   │
    │  │ Open WebUI:8080     │   │  │ Dify Web:3000   │   │
    │  └─────────────────────┘   │  │ Dify API:5001   │   │
    │                            │  └─────────────────┘   │
    └────────────────────────────┴────────────────────────┘
```

## URL Routing

- `demos.computelabs.ai` → Static HTML (Caddy)
- `gs.demos.computelabs.ai` → langgraph-api:8000
- `oui.demos.computelabs.ai` → open-webui:8080  
- `dify.demos.computelabs.ai` → docker-web-1:3000
- `api.dify.demos.computelabs.ai` → docker-api-1:5001

## Service Communication Matrix

| From Service | To Service | Network | Method |
|--------------|------------|---------|--------|
| Internet | Caddy | Host | Port mapping (80,443) |
| Caddy | LangGraph API | default | Container name |
| Caddy | Open WebUI | default | Container name |
| Caddy | Dify Web | docker_default | External link |
| Caddy | Dify API | docker_default | External link |

## Network Configuration

### LangGraph Stack Networks
```yaml
networks:
  default:
    driver: bridge
  docker_default:
    external: true
```

### Dify Stack Networks  
```yaml
networks:
  default:
    name: docker_default
```

## Key Architecture Benefits

1. **Service Isolation**: Each stack maintains independence
2. **Single Entry Point**: All traffic through Caddy
3. **Cross-Network Communication**: Services can communicate across stacks
4. **Automatic SSL**: Let's Encrypt for all domains
5. **Easy Scaling**: Add new services without disrupting existing ones 