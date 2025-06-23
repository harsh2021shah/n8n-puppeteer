# Use n8n base image
FROM n8nio/n8n:latest

# Switch to root to install packages
USER root

# Install Google Chrome and dependencies for Puppeteer
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    apt-transport-https \
    fonts-liberation \
    fonts-dejavu-core \
    fontconfig \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Set Puppeteer env vars
ENV CHROME_BIN=/usr/bin/google-chrome-stable
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# Switch back to node user
USER node

# Set working directory
WORKDIR /home/node

# Expose n8n port
EXPOSE 5678

# Start n8n
CMD ["n8n"]
