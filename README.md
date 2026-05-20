# 🔐 SecureMessageVault API

> Advanced database schema and architecture for an End-to-End Encrypted messaging and file-sharing platform. Built upon concepts from [DataProtectionWithDigitalSignature](https://github.com/baartys/DataProtectionWithDigitalSignature).

## 🚀 Features

- **Hybrid Encryption Model:** Combines the speed of AES-GCM for large payloads with the security of RSA for key distribution.
- **Digital Signatures:** Non-repudiation and integrity checks natively supported in the database schema.
- **Zero-Knowledge Architecture:** Private keys are stored in the database but are symmetrically encrypted by the user's password hash. The server cannot read them.
- **Audit Logging:** Built-in JSONB audit trails for security monitoring.

## 🗄️ Database Schema Overview

The system uses PostgreSQL. The core logic relies on separating the payload from the keys:
1. `users` - Identity management.
2. `user_keypairs` - Public and encrypted Private keys.
3. `encrypted_payloads` - AES encrypted data and digital signatures.
4. `payload_recipients` - Symmetric keys encrypted with the recipient's public RSA key.
5. `security_audit_logs` - Action tracking.

## 🛠️ Quick Start (Docker)

You can spin up the PostgreSQL database and pgAdmin interface using Docker Compose.

```bash
docker-compose up -d
Database: localhost:5432 (User: vaultadmin, DB: securevault)

pgAdmin: http://localhost:5050 (Login: admin@securevault.local)

💡 How it works (Encryption Flow)
Sender generates a random AES key and encrypts the message.

Sender signs the encrypted payload with their Private RSA Key.

Sender fetches the Public RSA Key of the Recipient.

Sender encrypts the random AES key using the Recipient's Public RSA Key.

Both the Encrypted Payload and Encrypted AES key are stored in the database.
