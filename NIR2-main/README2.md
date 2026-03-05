# Подробное руководство по ручному тестированию функционала (TypeScript Chaincode)

Данное руководство описывает полный цикл запуска сети Hyperledger Fabric и ручной проверки всех advanced-функций смарт-контракта (чейнкода), написанного на TypeScript.

---

## Часть 1: Запуск сети и развертывание чейнкода

Перед тестированием функционала необходимо поднять саму сеть Fabric, создать канал и задеплоить внешний чейнкод (Chaincode-as-a-Service).

### 1. Очистка и запуск блокчейн-сети
Перейдите в корневую папку проекта (`NIR2-main`) и выполните следующие команды установки:
```bash
# Очищаем старые данные (volumes), если сеть уже запускалась ранее
python network_setup.py clean

# Пересоздаем криптографические материалы и сертификаты
python generate_crypto_materials.py

# Запускаем все контейнеры сети (Orderer, Peers, CouchDB, CA)
python network_setup.py start
```
*Подождите примерно 15-20 секунд, чтобы все контейнеры полностью инициализировались, особенно Orderer и встроенные базы данных.*

### 2. Создание канала
Создаем канал `npa-channel` и присоединяем к нему пиры обеих организаций:
```bash
python channel_setup.py
```

### 3. Запуск сервера чейнкода (TypeScript)
Так как используется архитектура внешнего чейнкода, логика транзакций выполняется в отдельном контейнере.
```bash
cd chaincode

# Собираем и запускаем контейнер с TypeScript кодом
docker compose -f docker-compose.chaincode.yaml up -d --build chaincode-server
```

### 4. Регистрация чейнкода в сети (Деплой)
Чтобы пиры узнали о запущенном TypeScript сервере, регистрируем его:
```bash
python deploy_chaincode.py
```
После успешного выполнения вы увидите сообщение `Chaincode успешно развернут!`. Теперь сеть полностью готова к приему транзакций.

---

## Часть 2: Проверка бизнес-логики (Ручное тестирование)

Все проверки строятся на отправке транзакций напрямую в пир через CLI-команды `peer chaincode invoke` (запись) и `peer chaincode query` (чтение). Для того чтобы не прописывать длинные пути к сертификатам вручную, мы используем заготовленный скрипт `verify_features.sh` либо можем выполнять команды в терминале, предварительно экспортировав переменные среды.

### Подготовка терминала (Переменные среды)
Если вы тестируете вручную, вам необходимо экспортировать переменные среды для `Org1`.
Возвращаемся в корневую директорию проекта, если вы в папке chaincode:
```bash
cd ..
```

Выберите свой терминал:

**Для Linux / macOS / Git Bash:**
```bash
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ENABLED="true"
export CORE_PEER_MSPCONFIGPATH="/etc/hyperledger/fabric/admin-msp"
export CORE_PEER_ADDRESS="peer0.org1.example.com:7051"
export CORE_PEER_TLS_ROOTCERT_FILE="/etc/hyperledger/fabric/tls/ca.crt"

# Удобные переменные для вызова
export ORDERER_ARGS="-o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/orderer-ca.pem"
export PEER_ARGS="--peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/org1-tls-ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/org2-tls-ca.crt"
export CHAINCODE_ARGS="-C npa-channel -n taskdocument"
```

**Для Windows (PowerShell):**
```powershell
$env:CORE_PEER_LOCALMSPID = "Org1MSP"
$env:CORE_PEER_TLS_ENABLED = "true"
$env:CORE_PEER_MSPCONFIGPATH = "/etc/hyperledger/fabric/admin-msp"
$env:CORE_PEER_ADDRESS = "peer0.org1.example.com:7051"
$env:CORE_PEER_TLS_ROOTCERT_FILE = "/etc/hyperledger/fabric/tls/ca.crt"

# Удобные переменные для вызова
$env:ORDERER_ARGS = "-o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/orderer-ca.pem"
$env:PEER_ARGS = "--peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/org1-tls-ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/org2-tls-ca.crt"
$env:CHAINCODE_ARGS = "-C npa-channel -n taskdocument"
```

---

*Внимание: В командах тестирования ниже представлены два варианта синтаксиса использования переменных: для Linux (Bash) через `$ИМЯ` и для Windows (PowerShell) через `$env:ИМЯ`.*

### Тест 1: Базовое создание и идентификация (Client Identity)

