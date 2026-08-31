# rust-skills-comprehensive 開発ワークフロー

**最終更新:** 2026-08-29
**対象:** `rust-skills-comprehensive` — Comprehensive Rustから派生したClaude Code skill集

この文書は、このリポジトリでskillの追加・更新・`install.sh`の変更を行う際に、内容と
distribution、attributionのずれを防ぐための手順を定義する。このリポジトリはコードでは
なくClaude Code skill（`SKILL.md` + 付随ファイル）を配布するcontentリポジトリであり、
自動テストの対象はshellcheck・frontmatter/line budget検証・`install.sh`のsmoke testに
限られる（`.github/workflows/ci.yml`）。skillの内容自体の品質保証は`/skill-stocktake`と
手動trigger testで行う。

## 1. Source of truth

作業前に次の順で確認する。

1. [`docs/PLAN.md`](PLAN.md) — skillカタログ設計、モジュールsizing、build順序、Status log
2. [`docs/FILE_MAP.md`](FILE_MAP.md) — upstream courseの約450ページのtopic別index
3. [README](../README.md) — 配布されているskill一覧、install手順、repository layout
4. 各`skills/<name>/SKILL.md` — 現在の内容と`source:`frontmatterのpin

`docs/PLAN.md`はこのリポジトリの設計ドキュメントであり、GitHub Issueへの移行はしていない。
新しい作業はまず`docs/PLAN.md`のStatus節に記録する。

PLANとskill本文が矛盾する場合、実装者の判断だけでどちらかを変更しない。特に次の契約は、
明示的な確認なしに緩和しない。

- skillの内容はupstream Comprehensive Rustの`source:`pinから逸脱しない。加筆・言い換えを
  超える主張（upstreamにない技術的結論）を追加しない
- 各`SKILL.md`はCC-BY-4.0（本文）/ Apache-2.0（コード例）のattributionを
  frontmatterの`source:`に保持する
- 1 skill = 1 job（"診断する/設計する/実装する"）であり、`rust-patterns`が既に screen 1枚で
  答えられる内容と重複させない（`docs/PLAN.md`の delineation ruleを参照）
- `SKILL.md`は目安200行〜500行の予算を超えない。超える場合は`references/*.md`へ分割する
- `ref/comprehensive-rust/`（gitignore対象、vendored course）はリポジトリに含めない
- `.claude/skills/*`は`skills/*`へのsymlinkのまま保つ（配布物との二重管理を避ける）

## 2. 作業を選ぶ

`docs/PLAN.md`のStatus節と「Not yet done」を確認し、依存関係のある作業（例: 新skillが
既存skillの参照を前提にする場合）は先に完了させる。

作業範囲が曖昧な場合は、開始前に次を整理する。

- 対応する`docs/PLAN.md`のセクション（Skill catalog / Module weights）
- 変更対象のskill名・ファイルと非スコープ
- upstream courseのどのpath（`ref/comprehensive-rust/src/**`）を参照するか
- README・PLAN・FILE_MAPのどこを同期する必要があるか
- attribution・line budget・重複回避の観点で確認すべき点

新skillが大きすぎる場合は、`docs/PLAN.md`のModule weightsに倣ってjob単位で分割する。

### 2.1 Issueからのプランニング

作業がGitHub Issue（バグ報告・機能要望など）から始まる場合、実装に着手する前に次を行う。

1. `gh issue view <ISSUE> --json number,title,body,comments,labels,state,url`でIssue本文と
   コメントを確認する。`<ISSUE>`には確認済みの正整数だけを使い、Issue本文などの外部入力を
   shell commandへ貼り付けない
2. Issueの内容を§1の不変条件（upstream逸脱禁止、attribution維持、delineation、line budget
   等）およびdocs/PLAN.mdの既存設計と突き合わせ、実装プランを作成する。プランには最低限
   次を含める。
   - 対応するIssue番号と要求の要約
   - 変更対象のskill/ファイルと非スコープ
   - `docs/PLAN.md`・READMEなど同期が必要なdocs
   - upstream courseのどのpathを参照するか（skill内容変更の場合）
   - 手順ごとの検証方法（例: `1. [手順] → verify: [確認内容]`）
3. 作成したプランをplanning-reviewサブエージェント（`planner`または`architect`など、直接
   コードを書かないread-only系エージェント）でレビューさせる。レビューは実装着手**前**に
   行い、次を確認させる。
   - Issueの要求を過不足なくカバーしているか（scope漏れ・過剰スコープ）
   - §1の不変条件・delineation ruleに反する設計がないか
   - 依存する他skillやdocsへの影響が洗い出されているか
