FROM #{FROM}

ENV NODE_VERSION #{NODE_VERSION}
ENV NPM_VERSION 2.5.0

RUN curl -SLO "http://resin-packages.s3.amazonaws.com/node/v$NODE_VERSION/node-v$NODE_VERSION-linux-armv6hf.tar.gz" \
	&& tar -xzf "node-v$NODE_VERSION-linux-armv6hf.tar.gz" -C /usr/local --strip-components=1 \
	&& rm "node-v$NODE_VERSION-linux-armv6hf.tar.gz" \
	&& npm install -g npm@"$NPM_VERSION" \
	&& npm cache clear

CMD [ "node" ]