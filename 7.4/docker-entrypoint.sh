#!/bin/sh -x

NUXEO_CONF=$NUXEO_HOME/bin/nuxeo.conf

if [ "$1" = './bin/nuxeoctl' ]; then
  if [ ! -f $NUXEO_HOME/configured ]; then

    # PostgreSQL conf
    if [ -n "$NUXEO_DB_TYPE" ]; then
      
      NUXEO_DB_HOST=${NUXEO_DB_HOST:-'db_2'}
      NUXEO_DB_NAME=${NUXEO_DB_NAME:-nuxeo}
      NUXEO_DB_USER=${NUXEO_DB_USER:-nuxeo}
      NUXEO_DB_PASSWORD=${NUXEO_DB_PASSWORD:-nuxeo}

    	perl -p -i -e "s/^#?(nuxeo.templates=.*$)/\1,${NUXEO_DB_TYPE}/g" $NUXEO_CONF
    	perl -p -i -e "s/^#?nuxeo.db.host=.*$/nuxeo.db.host=${NUXEO_DB_HOST}/g" $NUXEO_CONF
    	perl -p -i -e "s/^#?nuxeo.db.name=.*$/nuxeo.db.name=${NUXEO_DB_NAME}/g" $NUXEO_CONF
    	perl -p -i -e "s/^#?nuxeo.db.user=.*$/nuxeo.db.user=${NUXEO_DB_USER}/g" $NUXEO_CONF
    	perl -p -i -e "s/^#?nuxeo.db.password=.*$/nuxeo.db.password=${NUXEO_DB_PASSWORD}/g" $NUXEO_CONF
    fi

    # nuxeo.url
    #echo "nuxeo.url=$HTTP_PROTOCOL://$DOMAIN/nuxeo" >> $NUXEO_CONF

    # connect.url
    if [ -n "$NUXEO_CONNECT_URL" ]; then
      echo "org.nuxeo.connect.url=$NUXEO_CONNECT_URL" >> $NUXEO_CONF
    fi

    if [ -n "$NUXEO_ES_HOST" ]; then
      echo "elasticsearch.addressList=${NUXEO_ES_HOST}:9300" >> $NUXEO_CONF
      echo "elasticsearch.clusterName=elasticsearch" >> $NUXEO_CONF
    fi

    echo "org.nuxeo.automation.trace=true" >> $NUXEO_CONF
    echo "org.nuxeo.dev=true" >> $NUXEO_CONF

    if [ -n "$NUXEO_REDIS_HOST" ]; then
      echo "nuxeo.redis.enabled=true" >> $NUXEO_CONF
      echo "nuxeo.redis.host=${NUXEO_REDIS_HOST}" >> $NUXEO_CONF
    fi
    
    mkdir -p ${NUXEO_DATA:=/var/lib/nuxeo/data}
    mkdir -p ${NUXEO_LOG:=/var/log/nuxeo}
    mkdir -p /var/run/nuxeo

    chown -R $NUXEO_USER:$NUXEO_USER $NUXEO_DATA
    chown -R $NUXEO_USER:$NUXEO_USER $NUXEO_LOG
    chown -R $NUXEO_USER:$NUXEO_USER /var/lib/nuxeo
    chown -R $NUXEO_USER:$NUXEO_USER /var/run/nuxeo

    cat << EOF >> $NUXEO_HOME/bin/nuxeo.conf
nuxeo.log.dir=$NUXEO_LOG
nuxeo.pid.dir=/var/run/nuxeo
nuxeo.data.dir=$NUXEO_DATA
nuxeo.wizard.done=true
EOF
    touch $NUXEO_HOME/configured

  fi

  # instance.clid
  if [ -n "$NUXEO_CLID" ]; then
    printf "%b\n" "$NUXEO_CLID" >> $NUXEO_DATA/instance.clid
  fi


  ## Executed at each start
  if [ -n "$NUXEO_CLID"  ] && [$(INSTALL_HOTFIX:'true') = "true" ]; then
      gosu $NUXEO_USER $NUXEOCTL mp-hotfix  
  fi
  # Install packages if exist
  if [ -n "$NUXEO_PACKAGES" ]; then
    gosu $NUXEO_USER $NUXEOCTL mp-install $NUXEO_PACKAGES --relax=false --accept=true
  fi

  if [ $2 = 'console']; then
    exec gosu $NUXEO_USER $NUXEOCTL console
  else
    exec gosu $NUXEO_USER $@
  fi

fi


exec $@