Каждое создание задачи автоматически фиксирует параметры организатора благодаря библиотеке `fabric-shim` (`ctx.clientIdentity`).

**1. Создаем задачу:**
- **Linux:**
```bash
peer chaincode invoke $ORDERER_ARGS $CHAINCODE_ARGS $PEER_ARGS -c '{"function":"create_task","Args":["TASK_001","Подготовка отчета","Описание отчета","Petrov"]}'
```
- **Windows (PowerShell):**
```powershell
peer chaincode invoke $env:ORDERER_ARGS $env:CHAINCODE_ARGS $env:PEER_ARGS -c '{"function":"create_task","Args":["TASK_001","Подготовка отчета","Описание отчета","Petrov"]}'
```
*Обратите внимание: Метка времени (timestamp) берется из блокчейна, а создатель автоматически привязывается к вашему MSP ID.*

**2. Проверяем, что задача создалась:**
- **Linux:**
```bash
peer chaincode query $CHAINCODE_ARGS -c '{"function":"get_task","Args":["TASK_001"]}'
```
- **Windows (PowerShell):**
```powershell
peer chaincode query $env:CHAINCODE_ARGS -c '{"function":"get_task","Args":["TASK_001"]}'
```

---

### Тест 2: Проверка истории транзакций (History API)

Метод позволяет отследить весь жизненный путь изменения задачи:

**1. Меняем статус задачи на "В работе":**
- **Linux:**
```bash
peer chaincode invoke $ORDERER_ARGS $CHAINCODE_ARGS $PEER_ARGS -c '{"function":"update_task_status","Args":["TASK_001","IN_PROGRESS","Petrov"]}'
```
- **Windows:**
```powershell
peer chaincode invoke $env:ORDERER_ARGS $env:CHAINCODE_ARGS $env:PEER_ARGS -c '{"function":"update_task_status","Args":["TASK_001","IN_PROGRESS","Petrov"]}'
```

**2. Меняем статус задачи на "Завершено":**
- **Linux:**
```bash
peer chaincode invoke $ORDERER_ARGS $CHAINCODE_ARGS $PEER_ARGS -c '{"function":"update_task_status","Args":["TASK_001","DONE","Petrov"]}'
```
- **Windows:**
```powershell
peer chaincode invoke $env:ORDERER_ARGS $env:CHAINCODE_ARGS $env:PEER_ARGS -c '{"function":"update_task_status","Args":["TASK_001","DONE","Petrov"]}'
```

**3. Проверяем историю (History API):**
- **Linux:**
```bash
peer chaincode query $CHAINCODE_ARGS -c '{"function":"get_task_history","Args":["TASK_001"]}'
```
- **Windows:**
```powershell
peer chaincode query $env:CHAINCODE_ARGS -c '{"function":"get_task_history","Args":["TASK_001"]}'
```
*Вы должны увидеть JSON-массив, где каждая запись — это слепок состояния задачи в конкретный момент времени с ID транзакции (TxId).*

---

### Тест 3: Сложные селекторы CouchDB (Rich Query)

Rich Query позволяет искать записи в Ledger (реестре) по значениям полей JSON-объекта, а не только по ключу.

**1. Создаем несколько новых задач для одного исполнителя (Ivanov):**
- **Linux:**
```bash
peer chaincode invoke $ORDERER_ARGS $CHAINCODE_ARGS $PEER_ARGS -c '{"function":"create_task","Args":["TASK_002","Дизайн","Сделать UI","Ivanov"]}'
peer chaincode invoke $ORDERER_ARGS $CHAINCODE_ARGS $PEER_ARGS -c '{"function":"create_task","Args":["TASK_003","Бэкенд","Сделать API","Ivanov"]}'
```
- **Windows:**
```powershell
peer chaincode invoke $env:ORDERER_ARGS $env:CHAINCODE_ARGS $env:PEER_ARGS -c '{"function":"create_task","Args":["TASK_002","Дизайн","Сделать UI","Ivanov"]}'
peer chaincode invoke $env:ORDERER_ARGS $env:CHAINCODE_ARGS $env:PEER_ARGS -c '{"function":"create_task","Args":["TASK_003","Бэкенд","Сделать API","Ivanov"]}'
```

