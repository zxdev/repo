# docker 
Jan 30 2024
to run intel image on Apple Silicon requires containerd active under experimental features

build using the dockerfile
```shell 
docker buildx build -t worker .
docker run --rm -p 1455:1455 --name containter_name containter_name
```

connect to running container wiht alpine
```shell
docker images ls
docker exec -it containter_name sh
```

transfer image to remote docker
```shell
docker save containter_name:latest | gzip | ssh user@host docker load

docker save -o containter_name.tgz containter_name
docker loag -i containter_name.tgz

```