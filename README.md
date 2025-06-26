# Gemini Fullstack LangGraph Quickstart

This project demonstrates a fullstack application using a React frontend and a LangGraph-powered backend agent. The agent is designed to perform comprehensive research on a user's query by dynamically generating search terms, querying the web using Google Search, reflecting on the results to identify knowledge gaps, and iteratively refining its search until it can provide a well-supported answer with citations. This application serves as an example of building research-augmented conversational AI using LangGraph and Google's Gemini models.

<img src="./app.png" title="Gemini Fullstack LangGraph" alt="Gemini Fullstack LangGraph" width="90%">

## Features

- 💬 Fullstack application with a React frontend and LangGraph backend.
- 🧠 Powered by a LangGraph agent for advanced research and conversational AI.
- 🔍 Dynamic search query generation using Google Gemini models.
- 🌐 Integrated web research via Google Search API.
- 🤔 Reflective reasoning to identify knowledge gaps and refine searches.
- 📄 Generates answers with citations from gathered sources.
- 🔄 Hot-reloading for both frontend and backend during development.

## Project Structure

The project is divided into two main directories:

-   `frontend/`: Contains the React application built with Vite.
-   `backend/`: Contains the LangGraph/FastAPI application, including the research agent logic.

## Getting Started: Development and Local Testing

Follow these steps to get the application running locally for development and testing.

**1. Prerequisites:**

-   Node.js and npm (or yarn/pnpm)
-   Python 3.11+
-   **`GEMINI_API_KEY`**: The backend agent requires a Google Gemini API key.
    1.  Navigate to the `backend/` directory.
    2.  Create a file named `.env` by copying the `backend/.env.example` file.
    3.  Open the `.env` file and add your Gemini API key: `GEMINI_API_KEY="YOUR_ACTUAL_API_KEY"`

**2. Install Dependencies:**

**Backend:**

```bash
cd backend
pip install .
```

**Frontend:**

```bash
cd frontend
npm install
```

**3. Run Development Servers:**

**Backend & Frontend:**

```bash
make dev
```
This will run the backend and frontend development servers.    Open your browser and navigate to the frontend development server URL (e.g., `http://localhost:5173/app`).

_Alternatively, you can run the backend and frontend development servers separately. For the backend, open a terminal in the `backend/` directory and run `langgraph dev`. The backend API will be available at `http://127.0.0.1:2024`. It will also open a browser window to the LangGraph UI. For the frontend, open a terminal in the `frontend/` directory and run `npm run dev`. The frontend will be available at `http://localhost:5173`._

## How the Backend Agent Works (High-Level)

The core of the backend is a LangGraph agent defined in `backend/src/agent/graph.py`. It follows these steps:

<img src="./agent.png" title="Agent Flow" alt="Agent Flow" width="50%">

1.  **Generate Initial Queries:** Based on your input, it generates a set of initial search queries using a Gemini model.
2.  **Web Research:** For each query, it uses the Gemini model with the Google Search API to find relevant web pages.
3.  **Reflection & Knowledge Gap Analysis:** The agent analyzes the search results to determine if the information is sufficient or if there are knowledge gaps. It uses a Gemini model for this reflection process.
4.  **Iterative Refinement:** If gaps are found or the information is insufficient, it generates follow-up queries and repeats the web research and reflection steps (up to a configured maximum number of loops).
5.  **Finalize Answer:** Once the research is deemed sufficient, the agent synthesizes the gathered information into a coherent answer, including citations from the web sources, using a Gemini model.

## CLI Example

For quick one-off questions you can execute the agent from the command line. The
script `backend/examples/cli_research.py` runs the LangGraph agent and prints the
final answer:

```bash
cd backend
python examples/cli_research.py "What are the latest trends in renewable energy?"
```


## Deployment

