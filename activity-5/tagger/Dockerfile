# Build stage
FROM node:20-alpine AS build
WORKDIR /app
COPY activity-5/tagger/package*.json ./
RUN npm ci
COPY activity-5/tagger/tsconfig.json ./
COPY activity-5/tagger/src ./src
RUN npm run build

# Production stage
FROM node:20-alpine
WORKDIR /app
COPY --from=build /app/package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist

CMD ["node", "dist/index.js"]
