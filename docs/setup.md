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

## 5. GitHub Secrets 설정

CI/CD 자동 배포를 위해 GitHub 저장소 Settings → Secrets and variables → Actions 에서 아래 값을 등록합니다.

| Secret | 값 |
|--------|-----|
| `SSH_HOST` | 서버 공인 IP |
| `SSH_USERNAME` | `ubuntu` |
| `SSH_PRIVATE_KEY` | 인스턴스 생성 시 등록한 SSH 개인키 전체 내용 |

### GHCR 패키지 가시성 설정

GitHub Actions가 빌드한 이미지를 서버에서 pull하려면 패키지를 Public으로 설정해야 합니다.

```
GitHub → Packages → backend / frontend
  → Package settings → Change visibility → Public
```

---

## 6. 프로젝트 배포

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

| Variable | 설명 |
|----------|------|
| `JWT_SECRET` | 랜덤 시크릿 (예: `openssl rand -hex 32` 출력값) |
| `SERVER_IP` | 서버 공인 IP (Bytebase external-url에 사용) |

나머지 항목은 사용할 기능에 따라 선택 입력합니다 (소셜 로그인, 외부 API 등).

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

## 7. 접속 주소

| 서비스 | URL |
|--------|-----|
| Flutter Web / API | `http://<서버IP>` |
| Uptime Kuma | `http://<서버IP>:3001` |
| Dozzle | `http://<서버IP>:8888` |
| Bytebase | `http://<서버IP>:8889` |
