"""用户协议和隐私政策的静态网页。App 首次启动的同意页里“全文”链接指向这里。

正文是占位文本，上线前由产品负责人提供、律师审阅（SPEC-011）。改版时同步提高 App 里的版本号。
"""

from html import escape

from fastapi import APIRouter
from fastapi.responses import HTMLResponse

from gramtree.core.errors import NotFound

router = APIRouter(prefix="/legal", include_in_schema=False)

DOCS: dict[str, tuple[str, str, list[str]]] = {
    "terms": (
        "味谱用户协议",
        "v1",
        [
            "【占位文本】正式条文上线前提供。",
            "味谱是一个帮助你记录、改进和分享菜谱的应用。",
            "你发布的菜谱会公开给其他用户查看（做过即公开）。",
            "你可以随时在“我的 → 设置”里注销账号。",
        ],
    ),
    "privacy": (
        "味谱隐私政策",
        "v1",
        [
            "【占位文本】正式条文上线前提供。",
            "我们收集：登录用的邮箱（或 Apple 提供的中转邮箱）、你写的菜谱和做菜记录、口味设置、"
            "设备 ID 和出错时的崩溃信息（不含菜谱和口味内容）。",
            "我们不放广告，不出售你的数据。",
            "相机、相册、麦克风、通知等权限只在你用到对应功能时才申请。",
            "你可以在“我的 → 设置”里查看个人信息收集清单和第三方 SDK 共享清单，撤回同意或注销账号。"
            "注销后 15 个工作日内删除个人数据。",
        ],
    ),
}


@router.get("/{doc}", response_class=HTMLResponse)
def legal_page(doc: str) -> HTMLResponse:
    name = doc.removesuffix(".html")
    if name not in DOCS:
        raise NotFound()
    title, version, paragraphs = DOCS[name]
    body = "".join(f"<p>{escape(p)}</p>" for p in paragraphs)
    return HTMLResponse(
        "<!doctype html><html lang='zh-CN'><head><meta charset='utf-8'>"
        "<meta name='viewport' content='width=device-width,initial-scale=1'>"
        f"<title>{escape(title)}</title>"
        "<style>body{max-width:40em;margin:2em auto;padding:0 16px;line-height:1.8;"
        "font-family:'Noto Sans SC',sans-serif;background:#F7F4EE;color:#1B1813}</style>"
        f"</head><body><h1>{escape(title)}</h1><p>版本 {escape(version)}</p>{body}</body></html>"
    )
