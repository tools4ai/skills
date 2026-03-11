# Export to Image

将 Markdown 文档导出为手机屏幕尺寸的图片工具，包含 Obsidian 插件和 CLI 命令行工具。

## 功能特性

- 📱 **智能分图**: 根据文档长度和标题个数自动计算需要生成的图片数量
- 📐 **多种屏幕尺寸**: 支持多种 iPhone 和 Android 手机尺寸，也可自定义尺寸
- 🎨 **主题支持**: 支持浅色、深色和跟随系统主题
- 📤 **一键导出**: 支持 PNG 和 JPEG 格式导出
- 🏷️ **#e2i 标签**: 使用 `#e2i` 标签手动标记需要导出的内容块
- 📏 **自动宽度调整**: 根据内容实际宽度自动调整图片宽度，避免图片过宽

## 支持的手机尺寸

- iPhone SE (375 x 667)
- iPhone 14 (390 x 844)
- iPhone 14 Pro Max (430 x 932)
- iPhone 15 (393 x 852)
- iPhone 15 Pro Max (430 x 932)
- Android Small (360 x 640)
- Android Medium (360 x 800)
- Android Large (412 x 915)
- 自定义尺寸

## 使用方式

### Obsidian 插件

#### 安装方法

1. 克隆或下载此仓库
2. 进入目录: `cd export2image`
3. 安装依赖: `npm install`
4. 编译: `npm run build`
5. 将 `export2image` 文件夹复制到你的 Obsidian 插件目录:
   - macOS: `~/Library/Application Support/obsidian/plugins/`
   - Windows: `%APPDATA%/obsidian/plugins/`
   - Linux: `~/.config/obsidian/plugins/`
6. 在 Obsidian 中启用插件: 设置 → 第三方插件 → 关闭安全模式 → 启用 Export to Image

#### 使用方法

1. 打开你想要导出的笔记
2. 点击左侧 ribbon 图标（图片+图标）或使用命令面板 (`Ctrl/Cmd + P`) 输入 "导出当前笔记为图片"
3. 在弹出的预览窗口中确认导出参数
4. 点击"导出图片"按钮

#### 插件设置

点击插件右侧的设置图标可以配置:

- 📱 **手机型号**: 选择目标手机屏幕尺寸
- 📏 **自定义尺寸**: 设置自定义的宽度和高度
- 🖼️ **图片格式**: 选择 PNG 或 JPEG
- 🔤 **字体大小**: 设置导出图片的字体大小
- 📄 **边距**: 设置内容边距
- 🎭 **主题**: 选择浅色、深色或跟随系统

### CLI 命令行工具

#### 编译 CLI 工具

```bash
npm install
npm run build:cli
```

#### 基本用法

```bash
export2image -i <输入文件> -o <输出文件>
```

#### 命令行选项

| 选项 | 简写 | 描述 | 默认值 |
|------|------|------|--------|
| `--input` | `-i` | 输入的 Markdown 文件路径 (必需) | - |
| `--output` | `-o` | 输出图片路径 (必需) | - |
| `--phone` | `-p` | 手机型号 | `iPhone 14` |
| `--theme` | `-t` | 主题: `light` 或 `dark` | `light` |
| `--padding` | - | 内容内边距 (像素) | `16` |
| `--font-size` | - | 字体大小 (像素) | `14` |
| `--help` | `-h` | 显示帮助信息 | - |

#### 使用示例

```bash
# 基本用法
export2image -i note.md -o output.png

# 指定手机型号和深色主题
export2image -i note.md -o output.png -p "iPhone 15" -t dark

# 自定义内边距和字体大小
export2image -i note.md -o output.png --padding 20 --font-size 16

# 输出 JPEG 格式
export2image -i note.md -o output.jpg
```

## #e2i 标签

你可以在 Markdown 中使用 `#e2i` 标签来标记需要导出为图片的内容块：

```markdown
#e2i
这里是第一张图片的内容
- 列表项1
- 列表项2
#e2i

#e2i
这里是第二张图片的内容
> 引用文字
#e2i

其他内容不会被导出
```

每个 `#e2i` 标签之间的内容会被单独导出为一张图片。

## 计算逻辑

插件根据以下规则自动计算图片数量和大小:

1. **内容高度估算**: 每 1000 字符约需要 400 像素高度
2. **标题调整**: 每个标题额外增加 60 像素，加上 30 像素的标题间距
3. **图片数量**: 根据总高度和选择的手机屏幕高度计算，最多支持 10 张图片
4. **内容分割**: 根据图片数量将内容平均分割到各个图片中
5. **自动宽度调整**:
   - 如果内容宽度小于可用宽度，使用实际内容宽度
   - 如果内容宽度大于可用宽度，使用缩放逻辑

## 注意事项

- 导出的图片会保存到你的默认下载目录
- 如果文档较长，会自动生成多张图片
- 建议在导出前预览一下生成参数

## 许可证

MIT License
