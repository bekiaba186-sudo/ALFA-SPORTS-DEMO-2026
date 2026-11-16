FROM node:20-alpine
WORKDIR /app/backend
COPY backend/package*.json ./
RUN npm install --omit=dev
COPY backend/src ./src
COPY backend/scripts ./scripts
COPY backend/migrations ./migrations
COPY public-admin /app/public-admin
COPY public /app/public
EXPOSE 4000
CMD ["sh","-c","node scripts/migrate.js && node scripts/seed.js && node src/server.js"]
