FROM node:18-bullseye

USER root

# Install base dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    gnupg \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    python3 \
    python3-pip \
    python3-dev \
    libasound2 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libgtk-3-0 \
    libnss3 \
    libxss1 \
    libasound2 \
    libx11-xcb1 \
    fonts-liberation \
    fonts-dejavu-core \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# Install latest stable Chrome from official PPA
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y google-chrome-stable

# Install latest stable ChromeDriver using Chrome for Testing
RUN CFT_JSON_URL="https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json" && \
    DRIVER_URL=$(curl -s $CFT_JSON_URL | python3 -c "import sys, json; print(json.load(sys.stdin)['channels']['Stable']['downloads']['chromedriver']['linux64']['url'])") && \
    wget -O /tmp/chromedriver.zip "$DRIVER_URL" && \
    unzip /tmp/chromedriver.zip -d /tmp && \
    mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver && \
    chmod +x /usr/local/bin/chromedriver && \
    rm -rf /tmp/chromedriver.zip /tmp/chromedriver-linux64

# Install Python packages (optional for scraping/API support)
RUN pip3 install --no-cache-dir selenium webdriver-manager requests

# Install n8n globally
RUN npm install -g n8n

# Set Puppeteer/Chrome env vars
ENV CHROME_BIN=/usr/bin/google-chrome
ENV CHROMEDRIVER_PATH=/usr/local/bin/chromedriver
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

WORKDIR /home/node
EXPOSE 5678

CMD ["n8n"]
