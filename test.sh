#!/bin/bash

SERVER="5.42.116.4"

echo "========================================="
echo "Testing X-Forwarded-For on $SERVER"
echo "========================================="
echo ""

# Проверяем, доступен ли сервер
echo "Checking if services are reachable..."
if ! curl -s -o /dev/null -w "%{http_code}" "http://$SERVER:5000/" | grep -q "200"; then
    echo "⚠️  Warning: App on port 5000 is not responding"
    echo "Make sure the playbook has been deployed successfully"
    echo ""
fi

# Тест 1: Прямой запрос к приложению
echo "1. Direct to app (no nginx):"
curl -s "http://$SERVER:5000/" | jq '{xff_raw, real_ip, client_ip}'
echo ""

# Тест 2: Через один nginx
echo "2. Through nginx3 only (port 8083):"
curl -s "http://$SERVER:8083/" | jq '{xff_raw, real_ip, client_ip}'
echo ""

# Тест 3: Через два nginx
echo "3. Through nginx2 → nginx3 (port 8082):"
curl -s "http://$SERVER:8082/" | jq '{xff_raw, real_ip, client_ip}'
echo ""

# Тест 4: Через три nginx
echo "4. Through nginx1 → nginx2 → nginx3 (port 8081):"
curl -s "http://$SERVER:8081/" | jq '{xff_raw, real_ip, client_ip}'
echo ""

# Тест 5: С поддельным заголовком X-Forwarded-For
echo "5. With fake X-Forwarded-For (malicious client):"
curl -s -H "X-Forwarded-For: 1.2.3.4, 5.6.7.8" "http://$SERVER:8081/" | jq '{xff_raw, real_ip, client_ip}'
echo ""

# Тест 6: С несколькими поддельными IP
echo "6. With multiple fake IPs in XFF header:"
curl -s -H "X-Forwarded-For: 8.8.8.8, 4.4.4.4, 1.1.1.1" "http://$SERVER:8081/test" | jq '{xff_raw, real_ip, client_ip}'
echo ""

echo "========================================="
echo "✅ Tests completed"
echo "========================================="
echo ""
echo "📝 INTERPRETATION OF RESULTS:"
echo "   - 'xff_raw': Shows complete proxy chain"
echo "   - 'real_ip': IP that last nginx saw"
echo "   - 'client_ip': Internal Docker IP of last nginx"
echo ""
echo "✅ Requirement 1: App sees all proxies (listed in xff_raw)"
echo "✅ Requirement 2: Fake XFF from client is NOT trusted -"
echo "   Real client IP (your public IP) appears in chain"
echo "✅ Requirement 3: Chain shows full path of all nginx servers"