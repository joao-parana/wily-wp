# wily-wp

> This is a Docker image for Wordpress 4.4 on Ubuntu 14.04 with SMTP support

**Documentation in Brazilian Portuguese**

Implementa Wordpress baseando se na Imagem parana/wily-php

Assume nome de database `wordpress`, usuário `root` no MySQL 
e as seguintes váriáveis de ambiente para acesso ao database:

Providas pelo Docker:

    MYSQL_PORT_3306_TCP_ADDR
    MYSQL_PORT_3306_TCP_PORT

Providos pelo usuário:

    MYSQL_ROOT_PASSWORD

## Criando a imagem:

Premissa: Arquivo `conf/smtp/.GMAILRC` deve existir e contêm as credenciais da sua conta GMail

    cat conf/smtp/.GMAILRC

    AuthUser=sua-conta-no-gmail
    AuthPass=sua-senha-no-gmail
    FromLineOverride=YES
    UseTLS=YES

Agora faça o build:

    ./build-wily-wp

## Rodando o contêiner

Precisamos de um contêiner com Database MySQL. Uma ótima opção
é a imagem oficial **mariadb** disponível em 
[https://hub.docker.com/r/library/mariadb/](https://hub.docker.com/r/library/mariadb/)

Usaremos aqui a versão 10.1.10

    docker run -d -e MYSQL_ROOT_PASSWORD="xpto" \
               --name mysql-server-01 mariadb:10.1.10
    docker logs mysql-server-01
    docker ps -a  | grep mysql-server-01
    docker run -i -t --name wp-4.4 --rm \
               --link mysql-server-01:mysql \
               -e MYSQL_ROOT_PASSWORD="xpto" \
               -e GMAIL_ACCOUNT=sua-conta-no-gmail \
               -p 80:80 \
               parana/wily-wp

    # Subistitua sua-conta-no-gmail pelo se ID. No meu caso é **joao.parana**

Observe que o terminal fica bloqueado na console do Ubuntu 14.04

Para investigar problemas você pode abrir uma nova aba ou janela com um 
Terminal e executar o comando:

    docker exec -i -t wp-4.4 bash  

Com isso você poderá executar comandos tais como:

    cat /var/log/apache2/error.log
    cat /etc/ssmtp/ssmtp.conf
    cat /var/log/maillog

### Rodando como Daemon

    docker run -d --name wp-4.4  \
               --link mysql-server-01:mysql \
               -e MYSQL_ROOT_PASSWORD="xpto" \
               -e GMAIL_ACCOUNT=sua-conta-no-gmail \
               -p 80:80 \
               parana/wily-wp

Parando o Contêiner

    docker stop wp-4.4

Reiniciando o Contêiner

    docker start wp-4.4

**OBS:** caso você tenha configura corretamente o sSMTP 
você receberá uma mensagem a cada vez que o contêiner inicia
a execução

## Configurando o SMTP Server 

### Envio de mensagens de e-mail usando o **ssmtp** e GMail

Como dizem os norte americanos, **SMTP Sucks !** 

Procurei simplificar bastante o processo criando código específico 
no Dockerfile e na shell `run-wp` para resolver o problema da forma 
mais elegante. Aceito suestões de melhorias no meu blog
[http://joao-parana.com.br/blog/](http://joao-parana.com.br/blog/) 
ou como Issue aqui no projeto do Github.

### Passo a passo da configuração do Servidor de e-mail

* Conferir o conteúdo original do arquivo `/etc/ssmtp/ssmtp.conf`
* Alterar o arquivo `conf/smtp/.GMAILRC` no computador host
* Recriar a imagem executando a shell `./build-wily-wp`
* Acertar a configuração da conta no GMail (veja imagem abaixo)

**Cuidado:** O arquivo `conf/smtp/.GMAILRC` possue valores associados as 
**credenciais de acesso** (servidor SMTP, usuário, senha, etc) que devem 
ser protgidos e não devem ficar no seu Sistema de Controle de Versão, 
por isso adicione este tipo de informação apenas em arquivos listados 
no `.gitignore`

![Acertando a configuração da conta no GMail](https://raw.githubusercontent.com/joao-parana/wily-wp/master/docs/images/gmail_login_e_segurança.png)

#### O arquivo /etc/ssmtp/ssmtp.conf

A versão final dentro do contêiner deve parecer com isso abaixo:

    cat /etc/ssmtp/ssmtp.conf

    #
    # Config file for sSMTP sendmail
    #
    # The person who gets all mail for userids < 1000
    # Make this empty to disable rewriting.
    # root=postmaster
    root=sua-conta-no-gmail@gmail.com

    # The place where the mail goes. The actual machine name is required no 
    # MX records are consulted. Commonly mailhosts are named mail.domain.com
    mailhub=smtp.gmail.com:465

    # Where will the mail seem to come from?
    rewriteDomain=gmail.com

    # The full hostname
    hostname=seu-nome-de-host

    # Are users allowed to set their own From: address?
    # YES - Allow the user to specify their own From: address
    # NO - Use the system generated From: address
    #FromLineOverride=YES

    AuthUser=sua-conta-no-gmail
    AuthPass=sua-senha-no-gmail
    FromLineOverride=YES
    UseTLS=YES


## Volumes para Plugins e Temas **desenvolvidos "em casa"**

Acrescente a opção `-v $PWD/src:/app/custom` ao comando `docker run` para 
indicar o diretório para Plugins e Temas adicionais que você esteja 
desenvolvendo.

    docker run -i -t --name wp-4.4 --rm \
               --link mysql-server-01:mysql \
               -e MYSQL_ROOT_PASSWORD="xpto" \
               -e GMAIL_ACCOUNT=sua-conta-no-gmail \
               -v $PWD/src:/app/custom \ 
               -p 80:80 \
               parana/wily-wp

O comando docker exec pode ser usado para inspecionar o contêiner

    docker exec -i -t wp-4.4 bash
    
    ls -lAt /app/custom/plugins
    ls -lAt /app/custom/themes
