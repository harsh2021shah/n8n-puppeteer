# Use Debian-based Node image
FROM node:18-bullseye

# Switch to root
USER root

# Update and install system packages
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

# Add Google Chrome repo and install
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Install ChromeDriver
RUN CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | cut -d '.' -f1-3) && \
    wget -O /tmp/chromedriver.zip "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/${CHROME_VERSION}/linux64/chromedriver-linux64.zip" && \
    unzip /tmp/chromedriver.zip -d /tmp && \
    mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver && \
    chmod +x /usr/local/bin/chromedriver && \
    rm -rf /tmp/chromedriver.zip /tmp/chromedriver-linux64

# Install Python packages
RUN pip3 install --no-cache-dir selenium webdriver-manager requests

# Install n8n globally
RUN npm install -g n8n

# Set environment variables
ENV CHROME_BIN=/usr/bin/google-chrome-stable
ENV CHROMEDRIVER_PATH=/usr/local/bin/chromedriver
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# Set working directory
WORKDIR /home/node

# Expose n8n port
EXPOSE 5678

# Start n8n
CMD ["n8n"]
