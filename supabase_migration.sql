-- Создание таблицы для кодов восстановления пароля
CREATE TABLE IF NOT EXISTS password_recovery_codes (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    code VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT FALSE
);

-- Индекс для быстрого поиска по email и коду
CREATE INDEX IF NOT EXISTS idx_password_recovery_codes_email_code
ON password_recovery_codes (email, code);

-- Индекс для поиска неиспользованных кодов
CREATE INDEX IF NOT EXISTS idx_password_recovery_codes_used_expires
ON password_recovery_codes (used, expires_at);

-- Функция для автоматической очистки просроченных кодов (опционально)
-- Можно вызывать периодически или настроить как cron job
CREATE OR REPLACE FUNCTION cleanup_expired_recovery_codes()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM password_recovery_codes
    WHERE expires_at < NOW() OR used = TRUE;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Row Level Security (RLS) - включаем
ALTER TABLE password_recovery_codes ENABLE ROW LEVEL SECURITY;

-- Политика: пользователи могут видеть только свои коды
CREATE POLICY "Users can view their own recovery codes"
ON password_recovery_codes
FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Политика: только аутентифицированные пользователи могут вставлять коды
CREATE POLICY "Authenticated users can insert recovery codes"
ON password_recovery_codes
FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- Политика: только аутентифицированные пользователи могут обновлять коды
CREATE POLICY "Authenticated users can update recovery codes"
ON password_recovery_codes
FOR UPDATE
USING (auth.uid() IS NOT NULL);