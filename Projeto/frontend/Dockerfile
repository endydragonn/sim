############################################################
#Etapa 1: Build do app Flutter (Web)
############################################################
FROM ubuntu:22.04 AS build

#Instala dependências do sistema
RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Define versão do Flutter como argumento
ARG FLUTTER_VERSION=3.19.6
ARG API_BASE_URL=""

# Instala Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter --branch ${FLUTTER_VERSION} --depth 1
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Define diretório de trabalho
WORKDIR /app

# Copia apenas o manifesto de dependências primeiro (cache otimizado)
COPY pubspec.* ./

# Habilita web e baixa dependências
RUN flutter config --enable-web && \
    flutter precache --web && \
    flutter pub get

# Copia o restante do código
COPY . .

# Define variável no build Flutter
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

############################################################
#Etapa 2: Imagem final com Nginx para servir estáticos
############################################################
FROM nginx:1-alpine-slim

# Copia arquivos de build do estágio anterior
COPY --from=build /app/build/web /usr/share/nginx/html

# Copia configuração customizada do Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expõe a porta padrão do nginx
EXPOSE 80

# Comando padrão
CMD ["nginx", "-g", "daemon off;"]