**2. Делаем запрос (поиск всех задач, где `assignee` = "Ivanov"):**
- **Linux:**
```bash
peer chaincode query $CHAINCODE_ARGS -c '{"function":"query_tasks","Args":["{\"selector\":{\"docType\":\"task\",\"assignee\":\"Ivanov\"}}", "10", ""]}'
```
- **Windows:**
```powershell
peer chaincode query $env:CHAINCODE_ARGS -c '{"function":"query_tasks","Args":["{\"selector\":{\"docType\":\"task\",\"assignee\":\"Ivanov\"}}", "10", ""]}'
```
*Результат вернёт обе задачи `TASK_002` и `TASK_003`, игнорируя при этом `TASK_001`, так как она назначена на Petrov.*

---

### Тест 4: Пагинация списков (Pagination)

При большом количестве задач важно не перегрузить сеть ответом. Проверим, как получить результаты по страницам.

**1. Делаем запрос с ограничением `page_size = 1`:**
- **Linux:**
```bash
peer chaincode query $CHAINCODE_ARGS -c '{"function":"query_tasks","Args":["{\"selector\":{\"docType\":\"task\",\"assignee\":\"Ivanov\"}}", "1", ""]}'
```
- **Windows:**
```powershell
peer chaincode query $env:CHAINCODE_ARGS -c '{"function":"query_tasks","Args":["{\"selector\":{\"docType\":\"task\",\"assignee\":\"Ivanov\"}}", "1", ""]}'
```
В конце вывода вы увидите поле `Bookmark`: длинную строку. Скопируйте её.

**2. Получаем вторую страницу (вставьте скопированную строку вместо `ВАША_ЗАКЛАДКА`):**
- **Linux:**
```bash
peer chaincode query $CHAINCODE_ARGS -c '{"function":"query_tasks","Args":["{\"selector\":{\"docType\":\"task\",\"assignee\":\"Ivanov\"}}", "1", "ВАША_ЗАКЛАДКА"]}'
```
- **Windows:**
```powershell
peer chaincode query $env:CHAINCODE_ARGS -c '{"function":"query_tasks","Args":["{\"selector\":{\"docType\":\"task\",\"assignee\":\"Ivanov\"}}", "1", "ВАША_ЗАКЛАДКА"]}'
```
*Благодаря закладке, CouchDB гарантированно продолжит поиск с места, на котором остановился, и вернёт вторую задачу `TASK_003`.*

---

### Тест 5: Версионирование документов

Эта функциональность позволяет привязать загружаемые документы к задаче (например, их хеши).

**1. Добавляем новую версию документа к задаче `TASK_001`:**
- **Linux:**
```bash
peer chaincode invoke $ORDERER_ARGS $CHAINCODE_ARGS $PEER_ARGS -c '{"function":"add_document_version","Args":["TASK_001", "DOC_100", "1.0", "hash_abc123", "Ivanov"]}'
```
- **Windows:**
```powershell
peer chaincode invoke $env:ORDERER_ARGS $env:CHAINCODE_ARGS $env:PEER_ARGS -c '{"function":"add_document_version","Args":["TASK_001", "DOC_100", "1.0", "hash_abc123", "Ivanov"]}'
```

**2. Добавляем вторую версию документа:**
- **Linux:**
```bash
peer chaincode invoke $ORDERER_ARGS $CHAINCODE_ARGS $PEER_ARGS -c '{"function":"add_document_version","Args":["TASK_001", "DOC_100", "1.1", "hash_def456", "Ivanov"]}'
```
- **Windows:**
```powershell
peer chaincode invoke $env:ORDERER_ARGS $env:CHAINCODE_ARGS $env:PEER_ARGS -c '{"function":"add_document_version","Args":["TASK_001", "DOC_100", "1.1", "hash_def456", "Ivanov"]}'
```

**3. Запрашиваем всю историю этого документа внутри задачи:**
- **Linux:**
```bash
peer chaincode query $CHAINCODE_ARGS -c '{"function":"get_document_versions","Args":["TASK_001","DOC_100"]}'
```
- **Windows:**
```powershell
peer chaincode query $env:CHAINCODE_ARGS -c '{"function":"get_document_versions","Args":["TASK_001","DOC_100"]}'
```
*Вы получите массив из двух версий документа (`1.0` и `1.1`), прикрепленных к задаче `TASK_001`.*

---

## Резюме проверок

Если у вас **Linux/Mac/Git Bash**, вы можете выполнить большинство этих тестов автоматически:
```bash
# Делает всё вышеперечисленное (History, Rich Query, Pagination) автоматически:
./verify_features.sh
```
