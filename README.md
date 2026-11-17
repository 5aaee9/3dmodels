# 3D Models Collections

个人的 3D 模型

## Models
- [H3C Desiccant](./models/h3c-desiccant)

## OpenSCAD 检查

需要 Python 3.9+ 和 OpenSCAD 2021.01+，检查脚本只使用 Python 标准库：

```sh
python scripts/lint_scad.py
```

脚本自动检查 `models/` 下所有 `.scad` 文件，包括公共库；另外运行
[.openscad-lint.json](./.openscad-lint.json) 中列出的参数组合。当前额外覆盖
`section_view="top"` 和 `print_ready=false`，默认参数由全量检查覆盖。
新增模型会自动加入检查，新增参数分支时应在该配置中补充组合。

检查使用 OpenSCAD 自身的解析器和求值器，开启 `--hardwarnings`、
`--check-parameters=true` 和 `--check-parameter-ranges=true`。语法错误、
执行路径中的未定义变量/模块、错误参数、失败的 `assert()` 以及编译警告
都会导致非零退出码。每个组合最多运行 120 秒，CSG 输出放入临时目录并自动清理，
不会写入或修改项目的 STL。

这属于快速编译检查，并非完整的静态分析：未调用的模块和未执行的分支不会
得到完整检查；它也不验证网格流形、布尔运算最终结果或可打印性。涉及几何修改
时仍须重新导出 STL 并检查。依赖本地生成 STL 的 `show_lid` / `show_baffle`
装配预览不纳入本检查，以便干净检出后也能运行。

脚本优先使用 `OPENSCAD_BIN`，然后查找 PATH 和 Windows/macOS 的常见安装位置。
Windows 使用 `openscad.com` 以可靠获取命令行诊断。自定义路径示例（PowerShell）：

```powershell
$env:OPENSCAD_BIN = 'C:\Program Files\OpenSCAD\openscad.com'
python scripts/lint_scad.py
```

第三方 OpenSCAD 库沿用 OpenSCAD 自身的库搜索规则，可通过 `OPENSCADPATH` 指定。
[.editorconfig](./.editorconfig) 为支持它的编辑器设置 UTF-8、LF 和 4 空格的 SCAD
缩进；它不是格式检查器，也不会批量重写现有源文件。

### 可选：提交前自动检查

项目已提供 [.pre-commit-config.yaml](./.pre-commit-config.yaml)。要在当前检出中启用：

```sh
python -m pip install pre-commit
pre-commit install
pre-commit run --all-files
```

钩子使用当前环境的 Python 和本机 OpenSCAD，每次提交检查全部模型，以覆盖
公共文件变更的影响。

### GitHub Actions

[OpenSCAD lint](./.github/workflows/openscad-lint.yml) 在每次 push 和 PR 时
自动运行，也支持在 GitHub Actions 页面手动触发。工作流使用 Ubuntu 24.04、
Python 3.12 和 Ubuntu 软件源中的 OpenSCAD，执行与本地相同的
`python scripts/lint_scad.py`。通过 `QT_QPA_PLATFORM=offscreen` 支持无显示器环境。
任一检查失败都会使工作流失败；完整日志可在 `Lint OpenSCAD models` 步骤查看。
