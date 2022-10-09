package main

import (
	"fmt"

	"github.com/estlosan/hyperledger-custom-network/chaincode/voting/smart-contract"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

func main() {
	chaincode, err := contractapi.NewChaincode(&voting.SmartContract{})

	if err != nil {
		fmt.Printf("Error creating voting chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error creating voting chaincode: %s", err.Error())
		return
	}
}

