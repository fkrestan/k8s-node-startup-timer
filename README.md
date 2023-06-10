# A questionable tool for measuring Kuberntetes Node startup time

Have you ever wondered how long it takes for a worker Node to startup in your
autoscaled cluster? Look no more! This janky tool will give you the answer!


# How does it work

This tool works by creating Pods big enough to force a creation of a new Node in
a Kubernetes cluster and measuring the time to the Pod startup. i.e. we assume
[cluster autoscaler][ca] or similar autoscaling setup.

The caveat is that you will need to size the Pod manually so that each test Pod
is guaranteed to get a new Node. Please take into account setups with
preemptible Pods (commonly overprovisioning/balloon Pods, ML/worker workloads).


# What's being measured exactly

The tool measures time between the testing Pod gets created in Kubernetes API to
a time it transitions to the "Running" state on a Node i.e. the Node is
"functionally ready".

Statistics measured are currently `p50`, `p80`, `p99`, `min`, `max` and `stddev`
but it should be easy enough to add any that interest you.

The resulting statistics are computed over configurable number of rounds.


# The setup

The manifest generators are written in a [jsonnet][jnt] language. To generate
the Kubernetes manifests from the jsonnet files and deploy those to Kubernetes
cluster the [Tanka][tk] tool is used.

This repository follows a [standard Tanka directory structure][tkd] located
under the `kubernetes/` directory. We've opted for the `spec.json` environment
configuration rather than the [inline environments][tki] to keep things simple.

This repository also uses [direnv][de] in combination with [nix shell][nix] to
deliver all tooling needed to successfully use this repository.

Yes, this is an overkill for something this simple. But it's the template that
we've had on hand.


# Usage

You'll need to configure the Kubernetes cluster in which you want to run the
experiment. This is done in `./kubernetes/environments/balloon/spec.json`.
Replace all the `PLACEHOLDER` values with appropriate ones.

Second you should configure the size of the balloon Pods used by this tool to be
big enough to always result in a new Node provisioning. This is done in
`./kubernetes/environments/balloon/main.jsonnet`.


```shell
$ make

# If there is a failure you can force clean up
$ make clean
```


# Notes

- The startup time of the test Pods should be minimal, but the delay of the
  image pull might be considerable. Consider using mirroring the image into your
  private registry used by the cluster.
- Curiously enough, it seems that Node startup time varies by AWS region. We
  recommend to test each region that you have a workload in.
- Different clusters will have different startup times. Things like cloudinit,
  kube-proxy configuration, CNI plugin used will all affect the startup time.
- The startup time you'll get is likely the typical one under normal cluster
  conditions. Expect wildly different numbers under high pressure conditions or
  conditions with multiple faults (e.g. AWS zone failure).
- Did you know that [JSON is valid YAML][jy]?


[ca]: https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler
[de]: https://direnv.net/
[jnt]: https://jsonnet.org/
[jy]: https://yaml.org/spec/1.2.2/#chapter-7-flow-style-productions
[nix]: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-shell.html
[tk]: https://tanka.dev/
[tkd]: https://tanka.dev/directory-structure
[tki]: https://tanka.dev/inline-environments