In production, the backend server serves the optimized static frontend build. LangGraph requires a Redis instance and a Postgres database. Redis is used as a pub-sub broker to enable streaming real time output from background runs. Postgres is used to store assistants, threads, runs, persist thread state and long term memory, and to manage the state of the background task queue with 'exactly once' semantics. For more details on how to deploy the backend server, take a look at the [LangGraph Documentation](https://langchain-ai.github.io/langgraph/concepts/deployment_options/). Below is an example of how to build a Docker image that includes the optimized frontend build and the backend server and run it via `docker-compose`.

_Note: For the docker-compose.yml example you need a LangSmith API key, you can get one from [LangSmith](https://smith.langchain.com/settings)._

_Note: If you are not running the docker-compose.yml example or exposing the backend server to the public internet, you should update the `apiUrl` in the `frontend/src/App.tsx` file to your host. Currently the `apiUrl` is set to `http://localhost:8123` for docker-compose or `http://localhost:2024` for development._

**1. Build the Docker Image:**

   Run the following command from the **project root directory**:
   ```bash
   docker build -t gemini-fullstack-langgraph -f Dockerfile .
   ```
**2. Run the Production Server:**

   ```bash
   GEMINI_API_KEY=<your_gemini_api_key> LANGSMITH_API_KEY=<your_langsmith_api_key> docker-compose up
   ```

Open your browser and navigate to `http://localhost:8123/app/` to see the application. The API will be available at `http://localhost:8123`.

## Technologies Used

- [React](https://reactjs.org/) (with [Vite](https://vitejs.dev/)) - For the frontend user interface.
- [Tailwind CSS](https://tailwindcss.com/) - For styling.
- [Shadcn UI](https://ui.shadcn.com/) - For components.
- [LangGraph](https://github.com/langchain-ai/langgraph) - For building the backend research agent.
- [Google Gemini](https://ai.google.dev/models/gemini) - LLM for query generation, reflection, and answer synthesis.

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

# LangGraph + Dify Deployment

This repository contains a clean deployment setup for running both LangGraph and Dify services under a single domain with path-based routing.

## Architecture

```
demos.computelabs.ai                  → Landing page
├── gs.demos.computelabs.ai          → LangGraph API (port 8000)
├── dify.demos.computelabs.ai        → Dify Web Interface (port 3000)
└── api.dify.demos.computelabs.ai    → Dify API (port 5001)
```

**Services:**
- **Dify**: Runs independently using the official Docker Compose stack
- **LangGraph**: Runs with its own Redis and PostgreSQL
- **Caddy**: Single reverse proxy routing traffic to both services

## Quick Start

1. **Clone repositories:**
   ```bash
   # Make sure you have both repositories
   git clone https://github.com/langgenius/dify.git
   git clone <this-repository>
   ```

2. **Start all services:**
   ```bash
   cd gemini-fullstack-langgraph-quickstart
   ./deploy.sh start
   ```

3. **Access services:**
   - **Main site**: https://demos.computelabs.ai
   - **LangGraph**: https://gs.demos.computelabs.ai
   - **Dify**: https://dify.demos.computelabs.ai

## Management Commands

```bash
# Start everything
./deploy.sh start

# Stop everything
./deploy.sh stop

# Restart everything
./deploy.sh restart

# Check status
./deploy.sh status

# View logs
./deploy.sh logs [service-name]

# Manage individual stacks
./deploy.sh dify start/stop/restart/logs
./deploy.sh langgraph start/stop/restart/logs

# Check prerequisites
./deploy.sh check
```

## Configuration

### LangGraph Configuration
Environment variables in `.env`:
```bash
GEMINI_API_KEY=your_key_here
LANGSMITH_API_KEY=your_key_here
```

### Dify Configuration
Dify is configured via `../dify/docker/.env`. The deployment script automatically sets the correct URLs for your domain.

Key settings:
```bash
CONSOLE_API_URL=https://api.dify.demos.computelabs.ai
CONSOLE_WEB_URL=https://dify.demos.computelabs.ai
SERVICE_API_URL=https://api.dify.demos.computelabs.ai
APP_API_URL=https://api.dify.demos.computelabs.ai
APP_WEB_URL=https://dify.demos.computelabs.ai
```

## Network Setup

- **Dify**: Uses its own `dify_default` network
- **LangGraph**: Uses its own `default` network
- **Caddy**: Connects to both networks to route traffic

## File Structure

```
gemini-fullstack-langgraph-quickstart/
├── docker-compose.yml    # LangGraph + Caddy services
├── Caddyfile            # Reverse proxy configuration
├── deploy.sh            # Deployment management script
├── .env                 # LangGraph environment variables
└── README.md            # This file

../dify/docker/
├── docker-compose.yaml  # Official Dify stack
└── .env                 # Dify configuration
```

## Benefits of This Setup

1. **Clean Separation**: Each service runs independently
2. **Official Support**: Uses official Dify Docker Compose without modifications
3. **Easy Management**: Single script to manage both stacks
4. **Clean URLs**: All services accessible via clean subdomains
5. **Maintainable**: Easy to update either service independently

## Troubleshooting

1. **Check prerequisites:**
   ```bash
   ./deploy.sh check
   ```

2. **View service status:**
   ```bash
   ./deploy.sh status
   ```

3. **Check logs:**
   ```bash
   ./deploy.sh logs caddy        # Caddy routing logs
   ./deploy.sh logs langgraph-api # LangGraph API logs
   ./deploy.sh dify logs api     # Dify API logs
   ```

4. **Restart individual services:**
   ```bash
   ./deploy.sh dify restart
   ./deploy.sh langgraph restart
   ```

# Multi-Service AI Platform

A comprehensive deployment of multiple AI services behind a single Caddy reverse proxy, featuring LangGraph agents, Open WebUI with Ollama, and the Dify platform.

## 🚀 Services Included

- **🤖 LangGraph Agent**: Interactive AI agent powered by Google Gemini
- **💬 Open WebUI + Ollama**: Self-hosted ChatGPT-style interface with local models
- **🔧 Dify Platform**: Complete LLMOps platform for AI applications
- **🌐 Caddy Reverse Proxy**: Automatic HTTPS and subdomain routing

## 🌍 Live Services

- **Main Portal**: [https://demos.computelabs.ai](https://demos.computelabs.ai)
- **LangGraph**: [https://gs.demos.computelabs.ai/app/](https://gs.demos.computelabs.ai/app/)
- **Open WebUI**: [https://oui.demos.computelabs.ai](https://oui.demos.computelabs.ai)
- **Dify Web**: [https://dify.demos.computelabs.ai](https://dify.demos.computelabs.ai)
- **Dify API**: [https://api.dify.demos.computelabs.ai](https://api.dify.demos.computelabs.ai)

## 📚 Documentation

- **[Multi-Service Deployment Guide](./MULTI_SERVICE_DEPLOYMENT.md)** - Comprehensive guide on the architecture
- **[Network Topology](./NETWORK_DIAGRAM.md)** - Visual network architecture overview
- **[Deployment Script](./deploy.sh)** - Management script for all services

## 🏗️ Architecture Overview

This deployment uses a sophisticated multi-Docker Compose architecture:

```
Internet → Cloudflare DNS → Caddy Reverse Proxy
                               ├── LangGraph Services (default network)
                               ├── Open WebUI + Ollama (default network)  
                               └── Dify Services (docker_default network)
```

### Key Features

- **Service Isolation**: Each service stack runs independently
- **Single Entry Point**: All traffic routed through Caddy
- **Automatic HTTPS**: Let's Encrypt certificates for all domains
- **Cross-Network Communication**: Services can communicate across Docker networks
- **Independent Management**: Each service can be managed separately

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Domain with DNS pointing to your server
- Cloudflare DNS configuration

### Deployment

```bash
# Clone and setup
git clone <repository>
cd gemini-fullstack-langgraph-quickstart

# Start all services
sudo ./deploy.sh start

# Check status
sudo ./deploy.sh status
```

## 🛠️ Management Commands

```bash
# Start all services
sudo ./deploy.sh start

# Start specific service
sudo ./deploy.sh start langgraph
sudo ./deploy.sh start dify

# Stop services
sudo ./deploy.sh stop

# Restart services
sudo ./deploy.sh restart
sudo ./deploy.sh restart caddy
sudo ./deploy.sh restart open-webui

# View logs
sudo ./deploy.sh logs
sudo ./deploy.sh logs caddy
sudo ./deploy.sh logs open-webui

# Check status
sudo ./deploy.sh status
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file with:

```bash
# OpenAI API Key for Open WebUI
OPENAI_API_KEY=your_openai_api_key_here

# Gemini API Key for LangGraph
GEMINI_API_KEY=your_gemini_api_key_here
```

### DNS Configuration

Add these A records in Cloudflare:

| Record | Value |
|--------|-------|
| demos.computelabs.ai | 35.193.136.64 |
| gs.demos.computelabs.ai | 35.193.136.64 |
| oui.demos.computelabs.ai | 35.193.136.64 |
| dify.demos.computelabs.ai | 35.193.136.64 |
| api.dify.demos.computelabs.ai | 35.193.136.64 |

## 🐳 Docker Architecture

### Service Distribution

| Service | Location | Network | Container |
|---------|----------|---------|-----------|
| Caddy | LangGraph stack | default + docker_default | caddy |
| LangGraph API | LangGraph stack | default | langgraph-api |
| Open WebUI | LangGraph stack | default | open-webui |
| Dify Web | Dify stack | docker_default | docker-web-1 |
| Dify API | Dify stack | docker_default | docker-api-1 |

### Network Communication

- **Same Network**: Caddy → LangGraph/Open WebUI (container names)
- **Cross Network**: Caddy → Dify services (external links)

## 🔍 Troubleshooting

### Common Issues

1. **Network connectivity**: Ensure Dify stack is started first to create `docker_default` network
2. **SSL certificates**: Check DNS resolution and Caddy logs
3. **Service discovery**: Verify container names and network connections

### Debug Commands

```bash
# Check networks
sudo docker network ls

# Test connectivity
sudo docker exec caddy ping langgraph-api
sudo docker exec caddy ping docker-web-1

# View logs
sudo docker logs caddy
sudo ./deploy.sh logs open-webui
```

## 📖 Technical Details

For detailed technical information, see:

- **[Multi-Service Deployment Guide](./MULTI_SERVICE_DEPLOYMENT.md)** - Complete architecture documentation
- **[Network Topology](./NETWORK_DIAGRAM.md)** - Network design and routing
- **[Caddyfile](./Caddyfile)** - Reverse proxy configuration
- **[Docker Compose](./docker-compose.yml)** - Service definitions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Architecture**: Multi-Docker Compose with Caddy Reverse Proxy  
**Services**: LangGraph + Open WebUI + Dify Platform  
**Deployment**: Production-ready with automatic HTTPS
