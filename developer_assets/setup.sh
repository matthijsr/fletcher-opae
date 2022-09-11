docker build . -f Env.dockerfile -t fletcher_opae_env:latest
docker build . -f Fletcher.dockerfile -t fletcher_opae:latest