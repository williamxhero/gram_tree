# 界面描述协议契约（SPEC-009.1）

服务端和 App 唯一共用的页面描述 JSON Schema 和测试样例，见 `docs/adr/0005-界面描述协议共享契约.md`。

- `schema/<major>.<minor 起点>/page_description.schema.json`：协议信封的 Schema。新增大版本时新建一个目录（例如 `schema/2.0/`），不改旧目录；同一大版本内的小版本增量不新建目录，只在信封里出现新的可选字段。
- `schema/<version>/components/<type>.schema.json`：每个组件类型的 `data` 字段格式，登记在服务端 `server/gramtree/ui_protocol/components.py` 和 App `app/lib/ui_protocol/component_registry.dart`，两边都从这里的文件读、不各写一份。
- `samples/valid/`：合法的页面描述样例，服务端和 App 的测试都读同一份文件，判定必须一致。
- `samples/invalid/`：不合法的样例，文件名即错误场景（SPEC-009.1 #79 起补全）：
  - `unknown_component.json`：组件类型没有登记过（`unknown_component`）。
  - `missing_field.json`：信封缺必填字段，这里缺的是 `cache`（`invalid_data`）。
  - `illegal_action.json`：组件的 `actions` 里缺 `intent`，信封 Schema 结构本身就不
    合法（`illegal_action`）。
  - `unregistered_intent.json`：`intent` 结构合法，但不是 App/服务端登记表里的意图名
    （`illegal_action`，SPEC-009.1 #81 起）。
  - `invalid_action_params.json`：`intent` 已登记（`open_page`），但 `params` 缺这个
    意图要求的字段（`open_page` 缺 `page`）（`illegal_action`，#81 起）。
  - `arbitrary_url_action.json`：`open_page` 的 `params.page` 是一个任意网址而不是
    App 已登记的页面名（`illegal_action`，#81 起——"打开页面"类意图只能打开已登记
    页面，其余一律拒绝，含任意网址跳转）。
  - `unknown_major.json`：`protocol` 的大版本没有对应的 Schema 目录（`unknown_major`）。
  - `missing_required_component.json`：Schema 本身合法（`components` 就是空数组），
    是不是不合法要看当时的页面类型规格——`today` 目前没有必显组件要求，所以这份样例
    默认判定是合法的；判定必显组件机制本身（`missing_required`）的测试要先临时给某个
    页面类型注册一个必显组件类型（服务端：临时改 `page_types.BY_PAGE_TYPE`；App：临时
    覆盖 `requiredComponentTypesProvider`），再用这份样例验证。

两端怎么读这份目录，见 `docs/adr/0005-界面描述协议共享契约.md`。
