# Use n8n base image
FROM n8nio/n8n:latest

# Switch to root to install packages
USER root

# Update package list and install dependencies separately for better error handling
RUN apt-get update

# Install basic dependencies first
RUN apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    curl

# Install Python and pip
RUN apt-get install -y \
    python3 \
    python3-pip \
    python3-setuptools

# Install Firefox and X11 dependencies
RUN apt-get install -y \
    firefox-esr \
    xvfb \
    libgtk-3-0 \
    libdbus-glib-1-2

# Clean up apt cache
RUN rm -rf /var/lib/apt/lists/* && apt-get clean

# Upgrade pip and install Python packages
RUN python3 -m pip install --upgrade pip

# Install Python packages for web scraping
RUN pip3 install --no-cache-dir \
    selenium==4.15.0 \
    webdriver-manager==4.0.1 \
    requests==2.31.0

# Download and install geckodriver manually with fixed version
RUN wget -O /tmp/geckodriver.tar.gz "https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz" && \
    tar -xzf /tmp/geckodriver.tar.gz -C /tmp && \
    mv /tmp/geckodriver /usr/local/bin/geckodriver && \
    chmod +x /usr/local/bin/geckodriver && \
    rm /tmp/geckodriver.tar.gz

# Set environment variables for headless operation
ENV DISPLAY=:99

# Switch back to node user for security
USER node

# Set working directory
WORKDIR /home/node

# Expose n8n port
EXPOSE 5678

# Start n8n
CMD ["n8n"]
