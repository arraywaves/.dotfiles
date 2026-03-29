# Licence Options

Present these choices when the user hasn't specified a licence. Give a one-line summary for each.

## Common Options

| Licence | Best for | Key point |
|---|---|---|
| **MIT** | Most projects | Do whatever you want, just keep the copyright notice. Most permissive, most popular. |
| **Apache 2.0** | Libraries / enterprise | Like MIT but adds explicit patent grant — better for corporate use. |
| **GPL-3.0** | Tools / CLIs | Copyleft — anyone using your code must also open-source their project under GPL. |
| **UNLICENSED** | Private / personal work | No permissions granted to anyone. Use when the repo is public but not open-source. |

## Badge Snippets

Replace `USERNAME/REPO` with the actual slug.

```
![License](https://img.shields.io/github/license/USERNAME/REPO)
```

This badge auto-detects the licence from the repo — it works as long as a `LICENSE` file is present.

## Licence Text in README Footer

```markdown
## License

Distributed under the [MIT License](./LICENSE).
```

```markdown
## License

Distributed under the [Apache 2.0 License](./LICENSE).
```

```markdown
## License

Distributed under the [GPL-3.0 License](./LICENSE).
```

```markdown
## License

This project is private and unlicensed. All rights reserved.
```
