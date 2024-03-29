# OCM

## Local Example

**_Initial setup (turn off VPN first)_**

- For work environments with Docker proxies configured
  - either unset proxies
  - or use `podman` by running the `hack/podman.sh` first, and run `podman machine rm` when done
- Install required `clusteradm` binary with:
  ```bash
  curl -L https://raw.githubusercontent.com/open-cluster-management-io/clusteradm/main/install.sh | bash
  ```
- Run `hack/local-up.sh` to start _3_ kind clusters
  - run `KIND_EXPERIMENTAL_PROVIDER=podman hack/local-up.sh` if using podman
  - run `kubectl -n open-cluster-management get pod --context kind-hub` post install to check if manager pods are up

**_Create multi-cluster resources_**

1. Register [clustersets](https://open-cluster-management.io/concepts/managedclusterset/) on the hub cluster

```bash
kubectl apply -f examples/clusterset
```

- in the hub cluster (`kind-hub` in context), `cluster1` and `cluster2` cluster namespace will be created after the registration
  - resources created in the hub's cluster namespace will be propagated to the managed cluster by ocm agents
- a clusterset is a set of managed clusters and they can be mapped to a clusterset namespace
  - resources created in the clusterset namespace will be propagated to the clusters in the clsuterset by default
- clsuterset and clusterset namespaces are _N:N_ mapping, via `ManagedClusterSetBinding`
  - [the argo clusterset manifest](examples/clusterset/argo-clusterset.yaml) creates a clusterset and a namespace, and bind them together
  - [the gloabl clusterset manifest](examples/clusterset/global-clusterset.yaml) binds the default global clusterset (all clusters) too both a dedicated gloabl namespace as well as the `argo-workspace` namespace (created from the step above)

2. Create [placements](https://open-cluster-management.io/concepts/placement/) on the hub cluster

```bash
kubectl apply -f examples/placement
```

- the placement controller uses the criteria specified in the placement spec to select a cluster namespace for a given work
  - [the allclusters placement](examples/placement/allclusters.yaml) will place the work in all of the managed clusters in the `global` clusterset
  - [the singlecluster placement](examples/placement/singlecluster.yaml) will place the work in one of the clusters in the `argo-clusterset` clusterset (controlled by `spec.numberOfClusters`)
- the placement controller will create `PlacementDecision` for each placement made for a given work
- [`ManifestWork`](https://open-cluster-management.io/concepts/manifestwork/) can be used along with the placement API to create resource(s) on managed clusters using different strategies

3. Create [work](https://open-cluster-management.io/concepts/manifestwork/) on the hub cluster

```bash
# creates argo namespace in all managed clusters
clusteradm create work argo-namespace -f examples/work/namespace.yaml --placement argo-workspace/allclusters --overwrite=true
# install argo in managed al clusters
clusteradm create work argo -f examples/work/argo.yaml --placement argo-workspace/allclusters --overwrite=true
# grant the necessary rbacs
clusteradm create work rbac -f examples/work/rbac.yaml --placement argo-workspace/allclusters --overwrite=true
# create argo resources using different placement strategies
clusteradm create work example-workflowtemplate -f examples/work/workflowtemplate.yaml --placement argo-workspace/allclusters --overwrite=true
clusteradm create work example-workflow -f examples/work/workflow.yaml --placement argo-workspace/singlecluster --overwrite=true
```

> Screwed up something and want to start over? Delete all the manifestwork with
>
> ```bash
> kuebctl get manifestwork -A -ojson --context kind-hub | jq -r '.items[].metadata | [.namespace, .name] | join(" ")' | awk '{ printf "kubectl delete manifestwork -n %s %s --context kind-hub\n", $1, $2}' | sh
> ```

- A work can be created using the `ManifestWork` manifest, but note resources created this way need to select the destination cluster manually (by specifying the cluster namespace as the manifestwork namespace)
- ATM, from the documentation available, it seems that `clusteradm` cli has to be used to submit a work with a placement strategy

## Issues

- ManifestWork does not allow [generateName](https://github.com/open-cluster-management-io/ocm/blob/main/pkg/work/webhook/common/validator.go#L52-L59)
- Placement has to be specified as `clusteradm` flag (`--placement <name>`), ideally it should a field in the ManifestWork
- Each submission of a Workflow (or any ephemeral run-to-completion batch jobs) is gonna need a new ManifestWork, doubling the CRs created
- [TODO] RBACs for dispatching Workflows to spoke clusters from hub
- [TODO] The full Workflow status is not propagated back to the hub cluster, need to investigate
- [TODO] Will update to the ManifestWork trigger a re-run of the Workflow? (mutable vs immutable fields, e.g. name vs label)
- [TODO] How to explicitly trigger a re-run of the Workflow? Will it follow the same placement decision?

## Podman troubleshooting

### kind clusters acting up / `clusteradm` commands stuck

The podman VM can be unstable, so the easiest thing to do is

```bash
# delete all clusters
KIND_EXPERIMENTAL_PROVIDER=podman kind delete clusters --all
# remove the podman vm
podman machine rm
# rerun the whole thing
hack/podman.sh
hack/local-up.sh
```

### control plane pod stuck in CLBO with message "too many open files"

The podman default systemctl settings needs to be adjusted with

- `podman machine ssh sudo sysctl fs.inotify.max_user_instances=1280`
- `podman machine ssh sudo sysctl fs.inotify.max_user_watches=655360`
- reference: https://github.com/kubeflow/manifests/issues/2087#issuecomment-1005556491
