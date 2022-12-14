# Export Hyperledger Fabric tools
export PATH=$PATH:${PWD}/bin

. scripts/fabric-ca.sh
. scripts/utils.sh

function removePreviousExecution() {
    # Remove previous execution
    infoln "Removing previous execution"
    docker-compose -f docker-compose-cli.yaml down --volumes --remove-orphans 2>/dev/null
    docker-compose -f docker-compose-ca.yaml down --volumes --remove-orphans 2>/dev/null
    docker-compose -f docker-compose-tls-ca.yaml down --volumes --remove-orphans 2>/dev/null

    # Remove fabric ca artifacts
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf fabric-ca/org1.example.com/ca/*' 2>/dev/null
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf fabric-ca/org1.example.com/tls.ca/*' 2>/dev/null
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf fabric-ca/org2.example.com/ca/*' 2>/dev/null
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf fabric-ca/org2.example.com/tls.ca/*' 2>/dev/null
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf fabric-ca/orderer.example.com/ca/*' 2>/dev/null
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf fabric-ca/orderer.example.com/tls.ca/*' 2>/dev/null
    rm -rf ./channel-artifacts/ 2>/dev/null
    rm -rf ./crypto-config/ 2>/dev/null
    sleep 2s
}

function generateCryptoMaterials() {
    # Generate crypto materials
    infoln "Generating crypto materials"
    if [ ${CRYPTO_CONFIG} == "CA" ]; then
        # Generate artifacts using Fabric-ca
        generateTLSCryptoMaterials
        generateCaCryptoMaterials
        sleep 5s

    elif [ ${CRYPTO_CONFIG} == "Cryptogen" ]; then
        # Generate artifacts
        cryptogen generate --config=./crypto-config.yaml
    fi

    mkdir -p channel-artifacts
    configtxgen -profile TwoOrgsOrdererGenesis --channelID channel1 -outputBlock ./channel-artifacts/genesis_block.pb
    configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx --channelID channel1
    configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx --channelID channel1 -asOrg Org1MSP
    configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx --channelID channel1 -asOrg Org2MSP
    sleep 10s
}

function upDockerNetwork() {
    # Up network
    infoln "Network up"
    CHANNEL_NAME=channel1 docker-compose -f docker-compose-cli.yaml up -d
    sleep 10s
}

function createChannelAndJoin() {
    # Create channel1 and join orderer
    infoln "Creating channel1 and joining orderer"
    export OSN_TLS_CA_ROOT_CERT=${PWD}/crypto-config/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
    export ADMIN_TLS_SIGN_CERT=${PWD}/crypto-config/ordererOrganizations/example.com/users/Admin@example.com/tls/client.crt
    export ADMIN_TLS_PRIVATE_KEY=${PWD}/crypto-config/ordererOrganizations/example.com/users/Admin@example.com/tls/client.key
    osnadmin channel join --channelID channel1 --config-block ./channel-artifacts/genesis_block.pb -o localhost:7049 --ca-file $OSN_TLS_CA_ROOT_CERT --client-cert $ADMIN_TLS_SIGN_CERT --client-key $ADMIN_TLS_PRIVATE_KEY

    
    # Join peers
    infoln "Joining peers"
    docker exec -it cli bash -c 'peer channel join -b ./channel-artifacts/genesis_block.pb'
    #docker exec -it cli bash -c 'peer channel update -o orderer.example.com:7050 -c channel1 -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem'
    docker exec -it cli bash -c 'CORE_PEER_LOCALMSPID=Org2MSP CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=peer0.org2.example.com:7051 CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem peer channel join -b ./channel-artifacts/genesis_block.pb'
    #docker exec -it cli bash -c 'CORE_PEER_LOCALMSPID=Org2MSP CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=peer0.org2.example.com:7051 CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem peer channel update -o orderer.example.com:7050 -c channel1 -f ./channel-artifacts/Org2MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem'
}

function deployChaincode() {
    # Deploy chaincode
    infoln "Deploying chaincode"
    docker exec -it cli bash -c 'peer lifecycle chaincode package voting.tar.gz --path /opt/gopath/src/github.com/chaincode/voting/ --lang golang --label voting_1.0'
    docker exec -it cli bash -c 'peer lifecycle chaincode install voting.tar.gz'
    docker exec -it cli bash -c 'CORE_PEER_LOCALMSPID=Org2MSP CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=peer0.org2.example.com:7051 CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem peer lifecycle chaincode install voting.tar.gz'
    docker exec -it cli bash -c 'peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID channel1 --name voting --version 1.0 --package-id voting_1.0:9cd1e8c5f0e29fe5d4a45fddbfa539157d81629598d7f8c6a7d45a98c514e454 --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem'
    docker exec -it cli bash -c 'CORE_PEER_LOCALMSPID=Org2MSP CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=peer0.org2.example.com:7051 CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID channel1 --name voting --version 1.0 --package-id voting_1.0:9cd1e8c5f0e29fe5d4a45fddbfa539157d81629598d7f8c6a7d45a98c514e454 --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem'
    docker exec -it cli bash -c 'peer lifecycle chaincode checkcommitreadiness --channelID channel1 --name voting --version 1.0 --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem --output json'

    docker exec -it cli bash -c 'peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID channel1 --name voting --version 1.0 --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem'

    docker exec -it cli bash -c 'peer lifecycle chaincode querycommitted --channelID channel1 --name voting --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem'
    docker exec -it cli bash -c 'CORE_PEER_LOCALMSPID=Org2MSP CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=peer0.org2.example.com:7051 CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem peer lifecycle chaincode querycommitted --channelID channel1 --name voting --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem'

    docker exec -it cli bash -c "peer chaincode invoke -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem -C channel1 -n voting --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem -c '{\"Args\":[\"Set\",\"User1\", \"Voter1\"]}'"
    sleep 5s
    docker exec -it cli bash -c "peer chaincode query -C channel1 -n voting -c '{\"Args\":[\"Query\", \"User1\"]}'"
}

# Default values

# Crypto materials generation (Cryptogen or CA)
CRYPTO_CONFIG="Cryptogen";

# INIT
while [[ $# -gt 0 ]]; do
    option=$1
    case ${option} in
    -h )
        printHelp
        exit 0
        ;;
    -ca|--ca)
        CRYPTO_CONFIG="CA"
        shift # past argument
        ;;
    -down|--down)
        removePreviousExecution
        exit 0
        ;;
    * )
        errorln "Unknown flag: ${option}"
        printHelp
        exit 1
        ;;
    esac
done

removePreviousExecution
generateCryptoMaterials
upDockerNetwork
createChannelAndJoin
deployChaincode
