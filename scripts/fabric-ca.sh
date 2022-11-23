#!/bin/bash

function generateOrg1CryptoMaterials() {
    # Generate artifacts using fabric-ca
    mkdir -p crypto-config/peerOrganizations/org1.example.com/
    export FABRIC_CA_CLIENT_HOME=${PWD}/crypto-config/peerOrganizations/org1.example.com/
    fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca.org1.example.com --tls.certfiles ${PWD}/fabric-ca/org1.example.com/ca/ca-cert.pem
    echo 'NodeOUs:
    Enable: true
    ClientOUIdentifier:
        Certificate: cacerts/localhost-7054-ca-org1-example-com.pem
        OrganizationalUnitIdentifier: client
    PeerOUIdentifier:
        Certificate: cacerts/localhost-7054-ca-org1-example-com.pem
        OrganizationalUnitIdentifier: peer
    AdminOUIdentifier:
        Certificate: cacerts/localhost-7054-ca-org1-example-com.pem
        OrganizationalUnitIdentifier: admin
    OrdererOUIdentifier:
        Certificate: cacerts/localhost-7054-ca-org1-example-com.pem
        OrganizationalUnitIdentifier: orderer' > "${PWD}/crypto-config/peerOrganizations/org1.example.com/msp/config.yaml"

    # Peer register
    fabric-ca-client register --caname ca.org1.example.com --id.name peer0 --id.secret peer0pw --id.type peer --id.attrs '"hf.Registrar.Roles=peer"' --tls.certfiles ${PWD}/fabric-ca/org1.example.com/ca/ca-cert.pem

    # Peer enroll
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca.org1.example.com -M ${PWD}/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp --csr.hosts peer0.org1.example.com --tls.certfiles ${PWD}/fabric-ca/org1.example.com/ca/ca-cert.pem
    cp "${PWD}/crypto-config/peerOrganizations/org1.example.com/msp/config.yaml" "${PWD}/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/config.yaml"

    # Peer TLS
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca.org1.example.com -M ${PWD}/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls --enrollment.profile tls --csr.hosts peer0.org1.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/org1.example.com/ca/ca-cert.pem

    # User register
    fabric-ca-client register --caname ca.org1.example.com --id.name user1 --id.secret user1pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${PWD}/fabric-ca/org1.example.com/ca/ca-cert.pem

    # User enroll
    fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca.org1.example.com -M ${PWD}/crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp --tls.certfiles ${PWD}/fabric-ca/org1.example.com/ca/ca-cert.pem
    cp "${PWD}/crypto-config/peerOrganizations/org1.example.com/msp/config.yaml" "${PWD}/crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/config.yaml"

    # User TLS
    fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca.org1.example.com -M ${PWD}/crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com/tls --enrollment.profile tls --tls.certfiles ${PWD}/fabric-ca/org1.example.com/ca/ca-cert.pem

    # Admin register
    fabric-ca-client register --caname ca.org1.example.com --id.name org1admin --id.secret org1adminpw --id.type admin --id.attrs '"hf.Registrar.Roles=admin"' --tls.certfiles ${PWD}/fabric-ca/org1.example.com/ca/ca-cert.pem

    # Admin enroll
    fabric-ca-client enroll -u https://org1admin:org1adminpw@localhost:7054 --caname ca.org1.example.com -M ${PWD}/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp --tls.certfiles ${PWD}/fabric-ca/org1.example.com/ca/ca-cert.pem
    cp "${PWD}/crypto-config/peerOrganizations/org1.example.com/msp/config.yaml" "${PWD}/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/config.yaml"

    # Admin TLS
    fabric-ca-client enroll -u https://org1admin:org1adminpw@localhost:7054 --caname ca.org1.example.com -M ${PWD}/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/tls --enrollment.profile tls --tls.certfiles ${PWD}/fabric-ca/org1.example.com/ca/ca-cert.pem

    # Copy org1's CA cert to org1's /msp/tlscacerts directory (for use in the channel MSP definition)
    mkdir -p "${PWD}/crypto-config/peerOrganizations/org1.example.com/msp/tlscacerts"
    cp "${PWD}/fabric-ca/org1.example.com/ca/ca-cert.pem" "${PWD}/crypto-config/peerOrganizations/org1.example.com/msp/tlscacerts/ca.crt"

    # Copy org1's CA cert to org1's /tlsca directory (for use by clients)
    mkdir -p "${PWD}/crypto-config/peerOrganizations/org1.example.com/tlsca"
    cp "${PWD}/fabric-ca/org1.example.com/ca/ca-cert.pem" "${PWD}/crypto-config/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem"

    # Copy org1's CA cert to org1's /ca directory (for use by clients)
    mkdir -p "${PWD}/crypto-config/peerOrganizations/org1.example.com/ca"
    cp "${PWD}/fabric-ca/org1.example.com/ca/ca-cert.pem" "${PWD}/crypto-config/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem"

    # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
    cp "${PWD}/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/tlscacerts/"* "${PWD}/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    cp "${PWD}/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/signcerts/"* "${PWD}/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt"
    cp "${PWD}/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/keystore/"* "${PWD}/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key"
}

