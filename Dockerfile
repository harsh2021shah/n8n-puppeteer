FROM node:18-bullseye

USER root

# Install dependencies
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

# Install Chrome v114 directly (official .deb)
RUN wget https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_114.0.5735.90-1_amd64.deb && \
    dpkg -i google-chrome-stable_114.0.5735.90-1_amd64.deb || apt-get -fy install && \
    rm google-chrome-stable_114.0.5735.90-1_amd64.deb

# Install matching ChromeDriver v114.0.5735.90
RUN wget -O /tmp/chromedriver.zip https://chromedriver.storage.googleapis.com/114.0.5735.90/chromedriver_linux64.zip && \
    unzip /tmp/chromedriver.zip -d /tmp && \
    mv /tmp/chromedriver /usr/local/bin/chromedriver && \
    chmod +x /usr/local/bin/chromedriver && \
    rm -rf /tmp/chromedriver.zip

# Install Python packages
RUN pip3 install --no-cache-dir selenium webdriver-manager requests

# Install n8n
RUN npm install -g n8n

# Environment variables
ENV CHROME_BIN=/usr/bin/google-chrome
ENV CHROMEDRIVER_PATH=/usr/local/bin/chromedriver
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

WORKDIR /home/node
EXPOSE 5678

CMD ["n8n"]
