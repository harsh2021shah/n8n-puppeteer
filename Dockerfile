# Base image
FROM node:18-bullseye

USER root

# Install core dependencies
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
    fonts-liberation \
    fonts-dejavu-core \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome browser (Stable)
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# 🧪 Test block: Fetch ChromeDriver (Chrome for Testing) in separate steps
RUN curl -s https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json -o /tmp/versions.json

RUN python3 -c "import sys, json; data = json.load(open('/tmp/versions.json')); print('✔ Chrome for Testing Stable Version:', data['channels']['Stable']['version'])"

RUN python3 -c "import sys, json; data = json.load(open('/tmp/versions.json')); print('✔ ChromeDriver URL:', data['channels']['Stable']['downloads']['chromedriver']['linux64']['url'])"

# 🧩 Actual ChromeDriver install (now that URL is confirmed)
RUN DRIVER_URL=$(python3 -c "import sys, json; print(json.load(open('/tmp/versions.json'))['channels']['Stable']['downloads']['chromedriver']['linux64']['url'])") && \
    wget -O /tmp/chromedriver.zip "$DRIVER_URL" && \
    unzip /tmp/chromedriver.zip -d /tmp && \
    mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver && \
    chmod +x /usr/local/bin/chromedriver && \
    rm -rf /tmp/chromedriver.zip /tmp/chromedriver-linux64 /tmp/versions.json

# Install required Python packages
RUN pip3 install --no-cache-dir \
    selenium \
    webdriver-manager \
    requests

# Install n8n globally
RUN npm install -g n8n

# Environment config
ENV CHROME_BIN=/usr/bin/google-chrome-stable
ENV CHROMEDRIVER_PATH=/usr/local/bin/chromedriver
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Working directory and port
WORKDIR /home/node
EXPOSE 5678

# Start n8n
CMD ["n8n"]
