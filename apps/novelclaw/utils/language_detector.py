"""
Simple language detector for zh/en based on character heuristics.
"""

import re
from typing import Literal


def detect_language(text: str) -> Literal["en", "zh", "vi"]:
    """
    Heuristic detection: if CJK characters ratio > 0.2 => zh else en.
    """
    if not text:
        return "en"
    vi_chars = len(re.findall(r"[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ]", text))
    total = max(len(text), 1)
    
    if vi_chars / total > 0.05:
        return "vi"
        
    cjk = len(re.findall(r"[\u4e00-\u9fff]", text))
    ratio = cjk / total
    return "zh" if ratio > 0.2 else "en"
