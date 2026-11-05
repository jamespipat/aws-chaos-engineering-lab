FROM node:22-bookworm-slim
WORKDIR /app
ENV NODE_ENV=production
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY src ./src
COPY certs/global-bundle.pem ./certs/global-bundle.pem
USER 1000
EXPOSE 8080
CMD ["node", "--experimental-strip-types", "src/main.ts"]
