FROM mcr.microsoft.com/devcontainers/base:ubuntu

USER root

# Upgrade packages and install OpenJDK 21
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends openjdk-21-jdk ca-certificates curl gnupg \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Resolve JAVA_HOME for amd64 and arm64
RUN JAVA_HOME_PATH="$(dirname "$(dirname "$(readlink -f "$(which java)")")")" \
	&& echo "JAVA_HOME=${JAVA_HOME_PATH}" >> /etc/environment \
	&& ln -sfn "${JAVA_HOME_PATH}" /usr/lib/jvm/java-21-home
ENV JAVA_HOME=/usr/lib/jvm/java-21-home
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Install Node.js 24 (current LTS track via NodeSource)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
	&& apt-get install -y --no-install-recommends nodejs \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Upgrade npm and install Salesforce CLI globally
RUN npm install -g npm@latest \
	&& npm install -g @salesforce/cli@latest

# Install uv system-wide
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Switch to vscode for per-user tooling
USER vscode
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Install Salesforce Code Analyzer (plugins are per-user)
RUN sf plugins install code-analyzer

# Install CPython 3.14 via uv
RUN uv python install 3.14

# Pin 3.14 as the default Python for this user
RUN uv python pin 3.14 --global
