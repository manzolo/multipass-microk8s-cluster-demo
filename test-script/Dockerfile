FROM alpine:latest

# Installa gli strumenti necessari
RUN apk add --no-cache \
    mariadb-client \
    postgresql-client \
    redis \
    curl \
    bash

# Copia gli script di test
COPY run-tests.sh /run-tests.sh

# Imposta il comando di avvio
CMD ["bash", "/run-tests.sh"]