# Hyperledger Fabric Custom Network

This is a hyperledger custom network with a set of scripts to generate artifacts, create channels, deploy chaincode and up the network spawn a docker-compose. This saves time for a developer to build a network without making any possible mistake. Besides this network helps developers to concentrate more on the smart contract writing and developing other integration parts rather than concentrating on the infrastructure part. The default network consists of 2 Organizations with 1 peer each organization.


## Table of Contents

- [🛠️ Pre-requisites](#🛠️-prequisites)
- [👨‍💻 Installation](#👨‍💻-getting-started)
  - [Install Dependencies](#installation)
- [▶️ Creating and running a custom network](#▶️-creating-and-running-a-custom-network)
  - [Preparing the network](#preparing-the-network)  
  - [Generate Hyperledger Fabric key materials](#generate-hyperledger-fabric-key-materials)  
  - [Generate channel artifacts and anchor peers configuration](#generate-channel-artifacts-and-anchor-peers-configuration)  
  - [Launch the network](#launch-the-network)  
  - [CLI conexion to peer](#cli-conexion-to-peer)  
  - [Channel creation](#channel-creation)  
  - [Deploy chaincode](#deploy-chaincode)

## 🛠️ Prerequisites

- Docker-compose: 20.10.7
- Go: 1.16.7
- Fabric 2.4.x

## 👨‍💻 Getting-started

### Installation

1. Clone this repository
2. Build using 
    ```sh
    cd <path to source code directory>/chaincode/voting
    go get
    cd ./../..
    ```
3. Modify `crypto-config.yaml` with your custom network values.
4. Modify `configtx.yaml` with your custom network values.


## ▶️ Creating and running a custom network

The code to configure and launch the network is located in `init.sh`. Next steps are only needed if you want to understand what is happening under the hood.

### Preparing the network

Before launching the network cryptographic materials need to be created

### Generate Hyperledger Fabric key materials 

```sh
cryptogen generate --config=./crypto-config.yaml
```

### Generate channel artifacts and anchor peers configuration

```sh
mkdir channel-artifacts
configtxgen -profile TwoOrgsOrdererGenesis --channelID system-channel -outputBlock ./channel-artifacts/genesis.block
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx --channelID channel1
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx --channelID channel1 -asOrg Org1MSP
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx --channelID channel1 -asOrg Org2MSP
```

### Launch the network

After all cryptographic material are created, custom network may be doployed

```sh
CHANNEL_NAME=channel1 docker-compose -f docker-compose-cli.yaml up -d
```

### CLI conexion to peer

Once network is deployed you need to connect to the peers using CLI docker container

```sh
docker exec -it cli bash
```

### Channel creation 

Channel creation and join with org1 peer
```sh
# Org1 peer
peer channel create -o orderer.example.com:7050 -c channel1 -f ./channel-artifacts/channel.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem 

peer channel join -b channel1.block

peer channel update -o orderer.example.com:7050 -c channel1 -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

Channel join with org2 peer
```sh
# Org2 peer
CORE_PEER_LOCALMSPID=Org2MSP CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=peer0.org2.example.com:7051 CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt peer channel join -b ./channel1.block

CORE_PEER_LOCALMSPID=Org2MSP CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=peer0.org2.example.com:7051 CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt peer channel update -o orderer.example.com:7050 -c channel1 -f ./channel-artifacts/Org2MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem
``` 

### Deploy chaincode

When channel creation is finished and peers are joined you can deploy the chaincode

Package chaincode
```sh
peer lifecycle chaincode package voting.tar.gz --path /opt/gopath/src/github.com/chaincode/voting/ --lang golang --label voting_1.0
```

Install chaincode on org1 peer
```sh
# Org1 peer
peer lifecycle chaincode install voting.tar.gz
```

Install chaincode on org2 peer
```sh
# Org2 peer
CORE_PEER_LOCALMSPID=Org2MSP CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=peer0.org2.example.com:7051 CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt peer lifecycle chaincode install voting.tar.gz
```

Approve chaincode terms on org1 peer
```sh
# Org1 peer
peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID channel1 --name voting --version 1.0 --package-id voting_1.0:9cd1e8c5f0e29fe5d4a45fddbfa539157d81629598d7f8c6a7d45a98c514e454 --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
``` 

Approve chaincode terms on org2 peer
```sh
# Org2 peer
ORE_PEER_LOCALMSPID=Org2MSP CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=peer0.org2.example.com:7051 CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID channel1 --name voting --version 1.0 --package-id voting_1.0:9cd1e8c5f0e29fe5d4a45fddbfa539157d81629598d7f8c6a7d45a98c514e454 --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
``` 

Check whether channel members have approved the same chaincode definition
```sh
peer lifecycle chaincode checkcommitreadiness --channelID channel1 --name voting --version 1.0 --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --output json
```

```json
{
    "Approvals": {
        "Org1MSP": true,
        "Org2MSP": true
    }
}
```

Commit chaincode to channel
```sh
peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID channel1 --name voting --version 1.0 --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
```

Check if chaincode definition has been commited to the channel
```sh
peer lifecycle chaincode querycommitted --channelID channel1 --name voting --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```
```
Committed chaincode definition for chaincode 'voting' on channel 'channel1':
Version: 1.0, Sequence: 1, Endorsement Plugin: escc, Validation Plugin: vscc, Approvals: [Org1MSP: true, Org2MSP: true]
```