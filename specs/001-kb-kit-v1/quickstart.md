# Quickstart: kb-kit v1

## New repository (5 minutes)

```bash
git clone <kb-kit-repo> ~/tools/kb-kit
cd ~/my-project
~/tools/kb-kit/kb-init.sh              # scaffolds kb/ (KB.md, INBOX.md), .kb/, .claude/skills/kb-*
claude                                  # any Claude Code session, fresh is fine
```

Then, inside the session:

```text
/kb-add вот транскрипт звонка с клиентом X: <вставленный текст>
# → отчёт: создан kb/clients/x-call-2026-07-06.md, строка в INDEX.md, связи

/kb-ask что клиент X говорил про цены?
# → ответ с цитатами: clients/x-call-2026-07-06.md: "точная реплика…"

/kb-check      # гигиена: битые ссылки, сироты, дрейф индексов
/kb-audit      # семантика: противоречия, дубли, устаревшее (по подтверждению — метки)
/kb-viz        # kb-graph.html — открой в браузере, работает офлайн
```

## Existing corpus (migration, no files moved)

```bash
cd ~/my-project-with-docs
~/tools/kb-kit/kb-init.sh --migrate docs/
# → docs/MIGRATION_REPORT.md: найденные темы, индексы, конвенции
claude
```

```text
/kb-init docs/
# читает отчёт + ваши README, формализует ВАШИ конвенции в правила тем,
# усыновляет существующие индексы; показывает план; применяет после подтверждения.
# Ни один существующий файл не перемещается и не переименовывается.
```

## Install a pack

```bash
~/tools/kb-kit/kb-init.sh --pack sources   # встроенный пак «библиотека источников»
```

## Weekly rhythm (the discipline, automated)

1. Кидай сырьё в течение недели: `/kb-add …` или строки в `kb/INBOX.md`.
2. Раз в неделю: `/kb-add разбери INBOX` → всё разложено, индексы обновлены.
3. Раз в месяц: `/kb-check`, затем `/kb-audit` — база чинится и размечается.
4. Вопросы — в любой свежей сессии: `/kb-ask …` с цитатами и путями к файлам.
