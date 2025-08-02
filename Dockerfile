# Universal, feature-rich web dev/test container using Nginx and Node.js
FROM node:20-bullseye AS builder

# Set working directory
WORKDIR /app

# Copy package files and install dependencies (if any)
COPY package*.json ./
RUN if [ -f package.json ]; then npm install; fi

# Copy all project files
COPY . .

# Build step for static assets (optional, e.g. if using Vite or similar)
# RUN npm run build

# --- Runtime image ---
FROM nginx:alpine

# Copy built static files or all public files to nginx html dir
COPY --from=builder /app /usr/share/nginx/html

# Remove default nginx config and add a universal config
RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
