# 界面描述协议契约（SPEC-009.1）

服务端和 App 唯一共用的页面描述 JSON Schema 和测试样例，见 `docs/adr/0005-界面描述协议共享契约.md`。

- `schema/<major>.<minor 起点>/page_description.schema.json`：协议信封的 Schema。新增大版本时新建一个目录（例如 `schema/2.0/`），不改旧目录；同一大版本内的小版本增量不新建目录，只在信封里出现新的可选字段。
- `schema/<version>/components/<type>.schema.json`：每个组件类型的 `data` 字段格式，登记在服务端 `server/gramtree/ui_protocol/components.py` 和 App `app/lib/ui_protocol/component_registry.dart`，两边都从这里的文件读、不各写一份。
- `samples/valid/`：合法的页面描述样例，服务端和 App 的测试都读同一份文件，判定必须一致。
- `samples/invalid/`：不合法的样例（未知组件、缺字段、非法动作、缺必显组件、未知大版本……SPEC-009.1 #79 起补全），文件名即错误场景。

两端怎么读这份目录，见 `docs/adr/0005-界面描述协议共享契约.md`。