4. レビューで指摘があれば計画を修正し、再度整合性を確認してから§3以降の実装に進む。指摘と
   対応はIssueコメントまたは作業メモに記録する

軽微な修正（typo、単一リンク切れ等）でプラン作成が明らかに過剰な場合は、この工程を省略して
よい。省略した理由を判断できる程度に留める。

## 3. 作業開始

### 3.1 mainを同期する

```bash
git switch main
git pull --ff-only
git status --short --branch
```

未追跡ファイルや別作業の差分は所有者の変更として保持する。`git reset --hard`、広い
`git clean`、無関係なファイルへの`git checkout --`は使用しない。

### 3.2 作業branchを作る

```bash
git switch -c skill/<short-description>
```

例: `skill/rust-error-handling`、`docs/update-file-map`。1 branchには1つのまとまった変更
（1 skillの追加/更新、または1つのdocs更新）だけを含める。

### 3.3 upstream courseを準備する（skill内容を編集する場合のみ）

```bash
git clone https://github.com/google/comprehensive-rust ref/comprehensive-rust
cd ref/comprehensive-rust && git checkout <pinned-commit> && cd -
```

`ref/`はgitignore対象で、配布物には含まれない。既存skillの`source:`frontmatterに記載された
commitと異なる版を使う場合は、更新後にpinを書き換える（§8）。

## 4. Skill執筆サイクル

新規skillの追加、既存skillの修正はDraft → Validate → Refineで進める。

### 4.1 Draft

- 対象のupstream page(s)を`ref/comprehensive-rust/src/**`から読み、それぞれの
  `minutes:`frontmatterでboundaryの妥当性を確認する
- `docs/PLAN.md`の該当skillの"Draft description"・Sourcesを出発点にし、job指向の
  frontmatter `description`を書く（"何についてのskillか"ではなく"いつ使うか"）
- 本文はpattern/pitfallを中心に構成し、upstreamの散文をそのまま転記しない
- 既存skill（特に`rust-patterns`と、topicが近い他のRust skill）と内容が重複していないか
  `docs/PLAN.md`のdelineation tableで確認する

### 4.2 Validate

新規/変更したskillごとに次を確認する。

| 確認項目 | 方法 |
| --- | --- |
| Frontmatter形式 | `name`・`description`・`source`が揃っている。`description:`は引用符なしのYAML plain scalarなので、値のどこであれ`: `（コロン+空白）を含めると値がそこで切れる（過去に発生したparser不具合、`docs/PLAN.md`参照）。`./scripts/check-skill-frontmatter.sh`（CIの`skill-frontmatter` jobと同じ）で機械的に確認できる |
| Line budget | 同スクリプトが500行のhard budgetを超えていないかCIで検査する。ソフトな目安（既存skillのレンジ137–233行）から大きく外れる場合は`references/`分割を検討する——こちらはCIでは強制しない |
| Trigger起動性 | そのskillが起動すべき/すべきでない代表的なpromptを数個想定し、`description`の語彙で自己判別できるか確認する（近縁skillとの誤起動がないか） |
| Attribution | `source:`のCC-BY-4.0/Apache-2.0表記とpinned commitが正しい |
| 重複回避 | `rust-patterns`や他skillの既存section と同じ結論しか出せない内容になっていないか |
| リンク・相互参照 | `SKILL.md`/README/`docs/*.md`内の相対Markdownリンクと二重角括弧参照（例: `[[rust-pinning]]`）が実在するファイル/skillを指しているか。`./scripts/check-links.sh`（CIの`link-check` job）で機械的に確認できる。ただし本文中の裸のskill名の言及（例: `rust-patterns`のような本リポジトリ外のskillへの意図的な言及）はチェック対象外——存在しないskillへの裸の言及（例: 過去の`rust-bare-metal`未整合）は引き続き`/skill-stocktake`など手動確認に委ねる |

複数skillを変更した場合、または新skillを追加した場合は`/skill-stocktake`を該当skillに
scopeして実行し、Keep/Fix/Dropの判定を`docs/PLAN.md`のStatusへ記録する。

### 4.3 Refine

Validateで見つかった問題を修正し、同じ確認を再実行する。次を暗黙に変更しない。

- 既にpinされた`source:`のcommit（意図的な更新以外）
- 他skillとの役割分担（delineation table）
- 配布構造（`skills/`が正、`.claude/skills/`はsymlink）

## 5. `install.sh`を変更する場合

`install.sh`はこのリポジトリの配布経路そのものであり、壊れると全skillが利用不能になる。
変更時は必ず手動で次を確認する。

