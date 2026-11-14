# Git 日常操作速查

## 一、先理解三个区域

```
工作区(你直接编辑的文件)  --git add-->  暂存区  --git commit-->  本地版本库  --git push-->  GitHub
```

- **工作区**：你在文件夹里看到、用编辑器改的东西
- **暂存区**：你挑出来"这次要提交的那些改动"
- **版本库**：本地的历史记录（`.git` 文件夹），断网也能提交
- **远程仓库**：GitHub 上的那份

## 二、每天真正会用到的命令（背这 4 条就够）

```bash
git status                  # 看当前有哪些改动（最常用，随时敲）
git add .                   # 把所有改动放进暂存区
git commit -m "改了什么"      # 给这次改动拍个快照，写清楚干了什么
git push                    # 把本地提交传到 GitHub
```

完整流程举例（改完代码后）：

```bash
cd G:\STM32\study
git status
git add .
git commit -m "feat: 完成 GPIO 点灯"
git push
```

## 三、这个仓库的配置

| 项目 | 值 |
|---|---|
| GitHub 用户名 | ZARD-cz |
| 邮箱 | 1179754440@qq.com |
| 远程名 | origin |
| 远程地址 | https://github.com/ZARD-cz/ckyf.git |
| 默认分支 | main |

## 四、查看历史 / 对比

```bash
git log --oneline --graph       # 看提交历史（图形化）
git diff                        # 看还没 add 的改动
git diff --staged               # 看已 add 但还没 commit 的改动
git show HEAD                   # 看最近一次提交具体改了啥
```

## 五、写坏了想撤回（新手救命三招）

```bash
# 1. 改了文件但还没 add，想全部还原
git restore .

# 2. 已经 add 了，想退出暂存区（文件内容不动）
git restore --staged .

# 3. 已经 commit 了，但想撤销这次提交（改动保留在文件里）
git reset --soft HEAD~1
```

> 尽量不要用 `git reset --hard`，它会真的删掉你未保存的改动。

## 六、常见报错对照

| 报错 | 原因 | 解决 |
|---|---|---|
| `fatal: not a git repository` | 当前目录不是仓库 | `cd` 到仓库目录，或 `git init` |
| `Please tell me who you are` | 没配用户名邮箱 | `git config --global user.name/user.email` |
| `updates were rejected` | 远程有你本地没有的提交 | 先 `git pull` 再 `git push` |
| `CONFLICT (content)` | 两边改了同一处 | 手动改文件，删掉 `<<<<<<<` 标记后 `git add` + `git commit` |
| 打开 GitHub 超时 | Steam++ 加速器没开 | 启动 Steam++ / Watt Toolkit |

## 七、`.gitignore` 是干什么的

仓库里的 `.gitignore` 列出的文件**不会被提交**。本仓库已配置忽略 Keil 的编译产物
（`Objects/`、`Listings/`、`*.hex`、`*.axf` 等），这样仓库里只留源码，干净、体积小。

如果想额外忽略某个文件，用文本编辑器打开 `.gitignore` 加一行即可，例如：

```
build/
*.log
```