RELEASEDIR=releases
DATESTAMP=$(date +%Y%m%d)
LOGSTAMP=$(git log --pretty=format:'%h' -n 1)

if [ "$LOGSTAMP" -eq "0" ]; then
  echo "Couldn't get Git log"
  exit 1
fi

TAG=$DATESTAMP-0.$LOGSTAMP

BUILDS=(
  # FORMAT
  # GOOS GOARCH BINSUFFIX
  # "darwin 386 darwin-i386-$TAG.prod"
  # "darwin amd64 darwin-amd64-$TAG.prod"
  "linux 386 linux-i386-$TAG.prod"
  "linux amd64 linux-amd64-$TAG.prod"
  # "windows 386 windows-i386-$TAG.prod.exe"
  # "windows amd64 windows-amd64-$TAG.prod.exe"
)


# update_releases invokes the update_release_json tool to record an agent update.
# It expects to be called with the following arguments:
# 1. The path to the releases.json file to update,
# 2. The component to update,
# 3. The tag for the new release and
# 4. The path to the new agent binary.
function update_releases() {
  releasejson=$(go run tools/update-release-json.go \
    -releases $RELEASEDIR/$1 \
    -component $2 \
    -tag $3 \
    -binary $4 \
    -sha256 $(cat $RELEASEDIR/$4 | openssl sha256))

  echo "$releasejson" > $RELEASEDIR/$1
}


for build in "${BUILDS[@]}"; do
  IFS=" " read -ra args <<< "$build"

  echo "Building an agent for ${args[0]}/${args[1]}"
  GOOS=${args[0]} GOARCH=${args[1]} go build -o $RELEASEDIR/mig-agent-${args[2]} github.com/mozilla/mig/mig-agent
  if [ $? -eq 0 ]; then
    echo "+ Build succeeded"
    update_releases releases.json agent $TAG mig-agent-${args[2]}
  else
    echo "- Build failed";
  fi

  echo "Building an agentConfig tool for ${args[0]}/${args[1]}"
  GOOS=${args[0]} GOARCH=${args[1]} go build -o $RELEASEDIR/mig-agent-cfg-${args[2]} tools/mig-agent-cfg.go
  if [ $? -eq 0 ]; then
    echo "+ Build succeeded"
    update_releases releases.json agentConfig $TAG mig-agent-cfg-${args[2]}
  else
    echo "- Build failed";
  fi
done
