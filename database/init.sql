-- Povolení UUID rozšíření (standard pro bezpečné identifikátory)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Tabulka uživatelů
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- Pro přihlášení (např. Argon2)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- 2. Tabulka pro správu kryptografických klíčů uživatele
-- Uchovává veřejný klíč pro ostatní a zašifrovaný privátní klíč uživatele
CREATE TABLE user_keypairs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    public_key TEXT NOT NULL, -- Veřejný RSA klíč (Base64/PEM)
    encrypted_private_key TEXT NOT NULL, -- Privátní klíč zašifrovaný heslem uživatele (AES)
    salt VARCHAR(255) NOT NULL, -- Sůl použitá k odvození klíče pro zašifrování privátního klíče
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE, -- Pro případnou rotaci klíčů
    is_revoked BOOLEAN DEFAULT FALSE
);

-- 3. Tabulka pro samotné šifrované zprávy/data
CREATE TABLE encrypted_payloads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES users(id),
    encrypted_data TEXT NOT NULL, -- Samotná zpráva zašifrovaná symetricky (např. AES-GCM)
    iv TEXT NOT NULL, -- Inicializační vektor pro AES (Base64)
    digital_signature TEXT NOT NULL, -- Podpis senderova privátního klíče pro ověření integrity a původu
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabulka příjemců zpráv (Implementace Hybridního šifrování)
-- Zpráva je zašifrována jedním AES klíčem. Tento AES klíč je zde uložen tolikrát,
-- kolik je příjemců, pokaždé zašifrovaný veřejným RSA klíčem daného příjemce.
CREATE TABLE payload_recipients (
    payload_id UUID NOT NULL REFERENCES encrypted_payloads(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES users(id),
    encrypted_symmetric_key TEXT NOT NULL, -- AES klíč zprávy zašifrovaný veřejným RSA klíčem příjemce
    read_at TIMESTAMP WITH TIME ZONE, -- Kdy si příjemce zprávu přečetl
    PRIMARY KEY (payload_id, recipient_id)
);

-- 5. Auditní log (Nezbytné pro bezpečnostní aplikace)
CREATE TABLE security_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL, -- např. 'LOGIN_SUCCESS', 'KEY_REVOKED', 'MESSAGE_DECRYPTED'
    ip_address VARCHAR(45),
    details JSONB, -- Další metadata o události
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexy pro rychlejší vyhledávání
CREATE INDEX idx_user_keys_userid ON user_keypairs(user_id);
CREATE INDEX idx_payloads_sender ON encrypted_payloads(sender_id);
CREATE INDEX idx_audit_userid ON security_audit_logs(user_id);
