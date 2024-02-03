#! /bin/sh

# set the binary name here and the code
# should be located at app/main.go; to build
# initiate from repo root with build/repo.sh

BINARY=project_name_goes_here

#
# -- careful with changes below here --
# 

BUILD=$PWD/build
INSTALL=$BUILD/install
INSTALLER=$BINARY.sh
PACKAGE=$BUILD/$BINARY.tgz
HISTORY=$BINARY.version
SERVICE=$BINARY.service
SYSTEMD=/etc/systemd/system
BIN=/usr/local/bin

# golang var embedded location for setting
# the Version,Build vars from the git repo
VARLOC=github.com/zxdev/env/v2

# remote user@host server configuration
SERVER=$1
if [[ ! "$SERVER" ]]; then 
    SERVERFILE=build/target.host
    if [ -e $SERVERFILE ]; then 
    SERVER=$(cat $SERVERFILE)
    fi
fi
HOST=
if [[ "$SERVER" ]]; then
    IFS='@' read -r -a ARRAY <<< "$SERVER"
    HOST=${ARRAY[1]}
fi

# create a working directory
if [ -e $INSTALL ]; then
    rm -fr $INSTALL
fi
mkdir $INSTALL

# generate streamlined golang binary
VERSION="$(git describe --tags `git rev-list --tags --max-count=1`)"
REVISION="$(git rev-parse HEAD)"
REVISION=${REVISION:0:12}
echo "VERSION $VERSION $REVISION"
echo "BUILD $BINARY, $SERVICE"
echo `date -u +%Y.%m.%d.%H.%M` $VERSION $REVISION $BINARY >> $INSTALL/$HISTORY
GOOS=linux GOARCH=amd64 go build \
-trimpath \
-ldflags "-s -w -X $VARLOC.Version=$VERSION -X $VARLOC.Build=$REVISION" \
-o $INSTALL/$BINARY app/main.go

# create systemd service
cat > $INSTALL/$SERVICE << EOF
[Unit]
Description= $BINARY service
Wants= network.target
After= network.target
[Service]
Environment= HOST=$(echo $SERVER | cut -d "@" -f 2)
ExecStart= /usr/local/bin/$BINARY
Restart= always
RestartSec= 1
KillSignal= SIGINT
TimeoutStopSec= 10
[Install]
WantedBy= multi-user.target
EOF

# create installer 
echo "BUILD $INSTALLER"
touch $INSTALL/$INSTALLER
chmod a+x $INSTALL/$INSTALLER
cat >> $INSTALL/$INSTALLER << EOF_HEAD
#! /bin/sh
INSTALL=install
INSTALLER=$INSTALLER
PACKAGE=$(basename $PACKAGE)
BINARY=$BINARY
HISTORY=$HISTORY
SYSTEMD=$SYSTEMD
SERVICE=$SERVICE
BIN=$BIN
ETC=/etc
EOF_HEAD

cat >> $INSTALL/$INSTALLER << 'EOF_BODY'
echo "install: $INSTALLER"
if [ -e $INSTALL ]; then
    sudo rm -fr $INSTALL
fi
tar -xzf $PACKAGE
sudo cp $INSTALL/$HISTORY $BIN
if [ -e $SYSTEMD/$SERVICE ]; then 
    sudo systemctl stop $SERVICE
    sudo cp $INSTALL/$BINARY $BIN
    sudo systemctl start $SERVICE
else 
    echo "install: systemd $SERVICE"
    sudo cp $INSTALL/$BINARY $BIN
    sudo cp $INSTALL/$SERVICE $SYSTEMD
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE
    sudo systemctl start $SERVICE
    exit
    sudo systemctl restart $SERVICE
fi
rm -fr $INSTALL $PACKAGE $INSTALLER
echo "install: complete"
EOF_BODY

# create the installer package
echo "BUILD $(basename $PACKAGE)"
tar -czf $PACKAGE -C $BUILD install
mv $PACKAGE $INSTALL/$(basename $PACKAGE)

# ship package, install it, and tidy up
if [[ "$SERVER" ]]; then 
    echo "TRANSMIT $INSTALLER $SERVER"
    scp $INSTALL/$(basename $PACKAGE) $SERVER:
    scp $INSTALL/$INSTALLER $SERVER:

    echo "RUN $SERVER $INSTALLER"
    ssh $SERVER "./$INSTALLER"

    echo "CLEANUP"
    rm -fr $INSTALL
fi

echo "bye"

