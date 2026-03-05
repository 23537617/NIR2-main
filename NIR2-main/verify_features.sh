#!/bin/bash
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/admin-msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt

ORDERER_ARGS="-o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/orderer-ca.pem"
PEER_ARGS="--peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/org1-tls-ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/org2-tls-ca.crt"
CHAINCODE_ARGS="-C npa-channel -n taskdocument"

echo ""
echo "=========================================="
echo "1. Testing History API"
echo "=========================================="
echo "-> Creating TASK_HIST"
peer chaincode invoke $ORDERER_ARGS $CHAINCODE_ARGS $PEER_ARGS -c '{"function":"create_task","Args":["TASK_HIST","Title","Desc","Petrov","Creator"]}'
sleep 3
echo "-> Updating TASK_HIST status to IN_PROGRESS"
peer chaincode invoke $ORDERER_ARGS $CHAINCODE_ARGS $PEER_ARGS -c '{"function":"update_task_status","Args":["TASK_HIST","IN_PROGRESS","Admin"]}'
sleep 3
echo "-> Querying History for TASK_HIST"
peer chaincode query $CHAINCODE_ARGS -c '{"function":"get_task_history","Args":["TASK_HIST"]}'

echo ""
echo "=========================================="
echo "2. Testing Rich Query"
echo "=========================================="
echo "-> Creating multiple tasks for Petrov"
peer chaincode invoke $ORDERER_ARGS $CHAINCODE_ARGS $PEER_ARGS -c '{"function":"create_task","Args":["TASK_RQ1","Title1","Desc1","Petrov","Creator"]}'
peer chaincode invoke $ORDERER_ARGS $CHAINCODE_ARGS $PEER_ARGS -c '{"function":"create_task","Args":["TASK_RQ2","Title2","Desc2","Petrov","Creator"]}'
sleep 4
echo "-> Querying all tasks where assignee = Petrov"
peer chaincode query $CHAINCODE_ARGS -c '{"function":"query_tasks","Args":["{\"selector\":{\"docType\":\"task\",\"assignee\":\"Petrov\"}}", "0", ""]}'

echo ""
echo "=========================================="
echo "3. Testing Pagination"
echo "=========================================="
echo "-> Querying first page of tasks for Petrov (size=1)"
OUTPUT=$(peer chaincode query $CHAINCODE_ARGS -c '{"function":"query_tasks","Args":["{\"selector\":{\"docType\":\"task\",\"assignee\":\"Petrov\"}}", "1", ""]}')
echo "$OUTPUT"

echo "-> Extracting bookmark and requesting next page"
BOOKMARK=$(echo $OUTPUT | grep -o '"bookmark":"[^"]*' | cut -d'"' -f4)
if [ ! -z "$BOOKMARK" ]; then
    echo "Using bookmark: $BOOKMARK"
    peer chaincode query $CHAINCODE_ARGS -c "{\"function\":\"query_tasks\",\"Args\":[\"{\\\"selector\\\":{\\\"docType\\\":\\\"task\\\",\\\"assignee\\\":\\\"Petrov\\\"}}\", \"1\", \"$BOOKMARK\"]}"
else
    echo "No bookmark found."
fi

echo ""
echo "=========================================="
echo "VERIFICATION COMPLETE"
echo "=========================================="