function generateOrg2CryptoMaterials() {
    # Generate artifacts using fabric-ca
    mkdir -p crypto-config/peerOrganizations/org2.example.com/
    export FABRIC_CA_CLIENT_HOME=${PWD}/crypto-config/peerOrganizations/org2.example.com/
    fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca.org2.example.com --tls.certfiles ${PWD}/fabric-ca/org2.example.com/ca/ca-cert.pem
    echo 'NodeOUs:
    Enable: true
    ClientOUIdentifier:
        Certificate: cacerts/localhost-8054-ca-org2-example-com.pem
        OrganizationalUnitIdentifier: client
    PeerOUIdentifier:
        Certificate: cacerts/localhost-8054-ca-org2-example-com.pem
        OrganizationalUnitIdentifier: peer
    AdminOUIdentifier:
        Certificate: cacerts/localhost-8054-ca-org2-example-com.pem
        OrganizationalUnitIdentifier: admin
    OrdererOUIdentifier:
        Certificate: cacerts/localhost-8054-ca-org2-example-com.pem
        OrganizationalUnitIdentifier: orderer' > "${PWD}/crypto-config/peerOrganizations/org2.example.com/msp/config.yaml"

    # Peer register
    fabric-ca-client register --caname ca.org2.example.com --id.name peer0 --id.secret peer0pw --id.type peer --id.attrs '"hf.Registrar.Roles=peer"' --tls.certfiles ${PWD}/fabric-ca/org2.example.com/ca/ca-cert.pem

    # Peer enroll
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca.org2.example.com -M ${PWD}/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp --csr.hosts peer0.org2.example.com --tls.certfiles ${PWD}/fabric-ca/org2.example.com/ca/ca-cert.pem
    cp "${PWD}/crypto-config/peerOrganizations/org2.example.com/msp/config.yaml" "${PWD}/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp/config.yaml"

    # Peer TLS
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca.org2.example.com -M ${PWD}/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls --enrollment.profile tls --csr.hosts peer0.org2.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/org2.example.com/ca/ca-cert.pem

    # User register
    fabric-ca-client register --caname ca.org2.example.com --id.name user1 --id.secret user1pw --id.type client --id.attrs '"hf.Registrar.Roles=client"' --tls.certfiles ${PWD}/fabric-ca/org2.example.com/ca/ca-cert.pem

    # User enroll
    fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca.org2.example.com -M ${PWD}/crypto-config/peerOrganizations/org2.example.com/users/User1@org2.example.com/msp --tls.certfiles ${PWD}/fabric-ca/org2.example.com/ca/ca-cert.pem
    cp "${PWD}/crypto-config/peerOrganizations/org2.example.com/msp/config.yaml" "${PWD}/crypto-config/peerOrganizations/org2.example.com/users/User1@org2.example.com/msp/config.yaml"

    # User TLS
    fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca.org2.example.com -M ${PWD}/crypto-config/peerOrganizations/org2.example.com/users/User1@org2.example.com/tls --enrollment.profile tls --tls.certfiles ${PWD}/fabric-ca/org2.example.com/ca/ca-cert.pem

    # Admin register
    fabric-ca-client register --caname ca.org2.example.com --id.name org2admin --id.secret org2adminpw --id.type admin --id.attrs '"hf.Registrar.Roles=admin"' --tls.certfiles ${PWD}/fabric-ca/org2.example.com/ca/ca-cert.pem

    # Admin enroll
    fabric-ca-client enroll -u https://org2admin:org2adminpw@localhost:8054 --caname ca.org2.example.com -M ${PWD}/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp --tls.certfiles ${PWD}/fabric-ca/org2.example.com/ca/ca-cert.pem
    cp "${PWD}/crypto-config/peerOrganizations/org2.example.com/msp/config.yaml" "${PWD}/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/config.yaml"

    # Admin TLS
    fabric-ca-client enroll -u https://org2admin:org2adminpw@localhost:8054 --caname ca.org2.example.com -M ${PWD}/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/tls --enrollment.profile tls --tls.certfiles ${PWD}/fabric-ca/org2.example.com/ca/ca-cert.pem

    # Copy org2's CA cert to org2's /msp/tlscacerts directory (for use in the channel MSP definition)
    mkdir -p "${PWD}/crypto-config/peerOrganizations/org2.example.com/msp/tlscacerts"
    cp "${PWD}/fabric-ca/org2.example.com/ca/ca-cert.pem" "${PWD}/crypto-config/peerOrganizations/org2.example.com/msp/tlscacerts/ca.crt"

    # Copy org2's CA cert to org2's /tlsca directory (for use by clients)
    mkdir -p "${PWD}/crypto-config/peerOrganizations/org2.example.com/tlsca"
    cp "${PWD}/fabric-ca/org2.example.com/ca/ca-cert.pem" "${PWD}/crypto-config/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem"

    # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
    cp "${PWD}/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/tlscacerts/"* "${PWD}/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
    cp "${PWD}/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/signcerts/"* "${PWD}/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.crt"
    cp "${PWD}/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/keystore/"* "${PWD}/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.key"
}

