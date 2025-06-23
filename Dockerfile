FROM node:18-bullseye

USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget curl unzip gnupg ca-certificates apt-transport-https \
    software-properties-common python3 python3-pip python3-dev \
    fonts-liberation fonts-dejavu-core fontconfig \
    libasound2 libatk1.0-0 libatk-bridge2.0-0 libcups2 \
    libxcomposite1 libxdamage1 libxrandr2 libgbm1 \
    libpango-1.0-0 libpangocairo-1.0-0 libgtk-3-0 \
    libnss3 libxss1 libxtst6 xdg-utils && \
    rm -rf /var/lib/apt/lists/*

# Install Google Chrome 114 using UChicago mirror
RUN wget -O /tmp/google-chrome.deb \
    https://mirror.cs.uchicago.edu/google-chrome/pool/main/g/google-chrome-stable/google-chrome-stable_114.0.5735.90-1_amd64.deb && \
    apt-get update && \
    apt-get install -y /tmp/google-chrome.deb && \
    rm /tmp/google-chrome.deb

# Install ChromeDriver 114.0.5735.90
RUN wget -O /tmp/chromedriver.zip \
    https://chromedriver.storage.googleapis.com/114.0.5735.90/chromedriver_linux64.zip && \
    unzip /tmp/chromedriver.zip -d /tmp && \
    mv /tmp/chromedriver /usr/local/bin/chromedriver && \
    chmod +x /usr/local/bin/chromedriver && \
    rm -rf /tmp/chromedriver.zip

# Install Python libs for Selenium automation
RUN pip3 install --no-cache-dir selenium webdriver-manager requests

# Install n8n CLI
RUN npm install -g n8n

# Set environment variables for Puppeteer/Selenium
ENV CHROME_BIN=/usr/bin/google-chrome \
    CHROMEDRIVER_PATH=/usr/local/bin/chromedriver \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Set working directory & expose port
WORKDIR /home/node
EXPOSE 5678

# Run n8n
CMD ["n8n"]
