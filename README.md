# lustre-aws-fsx SpecialResource manifest and helm chart

This repository contains the Helm chart and YAML manifest for a SpecialResource for deploying the driver container and CSI driver for the AWS Lustre FSx service in an OpenShift Container Platform cluster running on AWS.

See [kubernetes-sigs/aws-fsx-csi-driver](https://github.com/kubernetes-sigs/aws-fsx-csi-driver) for details about the CSI driver and its usage.

The Special Resource Operator needs to be installed on your OpenShift cluster in order to use this SpecialResource. See the [Special Resource Operator](https://github.com/openshift/special-resource-operator) for more information.

