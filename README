## Scope

- This project tries not to create a new way of federating multi-cluster workloads
  - It aims to use OCM/Karmada or other relative mature/widely-adopted multi-cluster federation frameworks
- This project does not care about the building phase of clusters
  - All clusters included in the multi-cluster environment are considered to be up and running
  - They may have varied healthiness status, but they are all considered built and initialized

## Requirements

**_should be handled by the multi-cluster framework_**

- Federation resources across multiple clusters
  - Be aware of the status/healthiness of the clusters
  - Be aware of the load of the clusters: both the overall resource and the individual resource quota per namespace
  - Push vs Poll federation/deployment models
    - https://docs.google.com/document/d/1cWcdB40pGg3KS1eSyb9Q6SIRvWVI8dEjFp9RI0Gk0vg/edit#heading=h.f9hh5bs7b8k5
  - Ephemeral vs Persistent resource deployments
- Support hot swapping clusters from "cluster sets" or "spoke clusters" or "managed clusters"
  - when new clusters are added, they should become scheduleable right a way
  - when clusters are deleted from the fleet of clusters, they should be tainted and drained
- RBAC for hub-spoke or spoke-spoke coordination

**_the multi-cluster framework should provide an interface for this_**

- Garbage Collection
  - GC completed items on worker/hub clusters
  - GC higher level CRs when they stop scheduling Pod onto worker/hub clusters
- Fail-Overs
  - For any deployments/jobs, if a pod fails in one cluster then the job should have the option to continue on other clusters
- Track the status of the job
  - Success/failure should be reflected to the federation API regardless of where the "work" is being done
  - Custom `status` fields native to the CRDs, e.g. status fields other than just `conditions`, should be propagated back to the hub/control plane
- RBAC
  - From user's perspective
    - Limited access to hub cluster
    - More elevated privilege in spoke clusters, e.g. delete stuck pods etc.
  - From the "work"'s perspective
    - Distribute the "work" with a service account to spoke clusters (push)
    - Spoke clusters read the "work" with a service account from hub cluster based on some topology/selector (pull)

## References

- [Work API design doc][work-api]
- [vallery's original blog on work API][vallery-blog]

[work-api]: https://docs.google.com/document/d/1cWcdB40pGg3KS1eSyb9Q6SIRvWVI8dEjFp9RI0Gk0vg/edit#heading=h.f9hh5bs7b8k5
[vallery-blog]: https://timewitch.net/post/2020-03-31-multicluster-workloads/
