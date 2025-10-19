# Dockerfile for ClickUp MCP Server
FROM node:20-alpine

# Install clickup-mcp-server globally
RUN npm install -g clickup-mcp-server@1.12.0

# Set working directory
WORKDIR /app

# Run the MCP server
CMD ["npx", "clickup-mcp-server"]
