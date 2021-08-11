#!/usr/bin/env bash
set -e

while getopts v: flag
do
    case "${flag}" in
        v) version=${OPTARG};;
    esac
done

echo $version

./build.sh -c ./config/prod.json

rm -rf ./package
mkdir -p package

echo "{
  \"name\": \"@maplelabs/treasury\",
  \"version\": \"${version}\",
  \"description\": \"Treasury Artifacts and ABIs\",
  \"author\": \"Maple Labs\",
  \"license\": \"AGPLv3\",
  \"repository\": {
    \"type\": \"git\",
    \"url\": \"https://github.com/maple-labs/treasury.git\"
  },
  \"bugs\": {
    \"url\": \"https://github.com/maple-labs/treasury/issues\"
  },
  \"homepage\": \"https://github.com/maple-labs/treasury\"
}" > package/package.json

mkdir -p package/artifacts
mkdir -p package/abis

cat ./out/dapp.sol.json | jq '.contracts | ."contracts/MapleTreasury.sol" | .MapleTreasury' > package/artifacts/MapleTreasury.json
cat ./out/dapp.sol.json | jq '.contracts | ."contracts/MapleTreasury.sol" | .MapleTreasury | .abi' > package/abis/MapleTreasury.json

npm publish ./package --access public

rm -rf ./package
