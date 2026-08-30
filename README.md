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

`backup/` là nơi lưu script và lịch backup production. Database production chạy native trên host; script DB dùng `pg_dump`, nén kết quả rồi upload qua image backend tới object storage.

Các script backup uploads, cron uploads và installer hiện mới là placeholder, nên chưa có backup uploads hoàn chỉnh. Không bật chúng ở production cho đến khi phần này được hoàn thiện và restore test thành công.

## Vận hành

- Thay đổi cấu hình hoặc script qua Git và deploy từ checkout repository; không sửa trực tiếp file script trên server.
- Secret chỉ nằm trong environment file trên server, ngoài Git.
- Trước khi bật lịch backup, chạy thử thủ công và restore thử cả database lẫn uploads.
