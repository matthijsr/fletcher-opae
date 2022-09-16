SOURCE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

docker build ${SOURCE} -f ${SOURCE}/developer_assets/Env.dockerfile -t fletcher_opae_env:latest --progress=plain
docker build ${SOURCE} -f ${SOURCE}/developer_assets/Fletcher.dockerfile -t fletcher_opae:latest --progress=plain