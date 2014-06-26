# sandbox_curls.sh

1. GET TOKEN:
---------------------------
curl http://108.244.166.6:5000/v2.0/tokens -H 'Content-Type: application/json' -d '{"auth":{"tenantName": "sandbox", "passwordCredentials": {"username": "sandbox", "password": "sandbox"}}}'

2. GET Available Images:
---------------------------
curl http://108.244.166.6:9292/v1/images -H "X-Auth-Token: c3310fb1a3e94a9298582d8acd5654a1"