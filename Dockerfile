# Alternative minimal approach
FROM n8nio/n8n:latest

USER root

# Install only essential packages
RUN apt-get update && \
    apt-get install -y python3 python3-pip wget && \
    pip3 install selenium requests && \
    wget -O /tmp/geckodriver.tar.gz https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz && \
    tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/geckodriver && \
    rm /tmp/geckodriver.tar.gz && \
    apt-get install -y firefox-esr && \
    rm -rf /var/lib/apt/lists/*

USER node
WORKDIR /home/node
EXPOSE 5678
CMD ["n8n"]
