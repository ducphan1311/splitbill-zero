# Build Stage
FROM oven/bun:1.2-alpine AS base
WORKDIR /app

# Install dependencies
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile || bun install

# Copy application files
COPY . .

# Expose port (Render/Fly.io inject PORT environment variable)
ENV PORT=3088
EXPOSE 3088

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/health || exit 1

# Run the Bun server
CMD ["bun", "run", "index.ts"]
