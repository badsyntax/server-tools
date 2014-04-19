# MIGRATE

### Snippets

Rsync files:

```
rsync -chavzP -e 'ssh -p 2227' --stats --progress local-folder user@host:/path/to/dest/
```
