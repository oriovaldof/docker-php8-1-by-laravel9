FROM php:8.1.10-fpm

# Arguments
ARG user=devroot
ARG uid=1000

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    rsync \
    sshpass \
    ldap-utils 

######
# NODE
# install node:lts-gallium - LTS 16.17.0
# copiando na versão específica que queremos de uma imagem docker
######
COPY --from=node:lts-gallium /usr/local/include/node /usr/local/include/node
COPY --from=node:lts-gallium /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node:lts-gallium /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd sockets   

#Copiando e instalando extensao PHP Ldap de uma imagem de extensoes
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/
RUN install-php-extensions ldap pgsql

# Copiando o composer na sua ultima versao de uma imagem docker composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Install redis
RUN pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis

# Set working directory
WORKDIR /var/www

USER $user