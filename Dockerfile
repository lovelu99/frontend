# ---------- Stage 1: build ----------
#FROM node:20-alpine3.21 AS builder
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---------- Stage 2: serve ----------
# FROM nginx:alpine
# RUN apk update && apk upgrade --no-cache

FROM nginx:1.23-alpine
#only to pipeline fail

# Copy React build output
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
