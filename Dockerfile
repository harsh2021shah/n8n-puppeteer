# Use n8n base image
FROM n8nio/n8n:latest

# Switch to root to install packages
USER root

# Install Python, Firefox, and system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    firefox-esr \
    wget \
    gnupg \
    ca-certificates \
    xvfb \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install Python packages globally (since we're in a container)
RUN pip3 install --no-cache-dir \
    selenium \
    webdriver-manager \
    gspread \
    oauth2client \
    requests

# Download and install geckodriver (Firefox WebDriver)
RUN GECKODRIVER_VERSION=$(wget -qO- "https://api.github.com/repos/mozilla/geckodriver/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")') && \
    wget -O /tmp/geckodriver.tar.gz "https://github.com/mozilla/geckodriver/releases/download/$GECKODRIVER_VERSION/geckodriver-$GECKODRIVER_VERSION-linux64.tar.gz" && \
    tar -xzf /tmp/geckodriver.tar.gz -C /tmp && \
    mv /tmp/geckodriver /usr/local/bin/geckodriver && \
    chmod +x /usr/local/bin/geckodriver && \
    rm /tmp/geckodriver.tar.gz

# Set environment variables for headless operation
ENV DISPLAY=:99
ENV PYTHONPATH=/usr/local/lib/python3.11/site-packages

# Create directory for Python scripts
RUN mkdir -p /home/node/scripts && \
    chown -R node:node /home/node/scripts

# Switch back to node user for security
USER node

# Set working directory
WORKDIR /home/node

# Expose n8n port
EXPOSE 5678

# Start n8n
CMD ["n8n"]
