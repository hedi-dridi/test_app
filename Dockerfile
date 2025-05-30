# Use an official Node.js runtime as the base image
FROM node:20-slim AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy project files
COPY . .

# Build the React application
RUN npm run build

# Production stage
FROM python:3.11-slim

# Install Node.js
RUN apt-get update && apt-get install -y \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install llama-cpp-python flask

# Set working directory
WORKDIR /app

# Copy built files from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/app.py .
COPY --from=builder /app/templates ./templates
COPY --from=builder /app/static ./static

# Expose ports
EXPOSE 3000 5000 4444

# Set environment variables
ENV NODE_ENV=production
ENV PYTHONUNBUFFERED=1

# Start the Flask server
CMD ["python3", "app.py"]