function generateOrdererCryptoMaterials() {
    # Generate artifacts using fabric-ca
    mkdir -p crypto-config/ordererOrganizations/example.com/
    export FABRIC_CA_CLIENT_HOME=${PWD}/crypto-config/ordererOrganizations/example.com/
    fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca.orderer.example.com --tls.certfiles ${PWD}/fabric-ca/orderer.example.com/ca/ca-cert.pem
    echo 'NodeOUs:
    Enable: true
    ClientOUIdentifier:
        Certificate: cacerts/localhost-9054-ca-orderer-example-com.pem
        OrganizationalUnitIdentifier: client
    PeerOUIdentifier:
        Certificate: cacerts/localhost-9054-ca-orderer-example-com.pem
        OrganizationalUnitIdentifier: peer
    AdminOUIdentifier:
        Certificate: cacerts/localhost-9054-ca-orderer-example-com.pem
        OrganizationalUnitIdentifier: admin
    OrdererOUIdentifier:
        Certificate: cacerts/localhost-9054-ca-orderer-example-com.pem
        OrganizationalUnitIdentifier: orderer' > "${PWD}/crypto-config/ordererOrganizations/example.com/msp/config.yaml"

    # Orderer register
    fabric-ca-client register --caname ca.orderer.example.com --id.name orderer --id.secret ordererpw --id.type orderer --id.attrs '"hf.Registrar.Roles=orderer"' --tls.certfiles ${PWD}/fabric-ca/orderer.example.com/ca/ca-cert.pem

    # Orderer enroll
    fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca.orderer.example.com -M ${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/orderer.example.com/ca/ca-cert.pem
    cp "${PWD}/crypto-config/ordererOrganizations/example.com/msp/config.yaml" "${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml"

    # Orderer TLS
    fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca.orderer.example.com -M ${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls --enrollment.profile tls --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/orderer.example.com/ca/ca-cert.pem

    # Admin register
    fabric-ca-client register --caname ca.orderer.example.com --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --id.attrs '"hf.Registrar.Roles=admin"' --tls.certfiles ${PWD}/fabric-ca/orderer.example.com/ca/ca-cert.pem

    # Admin enroll
    fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca.orderer.example.com -M ${PWD}/crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp --tls.certfiles ${PWD}/fabric-ca/orderer.example.com/ca/ca-cert.pem
    cp "${PWD}/crypto-config/ordererOrganizations/example.com/msp/config.yaml" "${PWD}/crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/config.yaml"

    # Admin TLS
    fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca.orderer.example.com -M ${PWD}/crypto-config/ordererOrganizations/example.com/users/Admin@example.com/tls --enrollment.profile tls --tls.certfiles ${PWD}/fabric-ca/orderer.example.com/ca/ca-cert.pem

    # Copy orderer's CA cert to orderer's /msp/tlscacerts directory (for use in the channel MSP definition)
    mkdir -p "${PWD}/crypto-config/ordererOrganizations/example.com/msp/tlscacerts"
    cp "${PWD}/fabric-ca/orderer.example.com/ca/ca-cert.pem" "${PWD}/crypto-config/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

    # Copy orderer's CA cert to orderer's /tlsca directory (for use by clients)
    mkdir -p "${PWD}/crypto-config/ordererOrganizations/example.com/tlsca"
    cp "${PWD}/fabric-ca/orderer.example.com/ca/ca-cert.pem" "${PWD}/crypto-config/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem"

    cp "${PWD}/crypto-config/ordererOrganizations/example.com/msp/config.yaml" "${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml"

    # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
    cp "${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/"* "${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"
    cp "${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/signcerts/"* "${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt"
    cp "${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/keystore/"* "${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key"

    # Copy orderer org's CA cert to orderer's /msp/tlscacerts directory (for use in the orderer MSP definition)
    mkdir -p "${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts"
    cp "${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/"* "${PWD}/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
}

#generateOrg1CryptoMaterials
#generateOrg2CryptoMaterials
#generateOrdererCryptoMaterials