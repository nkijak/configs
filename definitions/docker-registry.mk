DOCKER?=sudo docker
HOST?=$$(hostname)

certs/docker.crt certs/docker.key &:
	@mkdir -p $$(dirname $@)
	openssl req \
	  -newkey rsa:4096 -nodes -sha256 -keyout certs/docker.key \
	  -addext "subjectAltName = DNS:registry.${HOST}.supersixfour" \
	  -x509 -days 730 -out certs/docker.crt


%/pushcert: certs/docker.crt
	@echo Pushing cert to $$(dirname $@)
	@scp $< $$(dirname $@):.
	@echo ---- moving cert on $$(dirname $@)
	@echo -------- you must do the following manually
	@echo  sudo mkdir -p /etc/docker/certs.d/registry.${HOST}.supersixfour/
	@echo  sudo mv $$(basename $<) /etc/docker/certs.d/registry.${HOST}.supersixfour/ca.crt
	@ssh $$(dirname $@)
	# can't do this
	#@ssh -T $$(dirname $@) 'bash \
	#  sudo mkdir -p /etc/docker/certs.d/registry.${HOST}.supersixfour/; \
	#  sudo mv $$(basename $<) /etc/docker/certs.d/registry.${HOST}.supersixfour/ca.crt
	@echo ""

pushcerts: pi@node021/pushcert pi@node031/pushcert pi@node032/pushcert


docker/start: certs/docker.crt certs/docker.key
	$(DOCKER) run -d \
	  --restart=always \
	  --name registry \
	  -v "$$(pwd)"/certs:/certs \
	  -v "$$(pwd)"/data:/var/lib/registry \
	  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
	  -e REGISTRY_HTTP_TLS_CERTIFICATE=$< \
	  -e REGISTRY_HTTP_TLS_KEY=$(word 2,$^) \
	  -p 443:443 \
	  registry:2

docker/%:
	$(DOCKER) container $$(basename $@) registry

