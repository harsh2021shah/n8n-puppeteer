# Use Node.js base image
FROM node:18-bullseye

# Switch to root to install system-level packages
USER root

# Install dependencies for Puppeteer and Chrome
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg \
    ca-certificates \
    fonts-liberation \
    fonts-dejavu-core \
    libasound2 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libgtk-3-0 \
    libnss3 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    python3 \
    python3-pip \
    python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Google Chrome 114 using verified mirror with fallback dependency fix
RUN wget -O /tmp/google-chrome.deb \
    https://mirror.cs.uchicago.edu/google-chrome/pool/main/g/google-chrome-stable/google-chrome-stable_114.0.5735.90-1_amd64.deb && \
    apt-get update && \
    apt-get install -y /tmp/google-chrome.deb || apt-get -fy install && \
    rm /tmp/google-chrome.deb

# Install Puppeteer and required Python modules for coordination (optional)
RUN npm install -g n8n puppeteer && \
    pip3 install --no-cache-dir requests

# Set Puppeteer environment variables
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Copy the Puppeteer scraper script
COPY 9gag_scraper_puppeteer.js /home/node/9gag_scraper_puppeteer.js
RUN chmod +x /home/node/9gag_scraper_puppeteer.js

# Set working directory & permissions
WORKDIR /home/node
USER node

# Expose n8n port
EXPOSE 5678

# Start n8n
CMD ["n8n"]