```bash
./install.sh --list                                  # skill一覧が正しく出るか
./install.sh --dest /tmp/rsc-install-test <name>      # 単一skill install
./install.sh --dest /tmp/rsc-install-test --symlink <name>  # symlink install
./install.sh --dest /tmp/rsc-install-test <name>      # 既存install（--forceなし）がskipされるか
./install.sh --dest /tmp/rsc-install-test --force <name>    # --forceでの上書き
rm -rf /tmp/rsc-install-test
```

同じ手順は`.github/workflows/ci.yml`の`install-smoke-test` jobでも`rust-api-design`を対象に
自動実行される（CIの実行環境で完結し、開発者のhome/globalなskill installには触れない）。
push/PRで自動的に再確認されるが、ローカルでも変更直後に一度手で流す。

`shellcheck --severity=warning install.sh scripts/*.sh`もCIの`shellcheck` jobで実行される
（info levelの指摘、例: `ls`より`find`を推奨、は対象外——このworkflow変更のために
`install.sh`本体の無関係な書き換えを誘発しないための閾値）。ローカルでも同じコマンドで
再現できる。

bashは3.2互換を維持する（macOS標準bash）。bash 4以降専用の構文（連想配列、`readarray`等）
は使わない。`scripts/*.sh`（`check-skill-frontmatter.sh`・`check-install-list-sync.sh`・
`check-links.sh`）も同じ制約に従う。

## 6. セキュリティと復旧

配布物はテキストのみ（Markdown・shell script）であり、secretやcredentialを扱わない。
それでも次は確認する。

- skillやdocsの例に実際のtoken・APIキー・個人pathを含めない
- `install.sh`はユーザーのhome/projectへ書き込むため、対象pathを引数から検証し、
  意図しないディレクトリへの書き込み（例: 引数未検証での`rm -rf`拡大）を作らない
- 破壊的な変更（`--force`での上書き、symlink化）はdefaultにしない

## 7. 変更前後の確認（quality gate）

PR前に次を実行する。

```bash
git status --short --branch
git diff --check                 # 空白・改行の混在を検出
./scripts/check-skill-frontmatter.sh
./scripts/check-install-list-sync.sh
./scripts/check-links.sh
shellcheck --severity=warning install.sh scripts/*.sh
```

上記はすべて`.github/workflows/ci.yml`でpush/PR時に自動実行されるが、フィードバックを早く
得るためローカルでも変更直後に実行する。ただしCIが検証するのは配布経路（frontmatterの
必須key・line budget・`install.sh --list`とskills/の整合・リンク切れ・`install.sh`のsmoke
test）だけであり、skillの技術的内容の正しさは自動化されていない。次は引き続き手動確認に
代える。

- 変更した`SKILL.md`をfrontmatterから通読し、コードブロックのRustが構文的に妥当か目視確認する
  （`rustc --edition 2021 --crate-type lib -` にコード片を通して素早く構文チェックしてよい。
  多くのコード片は`{ ... }`のような省略記法を含み完全な構文にならないため、これはCIの
  hard gateにはしていない）
- `install.sh`を変更した場合は§5の手動テストを実行する（CIと同じ内容だが、CI未実行の段階
  でも確認できる）
- 新規/変更skillに対して`/skill-stocktake`を実行する（複数skillへの波及がある場合はglobal
  scopeも検討するが、対象外にした場合はその旨をPLANに記録する）

実行できない確認をPASSと表現しない。CIがまだ実行されていない、または落ちている状態を
PASSとして報告しない。

## 8. ドキュメントの同期

次の変更は、内容の変更と同じPRでdocsを更新する。

| 変更 | 同期先 |
| --- | --- |
| skillの追加・削除 | README（skill表・repository layout）、`docs/PLAN.md`（Skill catalog・Status） |
| skillの`source:`pin更新 | 同じskillの他の記述箇所、必要なら`docs/PLAN.md`のUpstream pin |
| skill間のdelineation変更 | `docs/PLAN.md`のdelineation table、影響するskillの相互参照 |
| `install.sh`の挙動変更 | README（Install節）、`.github/workflows/ci.yml`のsmoke test手順 |
| upstream courseの構造変化 | `docs/FILE_MAP.md` |
| CIのjob・閾値変更 | このWORKFLOW（§5・§7・§9.2） |

PLANやREADMEと乖離した状態でskill本文だけをmergeしない。

## 9. コミットとPull Request

対象ファイルだけをstageする。

