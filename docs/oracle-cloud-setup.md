# Oracle Cloud 초기 서버 설정

## 1. 인스턴스 생성

```
Oracle Cloud 콘솔
  → Compute → Instances → Create Instance
  → Shape: Ampere A1 Flex (4 OCPU / 24GB RAM)
  → OS: Ubuntu 22.04
  → SSH Key: 공개키 등록
```

---

## 2. Security List 인바운드 규칙 추가

```
콘솔 → Networking → Virtual Cloud Networks
     → 해당 VCN → Security Lists → Default Security List
     → Add Ingress Rules
```

| 포트 | 프로토콜 | 용도 |
|------|---------|------|
| 22 | TCP | SSH (기본 등록됨) |
| 80 | TCP | nginx (Flutter Web + API) |
| 3001 | TCP | Uptime Kuma |
| 8888 | TCP | Dozzle |
| 8889 | TCP | Bytebase |

각 규칙 설정값:
```
Source Type: CIDR
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Destination Port: <포트번호>
```

---

## 3. 서버 초기 설정

### SSH 접속

```bash
ssh -i ~/.ssh/<키파일> ubuntu@<서버IP>
```

### 패키지 업데이트

```bash
sudo apt update && sudo apt upgrade -y
```

### Docker 설치

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
```

### Docker Compose 확인

```bash
docker compose version
```

---

## 4. OS 방화벽 (iptables) 포트 오픈

Oracle Cloud Ubuntu는 기본적으로 iptables가 활성화되어 있습니다.
Security List 설정만으로는 부족하며 OS 레벨에서도 열어야 합니다.

```bash
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 3001 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 8888 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 8889 -j ACCEPT
```

### 재시작 후에도 유지되도록 저장

```bash
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
```

---

## 5. 프로젝트 배포

### 저장소 클론

```bash
git clone https://github.com/SeoHyeokGyu/Mukzzi.git ~/mukzzi
cd ~/mukzzi
```

### 환경 변수 설정

```bash
cp .env.example .env
vi .env   # 각 값 입력
```

`.env` 필수 입력값:

```
JWT_SECRET=<랜덤 시크릿>
SERVER_IP=<서버 공인 IP>
```

### 실행

```bash
# 모바일 앱 백엔드 + DB
docker compose up -d

# Flutter Web 포함
docker compose --profile web up -d
```

### 실행 확인

```bash
docker compose ps
```

---

## 6. 접속 주소

| 서비스 | URL |
|--------|-----|
| Flutter Web / API | `http://<서버IP>` |
| Uptime Kuma | `http://<서버IP>:3001` |
| Dozzle | `http://<서버IP>:8888` |
| Bytebase | `http://<서버IP>:8889` |
