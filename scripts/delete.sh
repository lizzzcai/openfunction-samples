#!/bin/bash

# Copyright 2022 The OpenFunction Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cert_manager_version=v1.7.1
tekton_pipeline_version=v0.30.0
shipwright_version=v0.6.0
knative_version=v1.2.5
kourier_version=v1.2.0
dapr_version=1.5.1
keda_version=2.4.0

all=false
with_shipwright=false
with_knative=false
with_openFuncAsync=false
region_cn=false

if [ $? != 0 ]; then
  echo "Terminating..." >&2
  exit 1
fi

while test $# -gt 0; do
  case "$1" in
    --all)
      all=true
      ;;
    --with-shipwright)
      with_shipwright=true
      ;;
    --with-knative)
      with_knative=true
      ;;
    --with-openFuncAsync)
      with_openFuncAsync=true
      ;;
    -p | --region-cn)
      region_cn=true
      ;;
    *)
      echo "Internal error!"
      exit 1
      ;;
  esac
  shift
done

if [ "$all" = "true" ]; then
  with_shipwright=true
  with_knative=true
  with_openFuncAsync=true
  with_ingress=true
fi

if [ "$with_shipwright" = "true" ]; then
  if [ "$region_cn" = "false" ]; then
    kubectl delete --filename https://github.com/tektoncd/pipeline/releases/download/${tekton_pipeline_version}/release.yaml
    kubectl delete --filename https://github.com/shipwright-io/build/releases/download/${shipwright_version}/release.yaml
  else
    kubectl delete --filename https://openfunction.sh1a.qingstor.com/tekton/pipeline/${tekton_pipeline_version}/release.yaml
    kubectl delete --filename https://openfunction.sh1a.qingstor.com/shipwright/${shipwright_version}/release.yaml
  fi
fi

if [ "$with_knative" = "true" ]; then
  if [ "$region_cn" = "false" ]; then
    kubectl delete -f https://github.com/knative/serving/releases/download/knative-${knative_version}/serving-crds.yaml
    kubectl delete -f https://github.com/knative/serving/releases/download/knative-${knative_version}/serving-core.yaml
    kubectl delete -f https://github.com/knative/net-kourier/releases/download/knative-${kourier_version}/kourier.yaml
    # kubectl delete -f https://github.com/knative/serving/releases/download/knative-${knative_version}/serving-default-domain.yaml
  else
    kubectl delete -f https://openfunction.sh1a.qingstor.com/knative/serving/knative-${knative_version}/serving-crds.yaml
    kubectl delete -f https://openfunction.sh1a.qingstor.com/knative/serving/knative-${knative_version}/serving-core.yaml
    kubectl delete -f https://openfunction.sh1a.qingstor.com/knative/net-kourier/knative-${kourier_version}/kourier.yaml
    # kubectl delete -f https://openfunction.sh1a.qingstor.com/knative/serving/knative-${knative_version}/serving-default-domain.yaml
  fi
fi

if [ "$with_openFuncAsync" = "true" ]; then
  if [ "$region_cn" = "false" ]; then
    # Installs the latest Dapr CLI.
    wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash -s ${dapr_version}
    # Init dapr
    dapr uninstall -k --all
    kubectl delete ns dapr-system
    # Installs the latest release version
    kubectl delete -f https://github.com/kedacore/keda/releases/download/v${keda_version}/keda-${keda_version}.yaml
  else
    # Installs the latest Dapr CLI.
    wget -q https://openfunction.sh1a.qingstor.com/dapr/install.sh -O - | /bin/bash -s ${dapr_version}
    # Init dapr
    dapr uninstall -k --all
    kubectl delete ns dapr-system
    # Installs the latest release version
    kubectl delete -f https://openfunction.sh1a.qingstor.com/v${keda_version}/keda-${keda_version}.yaml
  fi
fi

if [ "$with_ingress" = "true" ]; then
  if [ "$region_cn" = "false" ]; then
    kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
  else
    kubectl delete -f https://openfunction.sh1a.qingstor.com/ingress-nginx/deploy/static/provider/cloud/deploy.yaml
  fi
fi