FROM node:26-alpine AS build
ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}

WORKDIR /app
COPY activity-1/frontend/package*.json ./
RUN npm install -g typescript vite vue-tsc
RUN npm ci
COPY activity-1/frontend/ ./
RUN npm run build

FROM nginx:alpine
ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy built SPA and custom nginx config
COPY --from=build /app/dist /usr/share/nginx/html
COPY activity-2/nginx.conf /etc/nginx/conf.d/default.conf

# Configure nginx to run as non-root (Container Apps best practice)
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
