# Evolution API v2.3.7 + Baileys 7.0.0-rc14 + remendo de pareamento (companion_reg_refresh).
# Baseado no Dockerfile oficial da v2.3.7. Mudanças: (1) o código vem do tag 2.3.7 via git clone,
# (2) o Baileys sobe de 7.0.0-rc.9 para 7.0.0-rc14, (3) patch-package aplica patches/*.patch no postinstall.
FROM node:24-alpine AS builder

RUN apk update && \
    apk add --no-cache git ffmpeg wget curl bash openssl dos2unix

WORKDIR /evolution

ARG EVOLUTION_REF=2.3.7
RUN git clone --depth 1 --branch ${EVOLUTION_REF} https://github.com/EvolutionAPI/evolution-api.git .

COPY patches ./patches

# Troca o Baileys e liga o patch-package. Falha alto se o pacote não estiver como esperado.
RUN node -e "\
const fs=require('fs');\
const p=JSON.parse(fs.readFileSync('package.json','utf8'));\
if(p.dependencies.baileys!=='7.0.0-rc.9') throw new Error('baileys inesperado: '+p.dependencies.baileys);\
p.dependencies.baileys='7.0.0-rc14';\
p.devDependencies=p.devDependencies||{};\
p.devDependencies['patch-package']='^8.0.1';\
p.scripts.postinstall='patch-package --error-on-fail';\
fs.writeFileSync('package.json',JSON.stringify(p,null,2)+'\n');"

# npm install (e não npm ci): o package-lock original ainda aponta para o Baileys antigo.
RUN HUSKY=0 npm install --no-audit --no-fund --loglevel=error

# Confirma que o remendo realmente entrou no Baileys instalado.
RUN grep -q "companion_reg_refresh" node_modules/baileys/lib/Socket/socket.js

RUN cp ./.env.example ./.env
RUN chmod +x ./Docker/scripts/* && dos2unix ./Docker/scripts/*
RUN ./Docker/scripts/generate_database.sh
RUN npm run build

FROM node:24-alpine AS final

LABEL org.opencontainers.image.source="https://github.com/thelionrush/a_importacoes_evolution"
LABEL org.opencontainers.image.description="Evolution API 2.3.7 com Baileys rc14 e remendo de pareamento (Atrion Importações)"

RUN apk update && \
    apk add tzdata ffmpeg bash openssl

ENV TZ=America/Sao_Paulo
ENV DOCKER_ENV=true

WORKDIR /evolution

COPY --from=builder /evolution/package.json ./package.json
COPY --from=builder /evolution/package-lock.json ./package-lock.json

COPY --from=builder /evolution/node_modules ./node_modules
COPY --from=builder /evolution/dist ./dist
COPY --from=builder /evolution/prisma ./prisma
COPY --from=builder /evolution/manager ./manager
COPY --from=builder /evolution/public ./public
COPY --from=builder /evolution/.env ./.env
COPY --from=builder /evolution/Docker ./Docker
COPY --from=builder /evolution/runWithProvider.js ./runWithProvider.js
COPY --from=builder /evolution/tsup.config.ts ./tsup.config.ts

ENV DOCKER_ENV=true

EXPOSE 8080

ENTRYPOINT ["/bin/bash", "-c", ". ./Docker/scripts/deploy_database.sh && npm run start:prod" ]
