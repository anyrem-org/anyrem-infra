# AnyRem Production Backup

Script và lịch backup cho VPS production. Feature specification: `specs/features/013-backup/spec.md`.

## Layout

```text
backup/
├── cron/
│   ├── anyrem-db-backup.cron       # lịch backup database
│   └── anyrem-uploads-backup.cron  # lịch backup uploads volume
└── scripts/
    ├── db-backup.sh                # pg_dump → upload R2
    ├── uploads-backup.sh           # tar volume → upload R2
    └── install-backup.sh           # cài script + cron lên host
```

## Prerequisites

- Postgres chạy native trên host; `pg_dump` có sẵn trên PATH.
- Docker: network `anyrem_network`, volume `anyrem_uploads`, image `.../anyrem-be:latest` (hoặc override `IMAGE`).
- `/opt/anyrem-be/.env.production` với:
  - `BACKUP_DATABASE_URL` hoặc `DATABASE_URL`
  - `OBJECT_STORAGE_ENDPOINT`, `OBJECT_STORAGE_ACCESS_KEY_ID`, `OBJECT_STORAGE_SECRET_ACCESS_KEY`, `OBJECT_STORAGE_BUCKET`
  - `REDIS_URL`, `TELEGRAM_BOT_TOKEN`, `PRODUCT_DEPLOY_TELEGRAM_ID`
- Container `anyrem-be-worker` đang chạy (Telegram notify).

## Install

Trên VPS, từ checkout `anyrem-infra`:

```bash
cd backup/scripts
sudo ./install-backup.sh
```

Cài:

- `/usr/local/bin/anyrem-db-backup.sh`
- `/usr/local/bin/anyrem-uploads-backup.sh`
- `/etc/cron.d/anyrem-db-backup`
- `/etc/cron.d/anyrem-uploads-backup`

## Schedule

| Job      | Cron                                      | Log                                  |
| -------- | ----------------------------------------- | ------------------------------------ |
| Database | `0 3 * * *` (03:00, timezone của server)  | `/var/log/anyrem-db-backup.log`      |
| Uploads  | `15 9 * * *` (09:15, timezone của server) | `/var/log/anyrem-uploads-backup.log` |

Uploads chạy sau DB để tránh contention I/O lúc dump.

## Manual run

```bash
sudo /usr/local/bin/anyrem-db-backup.sh
sudo /usr/local/bin/anyrem-uploads-backup.sh
```

Override tạm thời:

```bash
ENV_FILE=/path/to/.env.production IMAGE=vunavu/anyrem-be:latest sudo -E /usr/local/bin/anyrem-db-backup.sh
```

## Object storage keys

Date theo UTC (`backup.keys.ts` trong `anyrem-be`):

| Loại     | Key                          |
| -------- | ---------------------------- |
| Database | `db/daily/YYYY-MM-DD.sql.gz` |
| Uploads  | `uploads/YYYY-MM-DD.tar.gz`  |

## Deploy order (đổi tên script hoặc image mới)

1. Deploy image `anyrem-be` mới (phải có `dist/backup/backup.script.js`).
2. Pull `anyrem-infra` và chạy lại `install-backup.sh`.
3. Chạy thử manual cả hai script trước khi chờ cron.

Cập nhật script trên VPS **trước** image mới sẽ gây lỗi `Cannot find module dist/backup/backup.script.js`.

## Restore drill

### Database

```bash
# Tải db/daily/YYYY-MM-DD.sql.gz từ object storage về /tmp/restore.sql.gz
gunzip -c /tmp/restore.sql.gz | psql "$BACKUP_DATABASE_URL"
```

### Uploads

```bash
# Tải uploads/YYYY-MM-DD.tar.gz về /tmp/restore.tar.gz
docker run --rm \
  -v anyrem_uploads:/data \
  -v /tmp/restore.tar.gz:/restore.tar.gz:ro \
  alpine:3.21 \
  sh -c "rm -rf /data/* && tar -xzf /restore.tar.gz -C /data"
```

Sau restore: `pnpm search:reindex` trong container backend; mở note có ảnh để kiểm tra URL `/uploads/note-images/...`.

## Troubleshooting

| Triệu chứng                               | Kiểm tra                                                |
| ----------------------------------------- | ------------------------------------------------------- |
| `Cannot find module ... backup.script.js` | Image backend chưa build/deploy sau đổi tên script      |
| Upload OK, không có Telegram              | Worker không chạy hoặc thiếu `REDIS_URL` / Telegram env |
| `403` object storage                      | Sai `OBJECT_STORAGE_*` hoặc token không quyền bucket    |
| Ảnh 404 sau restore DB                    | Chưa restore volume uploads hoặc tar sai cấu trúc path  |
