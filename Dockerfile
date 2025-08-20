FROM node:20-alpine AS deps

RUN corepack enable && \
    corepack prepare pnpm@9.1.1 --activate

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod=false

FROM node:20-alpine AS builder

RUN corepack enable && \
    corepack prepare pnpm@9.1.1 --activate

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_PUBLIC_API_URL=https://agent-chat-ui-514670249047.asia-northeast1.run.app/api
ENV NEXT_PUBLIC_ASSISTANT_ID=e9a5370f-7a53-55a8-ada8-6ab9ef15bb5b

RUN pnpm run build

FROM node:20-alpine AS runner

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable && corepack prepare pnpm@9.1.1 --activate

RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001 nodejs

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=8080

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules

USER nodejs

CMD ["pnpm", "exec", "next", "start", "-p", "8080"]
