# Remove previous execution
CHANNEL_NAME=channel1 docker-compose -f docker-compose-cli.yaml down
docker rm -f $(docker ps -a -q)
docker volume rm $(docker volume ls -q)
rm -r ./channel-artifacts/
rm -r ./crypto-config/
sleep 2s

# Generate artifacts
cryptogen generate --config=./crypto-config.yaml
mkdir channel-artifacts
configtxgen -profile TwoOrgsOrdererGenesis --channelID system-channel -outputBlock ./channel-artifacts/genesis.block
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx --channelID channel1
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx --channelID channel1 -asOrg Org1MSP
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx --channelID channel1 -asOrg Org2MSP

sleep 10s

# Up network
CHANNEL_NAME=channel1 docker-compose -f docker-compose-cli.yaml up -d

sleep 10s

# Create channel and join peers
docker exec -it cli bash -c 'peer channel create -o orderer.example.com:7050 -c channel1 -f ./channel-artifacts/channel.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem'
docker exec -it cli bash -c 'peer channel join -b channel1.block'
docker exec -it cli bash -c 'peer channel update -o orderer.example.com:7050 -c channel1 -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem'
docker exec -it cli bash -c 'CORE_PEER_LOCALMSPID=Org2MSP CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=peer0.org2.example.com:7051 CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt peer channel join -b ./channel1.block'
docker exec -it cli bash -c 'CORE_PEER_LOCALMSPID=Org2MSP CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=peer0.org2.example.com:7051 CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt peer channel update -o orderer.example.com:7050 -c channel1 -f ./channel-artifacts/Org2MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem'