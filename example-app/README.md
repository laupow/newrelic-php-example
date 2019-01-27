### Example Application

This Dockerfile builds an example PHP application container with the New Relic PHP Agent installed.

Running the container alone _will not_ connect to your New Relic account. 

The configuration of the New Relic Agent and Daemon is handled by Kubernetes configs. It's not part of the Docker build. 

You'll need to deploy this container into a Kubernetes cluster using the config in this repo.
