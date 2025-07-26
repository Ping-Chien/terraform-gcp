import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
    vus: 10, // 虛擬使用者數量，可依需求調整
    iterations: 100, // 總請求數量，可依需求調整
};

let baseId = 2; // 起始 id

export default function () {
    let id = baseId + __ITER; // 每次請求 id 遞增
    let url = 'http://104.199.150.203/submit';
    let payload = JSON.stringify({
        url: "http://dotnet-backend-service.default.svc.cluster.local:8080/employees",
        name: "chen",
        tel: "0987654321",
        id: id
    });

    let params = {
        headers: {
            'Content-Type': 'application/json',
        },
    };

    let res = http.post(url, payload, params);

    check(res, {
        'status is 200': (r) => r.status === 200,
    });

    sleep(1); // 每個虛擬使用者間隔 1 秒
}
