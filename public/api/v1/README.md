# 灯影智游静态数据接口

这个目录用于把 GitHub 仓库作为轻量静态数据源：

- `lanterns.json`：灯组知识库、样板路线和演示识别数据。

后续启用 GitHub Pages 后，App 可以从类似下面的地址读取：

```text
https://eric990705.github.io/dengying-zhiyou-c4/api/v1/lanterns.json
```

在正式后端上线前，这个静态 JSON 可以承担“内容数据库”的角色；识别推理仍需要本地演示逻辑、FastAPI 服务或 CoreML 端侧模型承接。

