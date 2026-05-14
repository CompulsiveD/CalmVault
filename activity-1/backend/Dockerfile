FROM node:26-alpine AS build
WORKDIR /app
COPY step-1/backend/package*.json ./
RUN npm install -g typescript
RUN npm ci
COPY step-1/backend/ ./
RUN npm run build

FROM node:26-alpine
WORKDIR /app

# Create non-root user (Container Apps best practice)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY step-1/backend/package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist

# Switch to non-root user
USER appuser

# Container Apps injects PORT via env var; default to 3001
ENV PORT=3001
EXPOSE 3001

# Health check for Container Apps probes
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/api/health || exit 1

CMD ["node", "dist/index.js"]