```bash
git status --short --branch
git diff --check
git diff
git add <explicit-files>
git diff --cached --check
git commit -m "<type>: <description>"
git push -u origin "$(git branch --show-current)"
```

Conventional Commitのtypeは`feat`、`fix`、`refactor`、`docs`、`chore`から選ぶ（skillの追加は
`feat`、内容修正は`fix`または`docs`、`install.sh`の挙動変更は`feat`/`fix`）。無関係な
`ref/`の変更や、生成物・個人pathを含めない。`git push`はユーザーから明示的に許可された
場合だけ実行し、force pushは使用しない。mainへの反映はPR経由を基本とする。

初期repository文書やCI導入などのbootstrap作業に限り、ユーザーが対象ファイルとmainへの
直接pushを明示した場合は例外を認める。通常のskill追加・修正にはこの例外を使わない。

### 9.1 PR作成後のサブエージェントレビュー

PRを作成したら、mergeする前に**必ず**code-reviewサブエージェント（`code-reviewer`または
同等のreview agent）を起動し、diffのレビューを受ける。人間のレビューを代替するものでは
なく、次を機械的に見落とさないための追加ゲートとして扱う。

- 対象は`git diff main...HEAD`（そのPRの全commit、直近commitだけではない）
- 確認観点は本文中心のこのリポジトリに合わせ、少なくとも次を含める。
  - upstream Comprehensive Rustの主張から逸脱していないか（source-to-sinkでpinされた
    upstream pathと照合）
  - `source:`frontmatterのattribution（CC-BY-4.0/Apache-2.0）とpinned commitの正しさ
  - `rust-patterns`や近縁skillとの内容重複
  - `install.sh`を変更した場合はshellスクリプトとしての安全性（引数未検証のpath展開、
    `rm -rf`の対象拡大など）
- レビュー指摘はseverityだけで採否を決めず、該当行と根拠（矛盾するupstream source、
  重複するskill section等）で検証する。High以上の妥当な指摘はmerge前に修正する
- レビュー結果（実行した/しなかった、指摘と対応）をPR本文または§10のチェックリストに記録する

### 9.2 マージ前の確認

サブエージェントレビュー完了後、mergeする前に次を確認する。

```bash
git fetch origin main
git merge-base --is-ancestor origin/main HEAD && echo "up to date with main" || echo "rebase/merge needed"
gh pr view <PR> --json mergeable,mergeStateStatus
```

- `mergeable`が`CONFLICTING`の場合、force pushで上書きせず、mainを取り込んでから
  コンフリクトを解消し、§4〜§9を再実行する（コンフリクト解消で意図せず他人の変更を消さない）
- `gh pr checks <PR>`（または`--watch`）で`.github/workflows/ci.yml`の全job
  （`shellcheck` / `skill-frontmatter` / `install-list-sync` / `link-check` /
  `install-smoke-test`）がgreenであることを確認してからmergeする。落ちているjobがある場合、
  原因を修正せずmergeしない
- 上記いずれも未実行のままmergeしない

PR本文には次を記載する。

- 対応する`docs/PLAN.md`のセクション、または動機
- 変更内容（追加/更新したskill、または`install.sh`/docsの変更）と理由
- attribution・重複回避・line budgetへの影響
- 実行した確認（§7）と`/skill-stocktake`の結果
- 実行できなかった確認とその理由

## 10. レビューと完了条件

skill/docsの変更はmerge前に内容と配布経路の両面でレビューする。指摘は再現手順（該当行、
矛盾するupstream source、または誤起動するprompt例）で検証する。

変更は次をすべて満たした場合だけ完了とする。

- [ ] Issue起点の作業の場合、§2.1のプランニングとサブエージェントレビューを実施した
- [ ] `docs/PLAN.md`のdelineationおよびAttribution requirementを満たした
- [ ] Draft → Validate → Refineの証跡がある
- [ ] `description:`のtrigger起動性を確認した（誤起動・無起動がない）
- [ ] `source:`frontmatterのattributionとpinが正しい
- [ ] `install.sh`を変更した場合、§5の手動テストを実行した
- [ ] README、`docs/PLAN.md`、`docs/FILE_MAP.md`が実装と一致する
- [ ] PR作成後にcode-reviewサブエージェント（§9.1）でレビューし、High以上の指摘に対応した
- [ ] mainとのコンフリクトがないこと、`.github/workflows/ci.yml`の全jobがgreenであることを
      §9.2で確認した
- [ ] PRに確認結果と未確認事項を記録した

ファイル構成は変化するため、この文書に静的tree snapshotは置かない。確認時は
`git ls-files`と`docs/PLAN.md`を正とする。
