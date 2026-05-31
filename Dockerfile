FROM node:22-alpine

ENV NODE_ENV=production

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm ci --omit=dev && npm cache clean --force

COPY --chown=node:node app.js app-controller.js index.html ./
COPY --chown=node:node images ./images
COPY --chown=node:node seed ./seed

EXPOSE 3000

USER node

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:' + (process.env.PORT || 3000) + '/live').then(function(res) { process.exit(res.ok ? 0 : 1); }).catch(function() { process.exit(1); })"

CMD ["npm", "start"]
