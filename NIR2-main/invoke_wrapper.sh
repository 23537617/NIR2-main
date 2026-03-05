#!/bin/bash
peer chaincode invoke -C npa-channel -n taskdocument -c '{"function":"create_task","Args":["task1", "Verification Task", "Testing advanced features", "User1", "Creator1"]}' -o orderer0:7050 --waitForEvent --tls --cafile /etc/hyperledger/fabric/orderer-ca.pem --ordererTLSHostnameOverride orderer.example.com
