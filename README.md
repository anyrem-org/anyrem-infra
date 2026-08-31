# AnyRem Infrastructure

Hạ tầng runtime dùng chung cho AnyRem. Repository này hiện quản lý Keycloak và các script vận hành backup.

## Keycloak

Keycloak chạy bằng Docker và dùng PostgreSQL trên host qua `host.docker.internal`.

```bash
cd keycloak
cp keycloak.env.example keycloak.env
# Điền secret và hostname production vào keycloak.env
./run.sh
```

Keycloak chỉ bind vào `127.0.0.1:9081` mặc định. Reverse proxy chịu trách nhiệm public HTTPS tại hostname đã cấu hình trong `keycloak.env`.

Dừng service:

```bash
cd keycloak
./stop.sh
```

Không commit `keycloak.env` hoặc bất kỳ file nào chứa secret.

## Backup

`backup/` chứa script shell, cron và installer cho backup production (Postgres + uploads volume). Upload lên object storage do `anyrem-be` thực hiện qua `dist/backup/backup.script.js`.

- Feature specification: `specs/features/013-backup/spec.md`
- Hướng dẫn vận hành: [backup/README.md](backup/README.md)

```bash
cd backup/scripts
sudo ./install-backup.sh
sudo /usr/local/bin/anyrem-db-backup.sh
sudo /usr/local/bin/anyrem-uploads-backup.sh
```

Trước khi bật cron production: deploy image backend mới nhất, chạy thử manual và restore drill (xem `backup/README.md`).

## Vận hành

- Thay đổi cấu hình hoặc script qua Git và deploy từ checkout repository; không sửa trực tiếp file script trên server.
- Secret chỉ nằm trong environment file trên server, ngoài Git.
- Trước khi bật lịch backup, chạy thử thủ công và restore thử cả database lẫn uploads.
