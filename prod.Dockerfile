# Stage 1: Build the application
FROM node:22.16.0-alpine AS builder

# Install bash for compatibility with scripts
RUN apk add --no-cache bash

# Install NestJS CLI, TypeScript, and ts-node globally
RUN npm i -g @nestjs/cli typescript ts-node

# Copy package.json and package-lock.json (if exists) to a temporary directory
COPY package*.json /tmp/app/
RUN cd /tmp/app && npm install

# Copy the application code
COPY . /usr/src/app
RUN cp -a /tmp/app/node_modules /usr/src/app

# Set working directory
WORKDIR /usr/src/app

# Copy environment file if it doesn't exist
RUN if [ ! -f .env ]; then cp env-example-document .env; fi

# Build the application (compiles TypeScript to JavaScript)
RUN npm run build

# Stage 2: Create the runtime image
FROM node:22.16.0-alpine

# Install bash for script compatibility
RUN apk add --no-cache bash

# Set working directory
WORKDIR /usr/src/app

# Copy only the necessary files from the builder stage
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/package*.json ./
COPY --from=builder /usr/src/app/.env ./
COPY --from=builder /usr/src/app/wait-for-it.sh /opt/wait-for-it.sh
COPY --from=builder /usr/src/app/startup.document.dev.sh /opt/startup.document.dev.sh

# Install only production dependencies
RUN npm install --omit=dev

# Make scripts executable and remove Windows line endings
RUN chmod +x /opt/wait-for-it.sh
RUN chmod +x /opt/startup.document.dev.sh
RUN sed -i 's/\r//g' /opt/wait-for-it.sh
RUN sed -i 's/\r//g' /opt/startup.document.dev.sh

# Run the application
CMD ["/opt/startup.document.dev.sh"]