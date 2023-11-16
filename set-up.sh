#!/bin/bash
echo "Hey! I'm going to set up the Ambassador Demo Environment for you!"
#ask user to enter their name

echo "Cloning repo"
git=`git clone https://github.com/a8r-se/demo-kay.git`

echo "Installing Edge Stack"
# Add the Repo:
helm repo add datawire https://app.getambassador.io
helm repo update
 
# Create Namespace and Install:
kubectl create namespace ambassador && \
kubectl apply -f https://app.getambassador.io/yaml/edge-stack/3.1.0/aes-crds.yaml
kubectl wait --timeout=90s --for=condition=available deployment emissary-apiext -n emissary-system
helm install edge-stack --namespace ambassador datawire/edge-stack && \
kubectl -n ambassador wait --for condition=available --timeout=90s deploy -lproduct=aes

#creating listeners
kubectl apply -f - <<EOF
---
apiVersion: getambassador.io/v3alpha1
kind: Listener
metadata:
  name: edge-stack-listener-8080
  namespace: ambassador
spec:
  port: 8080
  protocol: HTTP
  securityModel: XFP
  hostBinding:
    namespace:
      from: ALL
---
apiVersion: getambassador.io/v3alpha1
kind: Listener
metadata:
  name: edge-stack-listener-8443
  namespace: ambassador
spec:
  port: 8443
  protocol: HTTPS
  securityModel: XFP
  hostBinding:
    namespace:
      from: ALL
EOF

#create hosts (regular and keycloak)
    #ask user what their host name will be
    #tell them that keycloak host will be keycloak.(name).k736.net
#install keycloak
#install quote


echo "apply quote application to cluster"
#Deploy Quote Service in default namespace
kubectl apply -f https://app.getambassador.io/yaml/v2-docs/3.1.0/quickstart/qotm.yaml
#create /backend/ mapping
kubectl apply -f - <<EOF
---
apiVersion: getambassador.io/v3alpha1
kind: Mapping
metadata:
  name: quote-backend
spec:
  hostname: "*"
  prefix: /backend/
  service: quote
  docs:
    path: "/.ambassador-internal/openapi-docs"
EOF

echo ""