FROM node:20-alpine

WORKDIR /app

COPY package.json ./
COPY scripts ./scripts
COPY src ./src

RUN npm run build

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000
ENV ENVIRONMENT=production

EXPOSE 3000

CMD ["npm", "start"]
