SOURCE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

docker build ${SOURCE} -f ${SOURCE}/developer_assets/Fletchgen.dockerfile -t fletcher_opae_generate:latest --progress=plain