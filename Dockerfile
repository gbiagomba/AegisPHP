# Dockerfile for PHALANX: bundles Psalm, ProgPilot & psecio/parse
# Multi-stage build for optimized image size and security

FROM php:8.4-cli AS base

# Metadata
LABEL maintainer="PHALANX Security Team"
LABEL version="0.1.0"
LABEL description="PHALANX - Unified PHP Security Analysis Tool"

# Install system dependencies with security updates
RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
      unzip \
      zip \
      ca-certificates \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install Composer from official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Create non-root user for running scans
RUN useradd -m -u 1000 -s /bin/bash phalanx && \
    mkdir -p /home/phalanx/.composer && \
    chown -R phalanx:phalanx /home/phalanx

# Switch to non-root user for tool installation
USER phalanx
WORKDIR /home/phalanx

# Install global PHP SAST tools: Psalm & parse
RUN composer global require --no-interaction --prefer-dist \
      vimeo/psalm \
      psecio/parse

# Clone & install ProgPilot
RUN git clone --depth 1 https://github.com/designsecurity/progpilot.git /home/phalanx/progpilot \
 && cd /home/phalanx/progpilot \
 && composer install --no-interaction --prefer-dist --no-dev || true

# Add global Composer bins to PATH
ENV PATH="/home/phalanx/.composer/vendor/bin:${PATH}"

# Set working directory for scans (will be mounted by phalanx.py)
WORKDIR /app

# Health check to ensure tools are accessible
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD psalm --version && parse --version || exit 1

# No ENTRYPOINT - allows calling each tool directly:
#  docker run phalanx psalm ...
#  docker run phalanx parse scan /app --format json
#  docker run phalanx php /home/phalanx/progpilot/src/ProgPilot.php ...

# Security: Run as non-root user
USER phalanx
