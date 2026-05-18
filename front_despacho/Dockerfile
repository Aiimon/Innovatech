FROM node:20-alpine AS builder
WORKDIR /build
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
# Corrección de permisos para que corra sin root en Fargate en el puerto 8000
RUN touch /var/run/nginx.pid && \ 
    chown -R nginx:nginx /var/run/nginx.pid /var/cache/nginx /var/log /usr/share/nginx/html
USER nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf
# CORREGIDO EL TYPO: de ngnix a nginx
COPY --from=builder /build/dist /usr/share/nginx/html
# Informamos el puerto correcto
EXPOSE 8000