SOURCE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

docker build ${SOURCE} -f ${SOURCE}/developer_assets/Runtime_only.dockerfile -t fletcher_opae_runtime:latest --progress=plain