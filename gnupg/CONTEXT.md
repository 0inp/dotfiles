# GnuPG Module Context

## Purpose
Configuration for GnuPG (GNU Privacy Guard), a tool for secure communication and data storage.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `pubring.kbx`            | Public keyring                       | `~/.gnupg/pubring.kbx`             |
| `trustdb.gpg`            | Trust database                       | `~/.gnupg/trustdb.gpg`             |
| `private-keys-v1.d/`     | Private keys                         | `~/.gnupg/private-keys-v1.d/`      |

## Dependencies
- **GnuPG**: Install via Homebrew (`brew install gnupg`).

## Key Features
- **Key Management**: Import, export, and trust keys.
- **Encryption**: Encrypt/decrypt files and messages.
- **Signing**: Sign and verify signatures.

## AI Notes
- Focus on `pubring.kbx` and `trustdb.gpg` for key management.
- Private keys (`private-keys-v1.d/`) are **sensitive** — never modify directly.
- Test changes with `gpg --list-keys`.