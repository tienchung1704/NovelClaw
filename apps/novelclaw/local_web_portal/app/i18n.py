from __future__ import annotations

from typing import Dict, List

from jinja2 import pass_context
from starlette.requests import Request

DEFAULT_LOCALE = "en"
SUPPORTED_LOCALES = ("en", "vi-VN")

LOCALE_OPTIONS = (
    {"code": "en", "label": "English"},
    {"code": "vi-VN", "label": "Tiếng Việt"},
)

# Mapping for _ui_text function compatibility
LOCALE_MAP = {
    "en": "en",
    "zh": "zh-CN",
    "zh-CN": "zh-CN",
    "vi": "vi-VN",
    "vi-VN": "vi-VN",
}


def normalize_locale(value: str | None) -> str:
    """Normalize locale string to supported locale code."""
    raw = (value or "").strip().lower()
    
    # Vietnamese
    if raw in {"vi", "vi-vn", "vi_vn", "vie"}:
        return "vi-VN"
    
    # Chinese
    if raw in {"zh", "zh-cn", "zh_hans", "zh-hans", "zh_cn"}:
        return "zh-CN"
    if raw.startswith("zh-"):
        return "zh-CN"
    
    # English
    if raw in {"en", "en-us", "en_us", "en-gb", "en_gb"}:
        return "en"
    
    return DEFAULT_LOCALE


def get_locale(request: Request | None) -> str:
    """Get current locale from request session or headers."""
    if request is None:
        return DEFAULT_LOCALE
    
    # Check session
    session_locale = request.session.get("locale")
    if session_locale:
        return normalize_locale(str(session_locale))
    
    # Check Accept-Language header
    accept_language = request.headers.get("accept-language", "")
    for chunk in accept_language.split(","):
        code = chunk.split(";", 1)[0].strip()
        normalized = normalize_locale(code)
        if normalized in SUPPORTED_LOCALES:
            return normalized
    
    return DEFAULT_LOCALE


def set_locale(request: Request, locale: str | None) -> str:
    """Set locale in session."""
    normalized = normalize_locale(locale)
    request.session["locale"] = normalized
    return normalized


def ui_text(lang: str, zh: str, en: str, vi: str | None = None) -> str:
    """
    Helper function for backward compatibility with _ui_text.
    Returns text based on language code.
    
    Args:
        lang: Language code (en, zh, vi)
        zh: Chinese text
        en: English text
        vi: Vietnamese text (optional, falls back to English if not provided)
    """
    normalized = normalize_locale(lang)
    
    if normalized == "vi-VN":
        return vi if vi is not None else en
    elif normalized == "zh-CN":
        return zh
    else:
        return en


def locale_options() -> List[Dict[str, str]]:
    """Return list of available locale options."""
    return list(LOCALE_OPTIONS)


def install_i18n(templates) -> None:
    """Install i18n helpers into Jinja2 templates."""
    
    @pass_context
    def current_locale(context) -> str:
        request = context.get("request")
        return get_locale(request)
    
    @pass_context
    def t(context, en: str, zh: str = "", vi: str = "") -> str:
        """Template translation helper."""
        request = context.get("request")
        locale = get_locale(request)
        return ui_text(locale, zh or en, en, vi or en)
    
    templates.env.globals["locale"] = current_locale
    templates.env.globals["t"] = t
    templates.env.globals["locale_options"] = locale_options
