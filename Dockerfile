FROM node:20.19  AS build

WORKDIR /app

RUN apt-get update -y

COPY package.json  ./

RUN npm install

COPY . .

RUN npm run build

FROM node:20.19-slim

WORKDIR /app

COPY --from=build --chown=node:node /app /app

USER node

EXPOSE 1600

CMD ["npm", "run", "start"]
