# Text Classification Example

This is a custom model serving example. The model will be downloaded from cloud storage via a storage initializer.

## Upload the model to S3 and create credentials

### Upload model to S3 using aws cli

```sh
# copy the model to s3
aws s3 cp ./models s3://<bucket>/<path>/models --recursive
# check the model
aws s3 ls s3://<bucket>/<path>/models/
```

### Create a secret containing the environment variables

```sh
kubectl create secret generic seldon-init-container-secret \
    --from-literal=RCLONE_CONFIG_S3_REGION='eu-central-1' \
    --from-literal=RCLONE_CONFIG_S3_ACCESS_KEY_ID='XXXX' \
    --from-literal=RCLONE_CONFIG_S3_SECRET_ACCESS_KEY='XXXX' \
    --from-literal=RCLONE_CONFIG_S3_PROVIDER='aws' \
    --from-literal=RCLONE_CONFIG_S3_TYPE='s3' \
    --from-literal=RCLONE_CONFIG_S3_ENV_AUTH=false
```


## Build and Run Locally

### Build from source

```sh
# run below command in text-classification/
pack build my-text-clf-infer \
	--path python \
	--env FUNC_TYPE="http" \
	--env FUNC_NAME="predict" \
	--env FUNC_SRC="main.py" \
	--builder openfunction/builder:v1
```

### Run the container

```sh
# here we mount the model manually
docker run --rm -p 8080:8080 -v $(pwd)/models:/mnt/models my-text-clf-infer
```

### Send a request

```sh
curl -v -X POST -H "Content-Type: application/json" "http://localhost:8080" -d @./input.json
# {"predictions":"compliment"}
```

## Deploy the function

```sh
kubectl apply -f text-clf-infer.yaml
```

## Run a classification

```sh
# if using kourier
export INGRESS_HOST=$(kubectl --namespace kourier-system get service kourier -o json | jq -r ".status.loadBalancer.ingress[0].hostname")
# if using istio ingress gateway
export INGRESS_HOST=$(kubectl --namespace istio-system get service istio-ingressgateway -o json | jq -r ".status.loadBalancer.ingress[0].hostname")
export INGRESS_PORT=80
# kubectl get ksvc
SERVICE_NAME=serving-ggtk4-ksvc-hqz2m
SERVICE_HOSTNAME=$(kubectl get ksvc $SERVICE_NAME -n default -o jsonpath='{.status.url}' | cut -d "/" -f 3)
curl -v -X POST -H "Content-Type: application/json" -H "Host: $SERVICE_HOSTNAME" "http://$INGRESS_HOST:$INGRESS_PORT" -d @./input.json
# {"predictions":"compliment"}
```
